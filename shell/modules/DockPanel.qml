// Dock = open Dossiers (windows). Tap to focus.
import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.components

Item {
    id: root
    anchors.fill: parent
    ListView {
        anchors.fill: parent
        orientation: ListView.Horizontal
        spacing: 12
        clip: true
        model: Windows.windows
        boundsBehavior: Flickable.StopAtBounds
        delegate: Item {
            required property var modelData
            width: 120; height: ListView.view.height
            Rectangle {
                anchors.fill: parent; color: "transparent"
                border.color: modelData.is_focused ? Theme.ink : Theme.dim
                border.width: modelData.is_focused ? 2 : 1
            }
            Image {
                id: ico
                anchors.horizontalCenter: parent.horizontalCenter; y: 12
                width: 48; height: 48; sourceSize: Qt.size(96, 96)
                source: Windows.iconFor(modelData.app_id)
                onStatusChanged: if (status === Image.Error && source != Quickshell.iconPath("application-x-executable")) source = Quickshell.iconPath("application-x-executable")
            }
            Text {
                anchors { left: parent.left; right: parent.right; top: ico.bottom; topMargin: 8; margins: 6 }
                horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                text: (modelData.title || modelData.app_id || "").toUpperCase()
                color: Theme.ink; font.family: Theme.mono; font.pixelSize: 11
            }
            MouseArea { anchors.fill: parent; onClicked: { Windows.focus(modelData.id); UiState.close() } }
        }
        Text {
            anchors.centerIn: parent; visible: Windows.windows.length === 0
            text: "NO " + Vocab.t("window").toUpperCase() + "S OPEN"
            color: Theme.dim; font.family: Theme.mono; font.pixelSize: 14
        }
    }
}
