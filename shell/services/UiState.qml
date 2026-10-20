pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property string panel: ""        // "" | left | right | top | bottom
    function toggle(edge) { panel = (panel === edge ? "" : edge) }
    function close() { panel = "" }
}
