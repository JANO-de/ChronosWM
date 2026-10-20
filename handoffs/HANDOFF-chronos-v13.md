# Chronos handoff v13 (replaces v12)
[SANDBOX] nothing compiled/run (no rust/nix here). Everything below is UNTESTED until [DESKTOP] build + [SURFACE] test.

## Done earlier (confirmed on Surface)
iptsd fixed (udev `change` tag rule in hosts/surface/hardware.nix). 3f vertical swipe works. See v12 for root cause.

## This session (UNTESTED)
Gesture map implemented, see docs/IPC.md table.
- `niri/src/input/mod.rs`: `Out::Claim` now cancels the client touch sequence (fixes 1st/2nd finger leaking as taps); recognizer gets output-local coords + real screen size (`chronos_touch_pos`, replaces hard-coded 1920x1080); edge swipes -> IPC `EdgeSwipe`; bottom edge progress >= 1.8 -> `OpenOverview`; 4f horizontal = direction-aware quick switch (MruAdvance + MruConfirm) instead of Begin-only Forward; per-motion logs now `debug!`.
- `niri/src/niri.rs`: `edge_px = 32`, claim window 600.
- `niri/src/ipc/client.rs`: prints `EdgeSwipe`.
- `chronos-gesture-core/src/lib.rs`: 3+ fingers with the first in the edge band now become a multi-finger gesture (was Passthrough); new unit test.
- niri-ipc (NOT uploaded, so scripted): `tools/apply-ipc-edge.py` adds `EdgeSwipe` event and `GesturePhase::{Update,Cancel}`. Run from the fork root BEFORE building. Aborts safely if the text doesn't match.

## Single repo
`tools/migrate-to-single-repo.sh` [DESKTOP]: the niri fork becomes the one repo `~/Proyectos/chronos` (shell/, docs/, nix/, handoffs/ copied in; old folder kept as `chronos-old`; MyNixOS `chronos.url` repointed). gesture-core: ONE copy at `chronos-gesture-core/`. Fork's flake.nix not seen: shell/docs aren't build inputs, so it should be unaffected; if the build breaks, send flake.nix + Cargo.toml.

## Deploy
1. fork root: `python3 tools/apply-ipc-edge.py`; copy delivered files over (paths mirror the repo); `cargo test -p chronos-gesture-core`.
2. `bash tools/migrate-to-single-repo.sh`, then in MyNixOS `nix flake update chronos`, rebuild Surface, REBOOT.
3. [SURFACE] test; `journalctl --user -b | command grep chronos | tail -40`.

## Remaining for "whole WM" (not done)
1. Shell (QML): listen to `EdgeSwipe`/`GestureTriggered`; dock, island, spotlight, quick settings, Archive, Overview morph.
2. Tablet mode: MyNixOS home-manager hardcodes `tablet = false` (no touch `map-to-output`, scale 1); iio rotation (`iio-niri` absent), wvkbd binds.
3. OSK auto-show on text-input focus.
4. Cursor hide (`cursor { hide-after-inactive-ms 1000 }`, untested).
5. Dead-zone/palm tuning on real use.
## Notes
Desktop `grep` is rg: use `command grep`. Surface has no `strings`. Reboot after deploy.
