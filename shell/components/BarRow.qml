// LABEL ....... [#####     ]   drag or tap the bar to set 0..1
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

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.label.toUpperCase()
        color: Theme.ink; font.family: Theme.mono; font.pixelSize: 14
    }
    Rectangle {
        id: track
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.55; height: 22
        color: "transparent"; border.color: root.enabled ? Theme.ink : Theme.dim; border.width: 1
        Rectangle {
            x: 3; y: 3; height: parent.height - 6
            width: Math.max(0, (parent.width - 6) * root.value)
            color: root.enabled ? Theme.ink : Theme.dim
        }
        MouseArea {
            anchors.fill: parent
            enabled: root.enabled
            onPressed: mouse => root.moved(Math.max(0, Math.min(1, mouse.x / width)))
            onPositionChanged: mouse => root.moved(Math.max(0, Math.min(1, mouse.x / width)))
        }
    }
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.dim }
}
