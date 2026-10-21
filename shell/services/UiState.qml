pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property string panel: ""        // "" | left | right | top | bottom
    property int oskH: 250
    property bool osk: false         // on-screen keyboard
    // Office = desktop mode, Field = tablet mode. Default from CHRONOS_MODE (Nix sets "field" on the Surface).
    property string mode: Quickshell.env("CHRONOS_MODE") === "field" ? "field" : "office"
    readonly property bool field: mode === "field"
    onModeChanged: if (mode !== "field") osk = false
    signal key(string k)             // typed key: char | BKSP | ENTER
    function toggle(edge) { panel = (panel === edge ? "" : edge) }
    function close() { panel = ""; osk = false }
}
