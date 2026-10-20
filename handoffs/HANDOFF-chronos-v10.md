# Chronos handoff v10 (delta over v9)
Review done on [SANDBOX], nothing compiled.
## Findings
- Uploaded niri src ALREADY contains the debug patch (claim_window 400, output_for_touch, info logs). Deployed status still unknown -> check logs.
- gesture-core logic re-read: 3f/4f path in `down()` looks correct for fingers within claim window; unit tests cover it. Cause is not visible in code -> need logs.
- `on_touch_cancel` does NOT call `touch_gestures.cancel()` (state can stick if iptsd sends cancel). Untested fix: call it there.
- MyNixOS `modules/core/home-manager.nix` hardcodes `tablet = false`: Surface gets scale 1, no touch/tablet `map-to-output`. Touch falls back to first output (ok). Do NOT flip it blindly: tabletTop spawns iio-niri (package absent) and tabletBinds use wvkbd.
- `iptsd@` restartIfChanged=false is ALREADY in hosts/surface/hardware.nix (v9 listed it as untested); still reboot after deploy.
## Delivered
- `MyNixOS/modules/home/niri/config.kdl`: adds `cursor { hide-after-inactive-ms 1000 }` (all hosts). Untested. Place in ~/Proyectos/MyNixOS/modules/home/niri/config.kdl.
## Next
1. [DESKTOP] confirm patch deployed, reboot Surface; [SURFACE] `journalctl --user -b | grep chronos | tail -40`; send output.
2. Optional: hook `touch_gestures.cancel()` in on_touch_cancel.
3. QML shell.
