// 1px dossier frame, corner ticks, title strip. Children go in the body.
import QtQuick
import qs.services

Item {
    id: root
    property string heading: ""
    signal close()
    default property alias content: slot.data
    readonly property int headerH: 32

    Rectangle { anchors.fill: parent; color: Theme.bg; border.color: Theme.accent; border.width: 1 }
    Rectangle { x: 0; y: root.headerH; width: parent.width; height: 1; color: Theme.accent }
    Repeater {
        model: 4
        Rectangle {
            width: 5; height: 5; color: Theme.accent
            x: (index & 1) ? root.width - 3 : -2
            y: (index & 2) ? root.height - 3 : -2
        }
    }
    Text {
        x: 12; height: root.headerH; verticalAlignment: Text.AlignVCenter
        text: root.heading.toUpperCase()
        color: Theme.ink; font.family: Theme.mono; font.pixelSize: 14; font.letterSpacing: 1.5
    }
    Text {
        id: closeBtn
        anchors.right: parent.right; anchors.rightMargin: 12
        height: root.headerH; verticalAlignment: Text.AlignVCenter
        text: "[X]"; color: Theme.dim; font.family: Theme.mono; font.pixelSize: 14
        MouseArea { anchors.fill: parent; anchors.margins: -12; onClicked: root.close() }
    }
    Item {
        id: slot
        x: 12; y: root.headerH + 12
        width: parent.width - 24; height: parent.height - root.headerH - 24
    }
    Scanlines { anchors.fill: parent; visible: Theme.scanlines }
}
