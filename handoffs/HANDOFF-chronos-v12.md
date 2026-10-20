# Chronos handoff v12 (replaces v11)
[SANDBOX] review/edit only, nothing compiled. Hardware results below were confirmed by the user on the Surface.

## RESOLVED: iptsd / multitouch
Touch works. 3-finger vertical swipe is recognized (`Update/End fingers:3`) and switches the workspace on screen.

Root cause (confirmed with `systemd.log_level=debug`):
1. iptsd starts (~11.0s), the IPTS kernel driver restarts (`Stopping/Starting IPTS`, ~1s later).
2. Kernel emits a udev `change` event for hidraw0.
3. iptsd's udev rule only sets `TAG+="systemd"` on `add`. On `change`, systemd logs "device is not tagged with systemd" -> `dev-hidraw0.device` plugged->dead -> stop job for `iptsd@dev-hidraw0` -> iptsd spins at 100% CPU, ignores SIGKILL.
4. Not powertop, not chronos/niri, not DisableOnStylus.

Fix (in `hosts/surface/hardware.nix`, working):
- `services.udev.extraRules`: `SUBSYSTEM=="hidraw", ACTION=="change", KERNELS=="*045E:001F*", TAG+="systemd"`
- `systemd.services."iptsd@"` drop-in: `BindsTo=` cleared, `StopWhenUnneeded=no`, `Restart=on-failure`, `RestartSec=1s`, `TimeoutStopSec=5s`, `restartIfChanged=false`. Probably redundant now, harmless.
- `DisableOnPalm=false`, `DisableOnStylus=true` kept.
- `systemd.log_level=debug` kernel param REMOVED (it flooded shutdown/reboot). Do not re-add.

## Chronos niri changes (delivered, state partly unconfirmed)
- `src/niri.rs`: `claim_window_ms` 400 -> 600.
- `src/input/mod.rs`: `on_touch_cancel` now calls `touch_gestures.cancel()` and dispatches the outputs.
- Running build is `niri-c928283` = chronos flake rev `c9282839e60aafe63b9ec4aa2aa730f56ffb3f2a` (flake.lock node `chronos`). It contains the chronos debug logging. Whether it contains 600ms / cancel hook is NOT confirmed.
- Check: in the chronos repo `git grep -n claim_window_ms c928283`. The value may live in `compositor/niri-integration/chronos-debug.patch` (was 400) rather than a niri fork. Apply the change wherever it is, commit, push, `nix flake update chronos`, rebuild.
- Commit `17b5b8e` "claim window 600ms" actually only flipped `DisableOnStylus` in hardware.nix. It did not change the claim window.

## Notes
- Shell `grep` is aliased to `rg` on the desktop: use `command grep`.
- `strings` is not installed on the Surface; use `grep -a`.
- Per-event `info!` logging in `on_touch_*` / gesture outputs is noisy: lower to `debug!` when done testing.
- Deploy: `ssh jano@192.168.0.115`; reboot after deploy (iptsd@ has restartIfChanged=false).

## Next
1. Test 3f horizontal, 4f gestures, and slow 3-finger landings (the 600ms window). Send `journalctl --user -b | command grep chronos | tail -40` if any fail.
2. Confirm 600ms + cancel hook are in the deployed rev (see above).
3. Lower touch logging to `debug!`.
4. Optional: `MyNixOS/modules/home/niri/config.kdl` cursor `hide-after-inactive-ms 1000` (from v10, untested).
5. Continue with the rest of the plan (QML shell: `chronos/shell/shell.qml`).
