# Chronos handoff v14 (replaces v13)
User preference: write as little as possible. Reply in the user's language. Desktop `grep` is rg: use `command grep`.
[SANDBOX] has no rust/nix/quickshell: nothing is compiled or run there. [DESKTOP] = build machine. [SURFACE] = test device (jano@192.168.0.115).

## Decisions (final)
- Shell: Quickshell + QML ("Chronos Terminal"), replaces dynisland. dynisland stays installed, autostart disabled.
- One repo: `~/Proyectos/chronos` (GitHub JANO-de/ChronosWM) holds niri fork + `shell/` + docs. NixOS config: `~/Proyectos/MyNixOS` (flake input `chronos = git+file:///home/jano/Proyectos/chronos`).
- Theme: light for now. Phosphor default (near-black bg, one hue per Timeline: violet, teal, amber, magenta, orange), scanlines on, theme switch Terminal / Office / Dreamcore. Vocab (UI text only): Timeline, Dossier, Archive (overview), Index (spotlight), Memos, Clearance, Office/Field.
- Gesture map: `docs/IPC.md` (left=Index, right=Controls, top=Memos, bottom short=Dock, bottom >= 1.8 = niri Overview, 4f up = Archive event).

## Confirmed on Surface
- niri fork emits `EdgeSwipe` for all four edges (Begin/Update/End, progress up to ~5). Compositor sends End only if committed, Cancel otherwise.
- Shell autostarts via systemd user service `chronos-terminal`; left, right, top panels open on real edge swipes.
- On [DESKTOP]: hue follows `ipc call mock timeline N`, theme switch works (Dreamcore, amber).

## NOT yet tested
- Bottom short swipe -> Dock panel on touch.
- Panels following the finger smoothly (Behavior on `p` may snap on release).
- Hue following a real workspace switch (3f vertical swipe).
- v13 niri changes: Claim cancelling client touches, 4f quick-switch, 4f-up Archive (`GestureTriggered`).
- 4f-up currently runs `niri msg action toggle-overview` (a guess).

## Files
Chronos `shell/`: `shell.qml` (mock + theme IpcHandlers), `config/Vocab.qml`, `services/{Theme,Ipc,UiState}.qml`, `components/{Frame,DataRow,Scanlines}.qml`, `modules/{Edges,EdgePanel}.qml`.
- `Ipc.qml`: runs `niri msg -j event-stream`; any `EdgeSwipe` End toggles that panel (except bottom >= 1.8); re-reads `niri msg -j workspaces` on Workspace events for the Timeline hue.
- MyNixOS: `modules/desktop/shell/chronos-terminal.nix` (option `modules.desktop.chronosTerminal.enable`, set true in `hosts/surface/tablet.nix`, imported in `modules/desktop/shell/default.nix`). Service runs `qs -p ${inputs.chronos}/shell` with the FORK niri first in PATH. Helper `chronos-shell {start|stop|dev|ipc|log}` (`dev` expects the repo at `~/Proyectos/chronos/shell` on the machine it runs on; the Surface has no repo, use the scp loop below).

## Workflow / lessons
- Shell-only change: `git commit` in chronos, then in MyNixOS `nix flake update chronos`, rebuild, `systemctl --user restart chronos-terminal`. A dirty chronos tree gave a stale store copy: always commit first.
- Fast loop without rebuild: `scp -r ~/Proyectos/chronos/shell jano@192.168.0.115:~/chronos-shell`, then run `qs -p ~/chronos-shell` with the env below.
- niri changes need a REBOOT (nixos-rebuild does not restart niri.service).
- SSH has no session env: `export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 PATH=/run/current-system/sw/bin:$PATH NIRI_SOCKET=$(ls /run/user/1000/niri.*.sock | head -1)`.
- Stock `niri` from dynisland's runtimeDeps is on the user PATH and cannot parse fork events (`unknown variant TouchpadToggled`). Use the fork binary (`/run/current-system/sw/bin/niri`).
- Plain `niri msg event-stream` prints text ("Edge swipe: left Update (progress 0.44)"); `-j` prints JSON (what the shell reads).
- Test without touch: `qs -p <shell> ipc call mock swipe left|right|top|bottom`, `ipc call mock timeline 3`, `ipc call theme set terminal|office|dreamcore`.
- Surface has no `strings`.

## Known gaps
Top/bottom panels are full-width windows; no tap-outside-to-close; panel contents are placeholders (Index query, battery/light `--`, Dock `--`); no wallpaper; IBM Plex Mono must be installed (added via `fonts.packages`).

## Roadmap, next in order
1. Archive / Overview (NEXT): decide who owns it (niri renders Overview; shell adds Timeline labels/tint). Shell should react to niri `OverviewOpenedOrClosed`; decide the 4f-up behaviour (toggle-overview vs shell panel); style the Archive.
2. Verify on touch: bottom Dock, finger-following, hue on real Timeline switch; fix the release snap if present; add tap-outside close.
3. Real panel content: Index (app search/launcher), Controls (wifi, bt, battery, brightness, volume), Memos (notifications), Dock (running apps).
4. OSK auto-show on text-field focus (needs a compositor/text-input hook or shell request; `wvkbd` binds).
5. Tablet mode: MyNixOS home-manager hardcodes `tablet = false` (no touch `map-to-output`, scale 1); iio rotation (`iio-niri` absent).
6. Cursor hide (`cursor { hide-after-inactive-ms 1000 }`, untested).
7. Palm / dead-zone tuning on real use.
8. Theme polish (CRT glow, grain, dither, fluorescent flicker), Vocab everywhere, retire dynisland.
