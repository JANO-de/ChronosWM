// LABEL ........ VALUE
import QtQuick
import qs.services

Item {
    id: root
    property string label: ""
    property string value: ""
    property bool warn: false
    width: parent ? parent.width : 200
    height: 34

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.label.toUpperCase()
        color: Theme.ink; font.family: Theme.mono; font.pixelSize: 14
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right
        text: root.value.toUpperCase()
        color: root.warn ? Theme.warn : Theme.ink; font.family: Theme.mono; font.pixelSize: 14
    }
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.dim }
}
