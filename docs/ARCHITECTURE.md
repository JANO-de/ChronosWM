# Architecture / Arquitectura  (codename: `chronos`)

## EN
**Goal:** touch-first desktop OS. One compositor, two modes (desktop / tablet), gestures work in both.

| Layer | Tech | Role |
|---|---|---|
| Compositor | Rust, fork of niri (Smithay) | windows, workspaces, gesture recognition, mode state |
| Shell | QML, Quickshell (layer-shell) | island/panel, OSK, spotlight, overview, edge panel |
| IPC | JSON lines over Unix socket | compositor = source of truth, shell = view |

**Core rule:** gesture recognition and window layout are independent.
- `mode` (desktop|tablet) changes only layout policy (floating/tiled vs. maximized+paged).
- Gestures are recognized in the compositor in BOTH modes; they emit IPC events, the shell animates.
- No single flag does both jobs (this was the Denial `mobile_shell` mistake).

**Verified (web):** niri has touchpad gestures and basic touchscreen (scroll, move/resize windows) but
NO multi-finger touchscreen gestures, so that is the main compositor work. Niri also has Overview (25.05+),
IPC, and a Nix flake. Repo is now `niri-wm/niri`.
**Unverified:** exact source files for touch handling (to locate when cloning).

## ES
**Meta:** SO de escritorio táctil. Un compositor, dos modos (escritorio / tablet), gestos en ambos.

**Regla clave:** el reconocimiento de gestos y la geometría de ventanas son independientes.
- `mode` solo cambia la política de layout.
- Los gestos se reconocen siempre en el compositor y se envían por IPC; la shell anima.
- Ningún flag único hace ambas cosas (error de `mobile_shell` en Denial).

**Verificado (web):** niri tiene gestos de touchpad y táctil básico, pero NO gestos multidedo en pantalla táctil;
eso es el trabajo principal. **Sin verificar:** archivos exactos del código táctil.
