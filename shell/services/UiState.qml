pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property string panel: ""        // "" | left | right | top | bottom
    property int oskH: 250
    property bool osk: false         // on-screen keyboard
    signal key(string k)             // typed key: char | BKSP | ENTER
    function toggle(edge) { panel = (panel === edge ? "" : edge) }
    function close() { panel = ""; osk = false }
}
