# Chronos handoff v9
Machines: [DESKTOP] dev + build + deploy (cargo/nix, ssh to Surface), [SURFACE] touch test (192.168.0.115), [SANDBOX] Claude (no cargo/nix/network; everything I write is logic-reviewed, NOT compiled).
## Guidelines
- Talk as little as possible; English; zip + present outputs; label machine per command; handoff every 2 prompts; state what is untested; say where each file goes.
## Locked
- Gesture Map A: 3f horiz = columns, 3f vert = Timelines, 4f up = Archive (IPC event only), 4f horiz = window switcher (MRU). Map B kept for later, not implemented.
## Current state
- Patched niri fork builds with nix (release + tests passed), deployed to the Surface, running in a niri session with dynisland as placeholder shell.
- **Touch gestures do NOT work**: 1-2 fingers behave normally, 3f and 4f swipes do nothing.
- **Mouse cursor is visible at first** on the Surface (tablet wants it hidden).
- iptsd hang (confirmed from log): `iptsd@dev-hidraw0` hangs on stop after a live `nixos-rebuild switch` (udevd restart), process survives SIGKILL, touch dead everywhere (SDDM too) until reboot.
## Gesture diagnosis (code review only, untested)
Suspect 1: claim window 150 ms (first->third finger) in `gesture-core Config::new` is too tight for human hands.
Suspect 2: `dispatch_chronos_gesture` used `output_under_cursor()` (pointer position); on touch-only it may return None so Begin never starts. `output_for_touch()` is the safe alternative.
Suspect 3 (unchecked): first finger within 24 px of a screen edge -> EdgeCandidate -> a 2nd finger sets Passthrough, so no Multi.
Suspect 4 (unchecked): Config screen is hard-coded (1920,1080); only affects edge swipes (`set_screen` is never called).
## Debug patch (delivered, applied/deployed status UNCONFIRMED)
`chronos-debug.patch` (apply with `git apply` from `~/Proyectos/niri` root): claim_window 400 ms, `output_for_touch().cloned()` in dispatch, `tracing::info!` logs on every touch-down and gesture `Out`. Not compiled.
Read logs on [SURFACE]: `journalctl --user -b | grep chronos | tail -40`. Empty log = patch not deployed, or events never reach the hooks.
## Where everything is
- `~/Proyectos/niri` (git main): the fork. Commits: b2f37c2 chronos gestures, be76018 flake fileset. `chronos-gesture-core/` (copy of recognizer), patched `src/input/mod.rs` (`dispatch_chronos_gesture` ~4364, hooks in `on_touch_down/up/motion`), `src/niri.rs` (`touch_gestures` ~425, init ~2876), `src/ipc/*`, `niri-ipc/`. `flake.nix` fileset must list `./chronos-gesture-core`.
- `~/Proyectos/chronos`: gesture-core source of truth (`compositor/gesture-core`), docs, handoffs. **Two copies of gesture-core exist** (here + niri fork): keep in sync.
- `~/Proyectos/MyNixOS` (git main): `flake.nix` (`chronos.url = "git+file:///home/jano/Proyectos/niri"`, `denialEnabled = false`, surface `niriEnabled = true`), `modules/desktop/niri.nix` (sets fork as `programs.niri.package`, applies to ALL niri hosts), `hosts/surface/tablet.nix` (niri on, session niri; sets `XCURSOR_THEME=blank`, an old Plasma cursor hack), `hosts/surface/hardware.nix` (iptsd), `modules/home/niri.nix` (niri user config via home-manager -> `~/.config/niri/config.kdl`).
- Deploy loop [DESKTOP]: commit in niri -> `cd ~/Proyectos/MyNixOS && nix flake update chronos` -> `sudo nixos-rebuild switch --flake .#surface --target-host jano@192.168.0.115 --sudo --ask-sudo-password --accept-flake-config` -> **reboot the Surface** (live switch can hang iptsd).
- Home-manager collision seen once: move `~/.config/niri/config.kdl.backup` aside on the Surface.
## Untested ideas
- iptsd: `systemd.services."iptsd@".restartIfChanged = false;` in `hosts/surface/hardware.nix`.
- Cursor: niri config `cursor { hide-after-inactive-ms ... }` and/or niri-compatible blank cursor theme in `modules/home/niri.nix`; `XCURSOR_THEME=blank` may not reach niri.
## Next
1. [DESKTOP] apply debug patch if not yet, deploy, reboot Surface; [SURFACE] test gestures; send `journalctl` chronos lines.
2. Fix cause found from logs; then the 1st/2nd-finger gap (old single-touch path runs before claim).
3. Hide cursor on Surface.
4. QML shell (Theme.qml, Vocab.qml, mock IPC, listen for `GestureTriggered` "archive") to replace dynisland.
