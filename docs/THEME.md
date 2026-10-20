# Chronos theme / Tema Chronos

## EN
**Concept:** The Chronos Bureau, a semi-modern, 60s-style agency that monitors universe timelines.
The feel is an empty office at 3 AM: backrooms + dreamcore. Familiar, quiet, slightly wrong.

**Visual language (proposal, to confirm)**
- Palette: stale fluorescent beige `#d9d0a7`, carpet mustard `#b89b3c`, institutional green `#5f7a5a`,
  CRT amber `#ffb347`, dreamcore haze `#c9b8e8`, ink `#1d1b16`.
- Type: typewriter mono for data (Courier Prime / IBM Plex Mono), 60s grotesque for headings. Check nixpkgs availability.
- Texture: film grain, soft vignette, faint ceiling-light flicker, paper/index-card surfaces, rubber-stamp marks.
- Motion: slow, floaty ease; small CRT/VHS glitches only on timeline events. Always respect a reduce-motion toggle.
- Sound (optional later): fluorescent hum, typewriter keys, tape clicks.

**Vocabulary (proposal)**
| Normal | Chronos |
|---|---|
| Desktop mode | Office |
| Tablet mode | Field |
| Workspaces | Timelines |
| Windows | Dossiers |
| Overview | Archive |
| Spotlight | Index |
| Notifications | Memos |
| Lock screen | Clearance |

## ES
**Concepto:** El Buró Chronos, una agencia semimoderna estilo años 60 que vigila las líneas temporales del universo.
Sensación de oficina vacía a las 3 AM: backrooms + dreamcore. Familiar, silencioso, algo extraño.

Paleta, tipografías, texturas, movimiento y vocabulario: ver tablas arriba (propuestas por confirmar).

## Decision / Decisión
- Shell name / Nombre de la shell: **Chronos Terminal**.
- Vocabulary applies to UI text only; code, IPC and config keys stay plain (`workspace`, `window`).
  El vocabulario solo afecta al texto de la UI; código, IPC y claves de config usan nombres neutros.
- Implementation: one translation table in the shell (`shell/config/Vocab.qml`, TODO).

## Update: references & direction / Referencias y dirección
User references: 80s CRT dossier terminals (1px line frames with corner ticks, `LABEL ..... VALUE` rows,
status chrome like `SIGNAL LOW`/`CONNECTED`, 1-bit dithered imagery, grids/waveforms/barcodes/folder icons,
scanlines + glow + grain, pixel/mono font; one serif grainy display face for headings).

**Default theme: "Terminal" (phosphor).** Near-black bg `#05080a`, one phosphor hue per screen.
**Per-Timeline hue** (workspace n uses hue n, cycles): violet `#b4b4ff`, teal `#7fb3c8`, amber `#f2c12e`,
magenta `#ff4fa3`, orange `#ff8a1f`. Switching Timeline (4-finger swipe) tints the whole UI; animate the hue.
**Theme switch (Settings):** Terminal (default) | Office (beige/mustard paper) | Dreamcore (lilac haze pastel).
Backrooms/dreamcore lives in content: dithered empty-corridor wallpapers, odd idle text, light flicker, timeline glitches.

Hues and theme names are proposals; tune on real screens. / Tonos y nombres son propuestas; ajustar en pantalla real.
