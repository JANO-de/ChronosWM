#!/usr/bin/env python3
"""Run from the repo root (the niri fork). Adds EdgeSwipe + GesturePhase::{Update,Cancel} to niri-ipc.
Idempotent; aborts without writing if the expected text is not found."""
import sys, pathlib
p = pathlib.Path("niri-ipc/src/lib.rs")
s = p.read_text()
if "EdgeSwipe" in s:
    print("already applied"); sys.exit(0)

old_phase = "pub enum GesturePhase {\n    Begin,\n    End,\n}"
new_phase = "pub enum GesturePhase {\n    Begin,\n    Update,\n    End,\n    Cancel,\n}"
anchor = "    GestureTriggered {\n        /// Gesture name, e.g. \"archive\".\n        name: String,\n        fingers: u8,\n        phase: GesturePhase,\n    },\n"
new_ev = anchor + (
    "    /// A touchscreen edge swipe (Chronos). `edge` is \"top\" | \"bottom\" | \"left\" | \"right\";\n"
    "    /// `progress` is 0..1+ along the inward direction (1.0 = edge_travel_px).\n"
    "    EdgeSwipe {\n        edge: String,\n        phase: GesturePhase,\n        progress: f64,\n    },\n")
for o in (old_phase, anchor):
    if s.count(o) != 1:
        sys.exit(f"expected text not found exactly once:\n{o}")
p.write_text(s.replace(old_phase, new_phase).replace(anchor, new_ev))
print("ok: niri-ipc patched")
