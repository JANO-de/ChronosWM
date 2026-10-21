// LABEL ........ VALUE   (dot leaders)
import QtQuick
import qs.services

Item {
    id: root
    property string label: ""
    property string value: ""
    property bool warn: false
    width: parent ? parent.width : 200
    height: 34
    TextMetrics { id: tm; font.family: Theme.mono; font.pixelSize: 14; text: "." }
    readonly property string l: "▸ " + label.toUpperCase()
    readonly property string v: value.toUpperCase()
    readonly property int dots: Math.max(2, Math.floor(width / Math.max(1, tm.advanceWidth)) - l.length - v.length - 2)

    Text {
        anchors.verticalCenter: parent.verticalCenter; width: parent.width; elide: Text.ElideRight
        text: root.l + " " + ".".repeat(root.dots) + " " + root.v
        color: root.warn ? Theme.warn : Theme.ink; font.family: Theme.mono; font.pixelSize: 14
    }
}
