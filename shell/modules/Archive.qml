// Archive = niri Overview. The compositor draws it; the shell adds a header strip. Touches pass through.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true }
    implicitHeight: 52
    visible: Ipc.overview
    color: "transparent"
    exclusiveZone: 0
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "chronos-archive"

    Rectangle {
        x: 12; y: 12; width: parent.width - 24; height: 32
        color: Theme.bg; border.color: Theme.accent; border.width: 1
        Text {
            x: 12; height: parent.height; verticalAlignment: Text.AlignVCenter
            text: Vocab.t("overview").toUpperCase()
            color: Theme.ink; font.family: Theme.mono; font.pixelSize: 14; font.letterSpacing: 1.5
        }
        Text {
            anchors.centerIn: parent
            text: (Vocab.t("workspace") + " " + Ipc.timeline).toUpperCase()
            color: Theme.ink; font.family: Theme.mono; font.pixelSize: 14
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 12; height: parent.height
            verticalAlignment: Text.AlignVCenter
            text: (Vocab.t("window") + "s").toUpperCase()
            color: Theme.dim; font.family: Theme.mono; font.pixelSize: 14
        }
    }
}
