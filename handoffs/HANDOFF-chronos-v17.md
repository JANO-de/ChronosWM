# Chronos handoff v17 (replaces v16)
User preference: write as little as possible. Reply in the user's language (mixes Spanish and English). User shell is zsh (heredocs work); `grep` is rg, use `command grep`.
[SANDBOX] has no rust/nix/quickshell: nothing is compiled or run there. [DESKTOP] = build machine (~/Proyectos/{chronos,MyNixOS}). [SURFACE] = test device (jano@192.168.0.115 at home, 192.168.9.111 at school; check with `hostname -I`).
Style references: `docs/style-reference/` (Bureau CRT terminal: near-black, one phosphor hue per screen, 1px frames with corner ticks, LABEL ........ VALUE rows, dither, scanlines). Gestures: `docs/IPC.md`.

## Decisions (final, unchanged from v16 unless noted)
- Shell: Quickshell + QML ("Chronos Terminal"). WM: niri fork. One repo `~/Proyectos/chronos` (GitHub JANO-de/ChronosWM); NixOS config `~/Proyectos/MyNixOS` takes it as flake input `chronos`. Run flake commands only from `~/Proyectos/MyNixOS`.
- Shell reads niri over `niri msg -j event-stream`. Always use the FORK `niri` (`/run/current-system/sw/bin/niri`), never dynisland's stock one.
- Look: Terminal (phosphor) default, Office (beige) and Dreamcore (lilac) alternates; one hue per Timeline; backrooms lives in content, not chrome; ASCII for text, bars and icons, plain rectangles for Frames.
- Vocab (UI text only): Timeline = workspace, Dossier = window, Archive = Overview, Index = spotlight, Memos = notifications, Controls = quick settings, Dock, Clearance = lock, Office = desktop mode, Field = tablet mode. Proposed, not approved: Ledger = clipboard history, Capture = screenshot, Transmit = screen recording, Telemetry = system monitor, Cache = scratchpad, Redaction = error state.
- Gestures: 1-2f pass to apps; 3f L/R scroll columns; 3f vertical switch Timeline (UP = next); 4f L/R quick-switch; 4f up Archive; edges: left Index, right Controls, top Memos, bottom short Dock, bottom long niri Overview.
- NEW: mode switch. Office and Field. Field by default on the Surface, Office everywhere else. Toggle: Controls row `mode`, or `chronos-shell ipc mode toggle|set field|set office`.
- NEW: OSK default layout is `es` (Spanish, nodeadkeys).
- Cursor already hides on its own; nothing to configure.
- Deploy = commit chronos and push, `nix flake update chronos` in MyNixOS, commit and push, rebuild, restart `chronos-terminal`; niri changes need a reboot. Never deploy a dirty tree.

## Confirmed on Surface (v17)
- Everything in v16 "Confirmed", plus: OSK works (layouts, edit toolbar, print-in animation, no blank space under the last row, es nodeadkeys default), mode switch (boots into field), panel contents, sliders.
- Still UNTESTED: 4f quick-switch, 4f-up Archive event, OSK typing through `wtype` into other apps, mode toggle hiding the OSK in Office.

## Files (new or changed this session)
- `shell/services/OskLayouts.qml` (singleton; layouts saved to `~/.config/chronos/osk.json`; saved layouts override defaults: `rm` the json after changing defaults).
- `shell/modules/Osk.qml`: fixed height (toolbar space only while editing), rows appear by visibility, edit mode forced off on open/close, shown only when `UiState.field`.
- `shell/services/UiState.qml`: `mode` ("office"|"field"), `field`, default from env `CHRONOS_MODE`. `shell.qml`: IPC target `mode`. `ControlsPanel.qml`: row `mode`.
- MyNixOS `modules/desktop/shell/chronos-terminal.nix`: option `modules.desktop.chronosTerminal.defaultMode` (office|field), exported as `CHRONOS_MODE`; `hosts/surface/tablet.nix` sets it to `field`.
- niri `tablet` flag in `modules/core/home-manager.nix` stays `false` on purpose: that path (touch `map-to-output`, scale 2, wvkbd, iio-niri) references packages that no longer exist in any module. Decide before reviving.

## Lessons (read before debugging)
- Quickshell singletons: a `{` or `}` in the header comment of a `pragma Singleton` file made it load as a plain type, giving "Property 'x' of object OskLayouts is not a function" and `undefined` properties. Keep header comments brace-free. A wrong first diagnosis cost many rounds: read the journal first.
- Journal of the current run only: `ssh jano@192.168.0.115 'journalctl --user -u chronos-terminal --since "-30s" --no-pager | grep -i "osk\|warn\|error"'`.
- Check what is deployed: `S=$(systemctl --user cat chronos-terminal | grep -o "/nix/store/[a-z0-9]*-source/shell" | head -1)` on the Surface, then `grep -c <marker> $S/<file>`. In the repo use `command grep -c <marker> <file>`.
- `git commit` saying "working tree clean" means the file copy did not happen. Check `git status --short` before committing.
- Manual IPC on the Surface: `export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1; qs ipc -p $S call osk toggle` (the `-p` goes after `ipc`). On [DESKTOP]: `chronos-shell ipc <target> <fn>`.
- File cards from the chat did not download for the user: deliver files as zsh heredocs (`cat > path <<'EOF'`) or `git apply <<'EOF'` patches. Use `sed -i '/pattern/a\...'` for one-line Nix edits.
- Screenshot: `ssh jano@192.168.0.115 'export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 NIRI_SOCKET=$(ls /run/user/1000/niri.*.sock | head -1); /run/current-system/sw/bin/niri msg action screenshot-screen'` then `scp "jano@192.168.0.115:$(ssh jano@192.168.0.115 'ls -t ~/Pictures/Screenshots/* | head -1')" ~/shot.png`.
- A rebuild sudo prompt can fail on a typo (it asks twice: local, then target); rerun.
- Fast loop, never-unzip-over-repo, plain vs `-j` event-stream: unchanged from v16.

## Roadmap (v17: 95 items in 5 tiers; the full list lives in the Claude doc "Chronos Roadmap v17", export it to `docs/ROADMAP.md`)
Tier 1 Daily driver (29): Clearance lock, idle chain, power menu, themed greeter, polkit prompt, keyring, safe-mode fallback; palm rejection and dead zones, rotation, OSK auto-show in other apps, Type Cover auto mode, live gesture settings, 4f tests; wifi, Bluetooth, audio pickers, OSD, MPRIS; Capture, Ledger, Memos history, status line, tray, XWayland, portals, window rules, Dock v2, session restore, retire dynisland.
Tier 2 Comfortable (30): floating, Cache, tabbed columns, Dossier switcher, named Timelines, multi-monitor, Index v2, Archive v2, Controls v2, Telemetry, Settings Dossier, pen and Markup, OSK v2.
Tier 3 Theme polish (16): theme tokens file, CRT glow and grain (measure GPU cost first), dither pipeline, ASCII icon growth, transitions, Office and Dreamcore themes, GTK/Qt/terminal theming, boot sequence, accessibility.
Tier 4 Backrooms (11): corridor wallpapers, idle messages, flicker, screensaver, classified Clearance, glitches.
Tier 5 Platform (9): CI, tests, debug overlay, niri rebase, docs, backups, tags.

## Next in order
1. Test 4f quick-switch and the 4f-up Archive event.
2. Retire dynisland, then safe-mode fallback.
3. Palm rejection and dead zones, with live gesture settings.
4. Rotation.
5. OSK auto-show in other apps (needs a niri text-input hook), then Type Cover auto mode.
6. Clearance, idle chain, power menu.
7. Wifi, Bluetooth, audio pickers.
8. Capture and Ledger.
9. Window rules and Dock v2.
10. Theme tokens, then CRT effects.

## Open decisions
- 4f up: toggle niri Overview (current guess) or open a shell panel?
- Dock content: pinned apps, only running windows, or both?
- Greeter: SDDM theme or greetd with a Quickshell greeter?
- Approve the proposed vocab words?
- niri `tablet` flag: revive with new packages, or replace with a Field-only config (touch `map-to-output`, scale)?
- GPU budget for CRT effects on the Surface: always, plugged in only, or off in Field.
