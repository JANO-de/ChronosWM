# IPC protocol v0 (draft) / Protocolo IPC v0 (borrador)

> UPDATE: niri already has an IPC event stream. Plan is to ADD these events/requests to niri's IPC (see NIRI-INTEGRATION.md) rather than a separate socket; the message shapes below stay as the design. / Se añadirán al IPC de niri en vez de un socket aparte.

Socket: `$XDG_RUNTIME_DIR/chronos.sock`. One JSON object per line. / Un objeto JSON por línea.

## Compositor -> Shell (events / eventos)
```json
{"ev":"mode","mode":"desktop|tablet"}
{"ev":"gesture","kind":"swipe","fingers":3,"dir":"left|right|up|down","phase":"begin|update|end|cancel","dx":0.0,"dy":0.0,"progress":0.0,"velocity":0.0}
{"ev":"edge","edge":"bottom|top|left|right","phase":"begin|update|end|cancel","progress":0.0}
{"ev":"workspace","id":2,"count":4}
{"ev":"overview","open":true}
{"ev":"osk_hint","want":true}
```
`progress` is 0..1 so the shell can follow the finger. / `progress` 0..1 para seguir el dedo.

## Shell -> Compositor (requests / peticiones)
```json
{"req":"set_mode","mode":"tablet"}
{"req":"toggle_mode"}
{"req":"focus_workspace","id":2}
{"req":"overview","open":true}
{"req":"osk","visible":true}
```
Reply: `{"ok":true}` or `{"ok":false,"err":"..."}`.

## Gesture map (implemented, Map A + edges)
| Gesture | Owner | Action |
|---|---|---|
| 1-2 fingers | clients | tap, scroll, pinch pass through |
| 3f swipe L/R | compositor | scroll columns |
| 3f swipe up/down | compositor | switch Timeline (workspace) |
| 4f swipe up | shell | Archive: `GestureTriggered{name:"archive"}` |
| 4f swipe L/R | compositor | quick-switch window (left = next, right = previous) |
| Bottom edge, progress < 1.8 | shell | dock / launcher (`EdgeSwipe` bottom) |
| Bottom edge, progress >= 1.8 | compositor | Overview (also `EdgeSwipe` End) |
| Top edge | shell | island / notifications (`EdgeSwipe` top) |
| Left edge | shell | spotlight (`EdgeSwipe` left) |
| Right edge | shell | quick settings (`EdgeSwipe` right) |

niri IPC events (event stream): `GestureTriggered{name,fingers,phase}` and
`EdgeSwipe{edge:"top|bottom|left|right",phase:Begin|Update|End|Cancel,progress}`.
`progress` 1.0 = 160 px inward; commit at 0.4 progress or 600 px/s. Edge band = 32 px.
OSK: shown automatically on text-field focus (no gesture).
