// Index = spotlight: type to search apps, "2*(3+4)" calculates, tap or Enter launches.
import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.components

Item {
    id: root
    anchors.fill: parent
    property string query: ""
    readonly property var results: Apps.list(query)
    readonly property string calc: Apps.calc(query)
    function launch(a) { a.entry.execute(); UiState.close() }

    Connections {
        target: UiState
        function onPanelChanged() {
            if (UiState.panel === "left") { input.text = ""; input.forceActiveFocus(); UiState.osk = true }
            else { input.focus = false; UiState.osk = false }
        }
    }

    Connections {
        target: UiState
        enabled: UiState.panel === "left"
        function onKey(k) {
            if (k === "BKSP") input.remove(Math.max(0, input.cursorPosition - 1), input.cursorPosition)
            else if (k === "ENTER") { if (root.calc === "" && root.results.length > 0) root.launch(root.results[0]) }
            else input.insert(input.cursorPosition, k)
        }
    }

    Item {
        id: bar
        width: parent.width; height: 38
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "QUERY"; color: Theme.ink; font.family: Theme.mono; font.pixelSize: 14
        }
        TextInput {
            id: input
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.65
            onActiveFocusChanged: if (activeFocus) UiState.osk = true
            horizontalAlignment: TextInput.AlignRight
            color: Theme.ink; font.family: Theme.mono; font.pixelSize: 14
            selectionColor: Theme.accent; selectedTextColor: Theme.bg
            onTextChanged: root.query = text
            Keys.onReturnPressed: { if (root.calc === "" && root.results.length > 0) root.launch(root.results[0]) }
            Keys.onEscapePressed: UiState.close()
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.dim }
    }
    Text {
        id: calcLine
        anchors.top: bar.bottom; anchors.topMargin: 6
        height: root.calc !== "" ? 28 : 0; visible: root.calc !== ""
        text: "= " + root.calc; color: Theme.ink; font.family: Theme.mono; font.pixelSize: 16
    }
    ListView {
        anchors { top: calcLine.bottom; topMargin: 6; left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: UiState.osk ? 250 : 0 }
        clip: true
        model: root.results
        boundsBehavior: Flickable.StopAtBounds
        delegate: Item {
            required property var modelData
            width: ListView.view.width; height: 44
            AsciiIcon {
                id: ico
                x: 0; anchors.verticalCenter: parent.verticalCenter
                width: 44; size: 12
                name: modelData.name + " " + (modelData.entry.id || "")
            }
            Text {
                anchors.left: ico.right; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right; elide: Text.ElideRight
                text: modelData.name.toUpperCase()
                color: Theme.ink; font.family: Theme.mono; font.pixelSize: 14
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.dim; opacity: 0.5 }
            MouseArea { anchors.fill: parent; onClicked: root.launch(modelData) }
        }
    }
}
