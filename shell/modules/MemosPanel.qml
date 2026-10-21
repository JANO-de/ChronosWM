// Memos = notifications. Tap a memo to dismiss it.
import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.components

Item {
    id: root
    anchors.fill: parent
    SystemClock { id: clock; precision: SystemClock.Seconds }

    Row {
        id: top
        width: parent.width; height: 34
        DataRow { width: parent.width * 0.5 - 6; label: "time"; value: Qt.formatDateTime(clock.date, "HH:mm") }
        Item { width: 12; height: 1 }
        DataRow { width: parent.width * 0.5 - 6; label: Vocab.t("workspace"); value: String(Ipc.timeline) }
    }
    ListView {
        anchors { top: top.bottom; topMargin: 4; left: parent.left; right: parent.right; bottom: parent.bottom }
        clip: true
        model: Notifs.list
        boundsBehavior: Flickable.StopAtBounds
        delegate: Item {
            required property var modelData
            width: ListView.view.width; height: 46
            Text {
                id: sum
                y: 4; width: parent.width; elide: Text.ElideRight
                text: ((modelData.appName ? modelData.appName + ": " : "") + modelData.summary).toUpperCase()
                color: Theme.ink; font.family: Theme.mono; font.pixelSize: 14
            }
            Text {
                anchors.top: sum.bottom; width: parent.width; elide: Text.ElideRight
                text: modelData.body
                color: Theme.dim; font.family: Theme.mono; font.pixelSize: 13
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.dim; opacity: 0.5 }
            MouseArea { anchors.fill: parent; onClicked: modelData.dismiss() }
        }
        Text {
            anchors.centerIn: parent; visible: Notifs.list.length === 0
            text: "NO " + Vocab.t("notifications").toUpperCase()
            color: Theme.dim; font.family: Theme.mono; font.pixelSize: 14
        }
    }
}
