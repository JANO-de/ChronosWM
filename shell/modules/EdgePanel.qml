// A panel that slides in from one screen edge, following the finger (Ipc.progress), then stays open.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

PanelWindow {
    id: win
    required property var modelData
    property string edge: "left"
    property string heading: ""
    property int size: 360
    default property alias content: body.data

    readonly property bool horiz: edge === "left" || edge === "right"
    readonly property bool dragging: Ipc.edge === edge
    property real p: dragging ? Math.min(Ipc.progress, 1) : (UiState.panel === edge ? 1 : 0)
    Behavior on p { NumberAnimation { duration: win.dragging ? 0 : 220; easing.type: Easing.OutCubic } }

    screen: modelData
    anchors {
        left: edge !== "right"; right: edge !== "left"
        top: edge !== "bottom"; bottom: edge !== "top"
    }
    implicitWidth: horiz ? size : 0
    implicitHeight: horiz ? 0 : size
    margins {
        left: edge === "left" ? -(1 - p) * size : 0
        right: edge === "right" ? -(1 - p) * size : 0
        top: edge === "top" ? -(1 - p) * size : 0
        bottom: edge === "bottom" ? -(1 - p) * size : 0
    }
    visible: p > 0.001
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "chronos-" + edge

    Frame {
        anchors.fill: parent
        anchors.margins: 12
        heading: win.heading
        onClose: UiState.close()
        Item { id: body; anchors.fill: parent }
    }
}
