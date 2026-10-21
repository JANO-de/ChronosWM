// LABEL .... [████░░░░░░] 62%   drag or tap to set 0..1 (does not move the panel)
import QtQuick
import qs.services

Item {
    id: root
    property string label: ""
    property real value: 0
    property bool enabled: true
    signal moved(real v)
    width: parent ? parent.width : 200
    height: 40

    readonly property color col: enabled ? Theme.ink : Theme.dim
    TextMetrics { id: tm; font.family: Theme.mono; font.pixelSize: 14; text: "█" }
    readonly property real cw: Math.max(1, tm.advanceWidth)
    readonly property int cells: Math.max(6, Math.floor(width * 0.5 / cw) - 7)
    readonly property int filled: Math.round(Math.max(0, Math.min(1, value)) * cells)

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.label.toUpperCase()
        color: root.col; font.family: Theme.mono; font.pixelSize: 14
    }
    Text {
        id: bar
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        text: "[" + "█".repeat(root.filled) + "░".repeat(root.cells - root.filled) + "] "
              + String(Math.round(root.value * 100)).padStart(3, " ") + "%"
        color: root.col; font.family: Theme.mono; font.pixelSize: 14
        MouseArea {
            anchors.fill: parent; anchors.margins: -10
            enabled: root.enabled
            preventStealing: true   // keep the drag; the panel's swipe handler must not take it
            function setv(mx) {
                const x0 = 10 + root.cw, w = root.cells * root.cw
                root.moved(Math.max(0, Math.min(1, (mx - x0) / w)))
            }
            onPressed: mouse => setv(mouse.x)
            onPositionChanged: mouse => setv(mouse.x)
        }
    }
    Text {
        anchors.bottom: parent.bottom; width: parent.width; clip: true
        text: "·".repeat(400); color: Theme.dim; font.family: Theme.mono; font.pixelSize: 10
    }
}
