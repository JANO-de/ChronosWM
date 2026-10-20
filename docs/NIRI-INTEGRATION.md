# niri integration plan / Plan de integración con niri
Read from uploaded `src/` (niri-wm/niri, ~26.04). / Leído del `src/` subido.

## EN
**Findings (verified in source)**
- Touch events enter at `src/input/mod.rs`: `on_touch_down` (~4356), `on_touch_motion` (~4508),
  `on_touch_up` (~4484), `on_touch_frame`, `on_touch_cancel`. Today: overview touch grab, long-press move, forwarding to clients.
  No multi-finger recognition exists.
- Touchpad swipes (`on_gesture_swipe_*`, ~4019) already drive reusable layout APIs, which touchscreen gestures can call:
  `layout.workspace_switch_gesture_begin/update/end`, `view_offset_gesture_*`, `overview_gesture_*` (`src/layout/mod.rs` ~3636-3770).
  Touchpad: 3f = columns (horizontal) / workspaces (vertical), 4f = overview.
- niri already has an IPC event stream (`src/ipc/server.rs`: `Event::OverviewOpenedOrClosed`, `WorkspaceActivated`, ...).
  **Decision: extend niri IPC with Chronos events instead of a second socket.** (`niri-ipc` crate was not uploaded; unverified.)

**Plan**
1. `compositor/gesture-core` (DONE, 9 unit tests pass): pure recognizer, no niri deps.
2. Add `Recognizer` to niri `State`; feed it from the 4 touch handlers. On `Out::Claim` call `handle.cancel(self)`
   and stop forwarding to clients while `is_claimed()`.
3. Map outputs to the existing layout APIs (table below), mirroring the touchpad code.
4. Emit `Event::TouchGesture` / `Event::EdgeSwipe` / `Event::ModeChanged` on the IPC stream for the QML shell.
5. Mode (Office/Field) = layout policy only; gestures stay on in both.

**Open design point:** niri workspaces are vertical, my draft map had horizontal Timelines. Options in handoff.

## ES
Los eventos táctiles entran en `src/input/mod.rs`; no hay reconocimiento multidedo. Los gestos de touchpad ya usan
APIs de layout reutilizables. niri ya tiene flujo de eventos IPC: se extenderá en lugar de crear otro socket.
`gesture-core` está hecho y probado (9 tests). Siguiente: integrarlo en `State` y mapear a las APIs de layout.
