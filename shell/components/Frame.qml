// 1px dossier frame, corner ticks, title strip. Children go in the body.
import QtQuick
import qs.services

Item {
    id: root
    property string heading: ""
    signal close()
    default property alias content: slot.data
    readonly property int headerH: 32

    TextMetrics { id: tm; font.family: Theme.mono; font.pixelSize: 14; text: "═" }
    readonly property int cols: Math.max(10, Math.floor(width / Math.max(1, tm.advanceWidth)))
    readonly property int rows: Math.max(3, Math.floor(height / 18))
    readonly property string title: " " + heading.toUpperCase() + " "
    Rectangle { anchors.fill: parent; color: Theme.bg }
    // top border with title:  ╔═ TITLE ═════════ [X]╗
    Text {
        x: 0; y: 0; height: root.headerH; verticalAlignment: Text.AlignVCenter
        text: "╔═" + root.title + "═".repeat(Math.max(0, root.cols - root.title.length - 8)) + "╗"
        color: Theme.accent; font.family: Theme.mono; font.pixelSize: 14
    }
    Text {
        id: closeBtn
        anchors.right: parent.right; anchors.rightMargin: tm.advanceWidth * 2
        height: root.headerH; verticalAlignment: Text.AlignVCenter
        text: "[X]"; color: Theme.ink; font.family: Theme.mono; font.pixelSize: 14
        MouseArea { anchors.fill: parent; anchors.margins: -12; onClicked: root.close() }
    }
    // divider ╟────╢
    Text {
        x: 0; y: root.headerH - 4
        text: "╟" + "─".repeat(root.cols - 2) + "╢"
        color: Theme.accent; font.family: Theme.mono; font.pixelSize: 14
    }
    // side walls
    Text {
        x: 0; y: root.headerH + 10; width: tm.advanceWidth; height: parent.height - root.headerH - 30; clip: true
        text: "║\n".repeat(root.rows); color: Theme.accent; font.family: Theme.mono; font.pixelSize: 14; lineHeight: 18; lineHeightMode: Text.FixedHeight
    }
    Text {
        x: parent.width - tm.advanceWidth; y: root.headerH + 10; width: tm.advanceWidth; height: parent.height - root.headerH - 30; clip: true
        text: "║\n".repeat(root.rows); color: Theme.accent; font.family: Theme.mono; font.pixelSize: 14; lineHeight: 18; lineHeightMode: Text.FixedHeight
    }
    Text {
        x: 0; y: parent.height - 22
        text: "╚" + "═".repeat(root.cols - 2) + "╝"
        color: Theme.accent; font.family: Theme.mono; font.pixelSize: 14
    }
    Item {
        id: slot
        x: 16; y: root.headerH + 12
        width: parent.width - 32; height: parent.height - root.headerH - 40
    }
    Scanlines { anchors.fill: parent; visible: Theme.scanlines }
}
