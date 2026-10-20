// Tokens. terminal = phosphor (hue follows the Timeline); office / dreamcore are the alternates.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root
    property string name: "terminal"            // terminal | office | dreamcore
    property int timeline: Ipc.timeline         // 1-based
    property bool scanlines: true

    readonly property var hues: ["#b4b4ff", "#7fb3c8", "#f2c12e", "#ff4fa3", "#ff8a1f"]
    readonly property color hue: hues[(Math.max(timeline, 1) - 1) % hues.length]

    readonly property color bg: name === "office" ? "#d9d0a7" : name === "dreamcore" ? "#16121f" : "#05080a"
    property color accent: name === "office" ? "#5f7a5a" : name === "dreamcore" ? "#c9b8e8" : hue
    readonly property color ink: name === "office" ? "#1d1b16" : accent
    readonly property color dim: Qt.alpha(ink, 0.45)
    readonly property color warn: "#ff6a4d"
    readonly property string mono: "IBM Plex Mono"

    function cycle() {
        const n = ["terminal", "office", "dreamcore"]
        name = n[(n.indexOf(name) + 1) % n.length]
    }
    Behavior on accent { ColorAnimation { duration: 450 } }
}
