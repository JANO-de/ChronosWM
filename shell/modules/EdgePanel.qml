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
    readonly property real target: UiState.panel === edge ? 1 : 0
    property real p: 0   // 0 hidden .. 1 open; follows the finger while dragging, then animates to target
    // follow the finger (not when the panel is open and being swiped closed)
    Binding { target: win; property: "p"; value: Math.min(Ipc.progress, 1)
              when: win.dragging && win.target === 0; restoreMode: Binding.RestoreNone }
    onDraggingChanged: if (!dragging) settle.restart()
    onTargetChanged: if (!dragging) settle.restart()
    NumberAnimation { id: settle; target: win; property: "p"; to: win.target; duration: 220; easing.type: Easing.OutCubic }

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
