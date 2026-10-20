//! # chronos-gesture-core
//!
//! EN: Pure state machine that turns raw touch events (down/motion/up) into high-level gestures:
//! multi-finger swipes (3/4 fingers) and edge swipes. It knows nothing about Wayland or windows,
//! so gesture recognition stays independent from layout (the Denial `mobile_shell` mistake).
//!
//! ES: Máquina de estados pura que convierte eventos táctiles crudos en gestos: deslizamientos de
//! 3/4 dedos y desde los bordes. No sabe nada de Wayland ni de ventanas, así el reconocimiento de
//! gestos es independiente del layout.
//!
//! Flow / Flujo: the compositor feeds `down/motion/up/cancel`; it receives `Out` values. On
//! `Out::Claim` it must cancel the touch sequence sent to clients (they already got a `down`).

use std::collections::HashMap;
use std::hash::Hash;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Axis {
    Horizontal,
    Vertical,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Edge {
    Top,
    Bottom,
    Left,
    Right,
}

/// Tunable parameters. Pixels are logical pixels. / Parámetros ajustables (píxeles lógicos).
#[derive(Debug, Clone)]
pub struct Config {
    /// Screen size (w, h). / Tamaño de pantalla.
    pub screen: (f64, f64),
    /// Extra fingers must land within this time of the first one to count as a multi-finger gesture.
    pub claim_window_ms: u64,
    /// Distance before a gesture picks its axis (GNOME Shell uses 16).
    pub threshold_px: f64,
    /// A touch starting within this distance of a screen edge is an edge-swipe candidate.
    pub edge_px: f64,
    /// Inward travel that equals progress 1.0 for edge swipes.
    pub edge_travel_px: f64,
    /// Edge swipe is "committed" at this progress (or with enough inward velocity).
    pub edge_commit_progress: f64,
    /// Velocity (px/s) that commits an edge swipe even if progress is small.
    pub edge_commit_velocity: f64,
}

impl Config {
    pub fn new(screen: (f64, f64)) -> Self {
        Self {
            screen,
            claim_window_ms: 150,
            threshold_px: 16.0,
            edge_px: 24.0,
            edge_travel_px: 160.0,
            edge_commit_progress: 0.4,
            edge_commit_velocity: 600.0,
        }
    }
}

/// Output events. / Eventos de salida.
#[derive(Debug, Clone, PartialEq)]
pub enum Out {
    /// A gesture took over: cancel the touch sequence sent to clients.
    Claim,
    Begin { fingers: u8, axis: Axis },
    /// `dx/dy`: movement since the previous update; `total_*`: since gesture start (centroid).
    Update { fingers: u8, axis: Axis, dx: f64, dy: f64, total_dx: f64, total_dy: f64 },
    /// `total_*`: net centroid travel since gesture start. `velocity_*` in px/s over the last ~150 ms.
    End { fingers: u8, axis: Axis, total_dx: f64, total_dy: f64, velocity_x: f64, velocity_y: f64 },
    /// Multi-finger touch that never became a swipe (e.g. a 3-finger tap).
    Cancel { fingers: u8 },
    EdgeBegin { edge: Edge },
    /// `progress` is 0..1 (can exceed 1 slightly) along the inward direction.
    EdgeUpdate { edge: Edge, progress: f64 },
    EdgeEnd { edge: Edge, progress: f64, committed: bool },
}

#[derive(Debug, Clone, Copy)]
struct Slot {
    last: (f64, f64),
}

#[derive(Debug)]
enum State {
    Idle,
    /// Touch owned by clients until all fingers lift (pinch, scroll, tap...).
    Passthrough,
    /// First finger started at an edge; waiting to see if it moves inward.
    EdgeCandidate { edge: Edge, start: (f64, f64) },
    EdgeActive { edge: Edge, start: (f64, f64), progress: f64, history: Vec<(u64, f64)> },
    /// 3+ fingers landed together; axis may not be decided yet.
    Multi {
        fingers: u8,
        start: (f64, f64),
        last: (f64, f64),
        axis: Option<Axis>,
        history: Vec<(u64, f64, f64)>,
    },
    /// Gesture finished (finger lifted); ignore events until all fingers are up.
    Done,
}

/// `S` is the compositor's own touch-slot identifier (e.g. `smithay::backend::input::TouchSlot`).
/// Generic so niri can key it by its real slot type instead of a stand-in `i32`.
pub struct Recognizer<S> {
    cfg: Config,
    slots: HashMap<S, Slot>,
    state: State,
    first_down_ms: u64,
}

const HISTORY_MS: u64 = 150;

impl<S: Copy + Eq + Hash> Recognizer<S> {
    pub fn new(cfg: Config) -> Self {
        Self { cfg, slots: HashMap::new(), state: State::Idle, first_down_ms: 0 }
    }

    pub fn set_screen(&mut self, screen: (f64, f64)) {
        self.cfg.screen = screen;
    }

    fn centroid(&self) -> (f64, f64) {
        let n = self.slots.len().max(1) as f64;
        let (sx, sy) = self.slots.values().fold((0., 0.), |a, s| (a.0 + s.last.0, a.1 + s.last.1));
        (sx / n, sy / n)
    }

    fn edge_at(&self, (x, y): (f64, f64)) -> Option<Edge> {
        let (w, h) = self.cfg.screen;
        let e = self.cfg.edge_px;
        // Bottom/top first: they matter most for OSK/panel. / Primero abajo/arriba.
        if y >= h - e {
            Some(Edge::Bottom)
        } else if y <= e {
            Some(Edge::Top)
        } else if x <= e {
            Some(Edge::Left)
        } else if x >= w - e {
            Some(Edge::Right)
        } else {
            None
        }
    }

    /// Inward distance for an edge. / Distancia hacia dentro.
    fn inward(edge: Edge, start: (f64, f64), p: (f64, f64)) -> f64 {
        match edge {
            Edge::Bottom => start.1 - p.1,
            Edge::Top => p.1 - start.1,
            Edge::Left => p.0 - start.0,
            Edge::Right => start.0 - p.0,
        }
    }

    pub fn down(&mut self, slot: S, pos: (f64, f64), t_ms: u64) -> Vec<Out> {
        let mut out = vec![];
        let was_empty = self.slots.is_empty();
        self.slots.insert(slot, Slot { last: pos });

        if was_empty {
            self.first_down_ms = t_ms;
            self.state = match self.edge_at(pos) {
                Some(edge) => State::EdgeCandidate { edge, start: pos },
                None => State::Idle,
            };
            return out;
        }

        let n = self.slots.len() as u8;
        let in_window = t_ms.saturating_sub(self.first_down_ms) <= self.cfg.claim_window_ms;
        match &mut self.state {
            State::Idle if n >= 3 && in_window => {
                let c = self.centroid();
                self.state = State::Multi { fingers: n, start: c, last: c, axis: None, history: vec![] };
                out.push(Out::Claim);
            }
            State::Multi { fingers, axis: None, .. } if n > *fingers && in_window => {
                // Extra finger while undecided: upgrade 3 -> 4. Re-anchor centroid.
                *fingers = n;
                let c = {
                    let k = self.slots.len() as f64;
                    let (sx, sy) = self.slots.values().fold((0., 0.), |a, s| (a.0 + s.last.0, a.1 + s.last.1));
                    (sx / k, sy / k)
                };
                if let State::Multi { start, last, history, .. } = &mut self.state {
                    *start = c;
                    *last = c;
                    history.clear();
                }
            }
            State::Idle => {
                // 2 fingers so far, or a late finger: clients own it (pinch/scroll); a 3rd finger
                // may still arrive inside the claim window. Idle never emits events by itself.
            }
            State::EdgeCandidate { .. } if n == 2 && in_window => {
                // First finger landed in the edge band, but a 2nd one followed quickly: this is
                // no longer an edge swipe. Behave like Idle so a 3rd finger inside the claim
                // window can still start a multi-finger swipe.
                self.state = State::Idle;
            }
            State::EdgeCandidate { .. } => {
                self.state = State::Passthrough;
            }
            State::EdgeActive { .. } => {
                // Second finger during an edge swipe: ignore, keep gesture.
            }
            _ => {}
        }
        out
    }

    pub fn motion(&mut self, slot: S, pos: (f64, f64), t_ms: u64) -> Vec<Out> {
        let mut out = vec![];
        match self.slots.get_mut(&slot) {
            Some(s) => s.last = pos,
            None => return out,
        }
        let c = self.centroid();
        let thr = self.cfg.threshold_px;
        let travel = self.cfg.edge_travel_px;

        match &mut self.state {
            State::EdgeCandidate { edge, start } => {
                let (edge, start) = (*edge, *start);
                let inward = Self::inward(edge, start, pos);
                let (dx, dy) = (pos.0 - start.0, pos.1 - start.1);
                let lateral = match edge {
                    Edge::Bottom | Edge::Top => dx.abs(),
                    Edge::Left | Edge::Right => dy.abs(),
                };
                if inward >= thr && inward >= lateral {
                    let progress = inward / travel;
                    self.state = State::EdgeActive { edge, start, progress, history: vec![(t_ms, inward)] };
                    out.push(Out::Claim);
                    out.push(Out::EdgeBegin { edge });
                    out.push(Out::EdgeUpdate { edge, progress });
                } else if lateral >= thr || inward <= -thr {
                    // Moves along the edge or outward: normal touch.
                    self.state = State::Passthrough;
                }
            }
            State::EdgeActive { edge, start, progress, history } => {
                let inward = Self::inward(*edge, *start, pos).max(0.0);
                *progress = inward / travel;
                history.push((t_ms, inward));
                history.retain(|(t, _)| t_ms - *t <= HISTORY_MS);
                out.push(Out::EdgeUpdate { edge: *edge, progress: *progress });
            }
            State::Multi { fingers, start, last, axis, history } => {
                let (dx, dy) = (c.0 - last.0, c.1 - last.1);
                *last = c;
                history.push((t_ms, c.0, c.1));
                history.retain(|(t, _, _)| t_ms - *t <= HISTORY_MS);
                let (tx, ty) = (c.0 - start.0, c.1 - start.1);
                if axis.is_none() && tx.hypot(ty) >= thr {
                    let a = if tx.abs() > ty.abs() { Axis::Horizontal } else { Axis::Vertical };
                    *axis = Some(a);
                    out.push(Out::Begin { fingers: *fingers, axis: a });
                }
                if let Some(a) = *axis {
                    out.push(Out::Update { fingers: *fingers, axis: a, dx, dy, total_dx: tx, total_dy: ty });
                }
            }
            _ => {}
        }
        out
    }

    pub fn up(&mut self, slot: S, _t_ms: u64) -> Vec<Out> {
        let mut out = vec![];
        if self.slots.remove(&slot).is_none() {
            return out;
        }
        let all_up = self.slots.is_empty();
        let state = std::mem::replace(&mut self.state, State::Done);
        self.state = match state {
            State::EdgeActive { edge, progress, history, .. } => {
                let v = match (history.first(), history.last()) {
                    (Some(a), Some(b)) if b.0 > a.0 => (b.1 - a.1) / ((b.0 - a.0) as f64 / 1000.0),
                    _ => 0.0,
                };
                let committed = progress >= self.cfg.edge_commit_progress || v >= self.cfg.edge_commit_velocity;
                out.push(Out::EdgeEnd { edge, progress, committed });
                State::Done
            }
            State::Multi { fingers, start, last, axis, history } => {
                match axis {
                    Some(a) => {
                        let (vx, vy) = match (history.first(), history.last()) {
                            (Some(f), Some(l)) if l.0 > f.0 => {
                                let dt = (l.0 - f.0) as f64 / 1000.0;
                                ((l.1 - f.1) / dt, (l.2 - f.2) / dt)
                            }
                            _ => (0.0, 0.0),
                        };
                        out.push(Out::End {
                            fingers,
                            axis: a,
                            total_dx: last.0 - start.0,
                            total_dy: last.1 - start.1,
                            velocity_x: vx,
                            velocity_y: vy,
                        });
                    }
                    None => out.push(Out::Cancel { fingers }),
                }
                State::Done
            }
            other => other,
        };
        if all_up {
            self.state = State::Idle;
        }
        out
    }

    /// Touch sequence cancelled by the device/compositor. / Secuencia cancelada.
    pub fn cancel(&mut self) -> Vec<Out> {
        self.slots.clear();
        let state = std::mem::replace(&mut self.state, State::Idle);
        match state {
            State::Multi { fingers, start, last, axis: Some(a), .. } => vec![Out::End {
                fingers,
                axis: a,
                total_dx: last.0 - start.0,
                total_dy: last.1 - start.1,
                velocity_x: 0.0,
                velocity_y: 0.0,
            }],
            State::Multi { fingers, .. } => vec![Out::Cancel { fingers }],
            State::EdgeActive { edge, progress, .. } => vec![Out::EdgeEnd { edge, progress, committed: false }],
            _ => vec![],
        }
    }

    /// True while a gesture owns the touch (the compositor must not forward events to clients).
    pub fn is_claimed(&self) -> bool {
        matches!(self.state, State::Multi { .. } | State::EdgeActive { .. } | State::Done)
            && !self.slots.is_empty()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn rec() -> Recognizer<i32> {
        Recognizer::new(Config::new((1920.0, 1280.0)))
    }

    /// Land `n` fingers in the middle, then move all by (dx,dy) in steps. Returns all outputs.
    fn swipe(r: &mut Recognizer<i32>, n: i32, dx: f64, dy: f64) -> Vec<Out> {
        let mut o = vec![];
        for i in 0..n {
            o.extend(r.down(i, (800.0 + i as f64 * 40.0, 600.0), 10 * i as u64));
        }
        let steps = 10;
        for s in 1..=steps {
            for i in 0..n {
                let f = s as f64 / steps as f64;
                o.extend(r.motion(i, (800.0 + i as f64 * 40.0 + dx * f, 600.0 + dy * f), 100 + s as u64 * 16));
            }
        }
        for i in 0..n {
            o.extend(r.up(i, 400));
        }
        o
    }

    #[test]
    fn three_finger_horizontal() {
        let mut r = rec();
        let o = swipe(&mut r, 3, 300.0, 0.0);
        assert_eq!(o[0], Out::Claim);
        assert!(o.contains(&Out::Begin { fingers: 3, axis: Axis::Horizontal }));
        assert!(matches!(o.last().unwrap(), Out::End { fingers: 3, axis: Axis::Horizontal, .. }));
        assert!(!r.is_claimed());
    }

    #[test]
    fn four_finger_up_is_vertical() {
        let mut r = rec();
        let o = swipe(&mut r, 4, 0.0, -300.0);
        assert!(o.contains(&Out::Begin { fingers: 4, axis: Axis::Vertical }));
        assert!(o.iter().any(|e| matches!(e, Out::End { fingers: 4, velocity_y, .. } if *velocity_y < 0.0)));
    }

    #[test]
    fn two_fingers_pass_through() {
        let mut r = rec();
        let o = swipe(&mut r, 2, 300.0, 0.0);
        assert!(o.is_empty());
    }

    #[test]
    fn late_third_finger_passes_through() {
        let mut r = rec();
        r.down(0, (500.0, 500.0), 0);
        r.down(1, (600.0, 500.0), 20);
        let o = r.down(2, (700.0, 500.0), 500); // too late
        assert!(o.is_empty());
        assert!(!r.is_claimed());
    }

    #[test]
    fn three_finger_tap_cancels() {
        let mut r = rec();
        for i in 0..3 {
            r.down(i, (800.0 + i as f64 * 40.0, 600.0), i as u64);
        }
        let mut o = vec![];
        for i in 0..3 {
            o.extend(r.up(i, 80));
        }
        assert_eq!(o, vec![Out::Cancel { fingers: 3 }]);
    }

    #[test]
    fn bottom_edge_swipe_commits() {
        let mut r = rec();
        assert!(r.down(0, (900.0, 1270.0), 0).is_empty());
        let mut o = vec![];
        for s in 1..=10 {
            o.extend(r.motion(0, (900.0, 1270.0 - s as f64 * 15.0), s as u64 * 16));
        }
        o.extend(r.up(0, 200));
        assert_eq!(o[0], Out::Claim);
        assert_eq!(o[1], Out::EdgeBegin { edge: Edge::Bottom });
        assert!(matches!(o.last().unwrap(), Out::EdgeEnd { edge: Edge::Bottom, committed: true, .. }));
    }

    #[test]
    fn short_slow_edge_swipe_not_committed() {
        let mut r = rec();
        r.down(0, (900.0, 1270.0), 0);
        let mut o = vec![];
        for s in 1..=4 {
            o.extend(r.motion(0, (900.0, 1270.0 - s as f64 * 6.0), s as u64 * 200)); // slow, ~24px
        }
        o.extend(r.up(0, 1000));
        assert!(matches!(o.last().unwrap(), Out::EdgeEnd { committed: false, .. }));
    }

    #[test]
    fn edge_touch_moving_along_edge_is_normal() {
        let mut r = rec();
        r.down(0, (900.0, 1270.0), 0);
        let o = r.motion(0, (960.0, 1270.0), 16);
        assert!(o.is_empty());
        assert!(!r.is_claimed());
    }

    #[test]
    fn three_fingers_with_first_in_edge_band_is_multi() {
        let mut r = rec();
        r.down(0, (900.0, 1270.0), 0); // edge band
        r.down(1, (960.0, 1100.0), 20);
        let o = r.down(2, (1020.0, 1100.0), 40);
        assert_eq!(o, vec![Out::Claim]);
        let mut o = vec![];
        for s in 1..=10 {
            let d = s as f64 * 20.0;
            o.extend(r.motion(0, (900.0 + d, 1270.0), 100 + s as u64 * 16));
            o.extend(r.motion(1, (960.0 + d, 1100.0), 100 + s as u64 * 16));
            o.extend(r.motion(2, (1020.0 + d, 1100.0), 100 + s as u64 * 16));
        }
        assert!(o.iter().any(|e| matches!(e, Out::Begin { fingers: 3, axis: Axis::Horizontal })));
    }

    #[test]
    fn state_resets_between_gestures() {
        let mut r = rec();
        swipe(&mut r, 3, 300.0, 0.0);
        let o = swipe(&mut r, 4, 0.0, -300.0);
        assert_eq!(o[0], Out::Claim);
    }
}
