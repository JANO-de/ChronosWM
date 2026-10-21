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

    property real pull: 0   // 0..1 how far the open panel is dragged back toward its edge

    Item {
        anchors.fill: parent
        DragHandler {
            id: dh
            target: null
            xAxis.enabled: win.horiz
            yAxis.enabled: !win.horiz
            onActiveTranslationChanged: {
                if (!active) return
                const t = activeTranslation
                const d = win.edge === "left" ? -t.x : win.edge === "right" ? t.x
                        : win.edge === "top" ? -t.y : t.y
                win.pull = Math.max(0, Math.min(1, d / win.size))
            }
            onActiveChanged: {
                if (active) return
                const q = win.pull
                win.pull = 0
                win.p = 1 - q            // hand the offset over to the window slide
                if (q > 0.3) UiState.close()
                settle.restart()
            }
        }
        Frame {
            anchors.fill: parent
            anchors.margins: 12
            heading: win.heading
            onClose: UiState.close()
            transform: Translate {
                x: win.edge === "left" ? -win.pull * win.size : win.edge === "right" ? win.pull * win.size : 0
                y: win.edge === "top" ? -win.pull * win.size : win.edge === "bottom" ? win.pull * win.size : 0
            }
            Item { id: body; anchors.fill: parent }
        }
    }
}
