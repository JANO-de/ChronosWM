// ASCII on-screen keyboard. Auto-shows with Index; elsewhere types via wtype. `qs ipc call osk toggle` to force.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    anchors { left: true; right: true; bottom: true }
    implicitHeight: 250
    visible: UiState.osk
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "chronos-osk"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property bool shift: false
    property bool sym: false
    readonly property var rows: sym
        ? ["1234567890", "@#$%&*-+=/", "()[]{}<>_\\", "!?:;\"'.,~^"]
        : ["1234567890", "qwertyuiop", "asdfghjkl", "zxcvbnm,."]

    function send(k) {
        if (UiState.panel === "left") { UiState.key(k); return }
        if (k === "BKSP") Quickshell.execDetached(["wtype", "-k", "BackSpace"])
        else if (k === "ENTER") Quickshell.execDetached(["wtype", "-k", "Return"])
        else Quickshell.execDetached(["wtype", "--", k])
    }
    function press(k) {
        send(shift && k.length === 1 ? k.toUpperCase() : k)
        if (shift) shift = false
    }

    component Key: Item {
        id: k
        property string label: ""
        property real span: 1
        property bool hot: false
        signal tapped()
        width: 0; height: 0
        Rectangle {
            anchors.fill: parent; anchors.margins: 2
            color: down.pressed || k.hot ? Theme.ink : "transparent"
            border.color: Theme.dim; border.width: 1
            Text {
                anchors.centerIn: parent
                text: k.label
                color: down.pressed || k.hot ? Theme.bg : Theme.ink
                font.family: Theme.mono; font.pixelSize: 16
            }
        }
        MouseArea { id: down; anchors.fill: parent; preventStealing: true; onClicked: k.tapped() }
    }

    Rectangle {
        anchors.fill: parent; anchors.margins: 6
        color: Theme.bg; border.color: Theme.accent; border.width: 1
        Column {
            anchors.fill: parent; anchors.margins: 4
            readonly property real rh: height / 5
            Repeater {
                model: win.rows
                Row {
                    required property string modelData
                    required property int index
                    anchors.horizontalCenter: parent.horizontalCenter
                    Repeater {
                        model: modelData.length
                        Key {
                            required property int index
                            readonly property string ch: modelData.charAt(index)
                            width: (win.width - 28) / 10; height: (win.height - 20) / 5
                            label: win.shift ? ch.toUpperCase() : ch
                            onTapped: win.press(ch)
                        }
                    }
                }
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                readonly property real u: (win.width - 28) / 10
                readonly property real h: (win.height - 20) / 5
                Key { width: parent.u * 1.5; height: parent.h; label: "SHIFT"; hot: win.shift; onTapped: win.shift = !win.shift }
                Key { width: parent.u * 1.5; height: parent.h; label: win.sym ? "ABC" : "123"; onTapped: win.sym = !win.sym }
                Key { width: parent.u * 3; height: parent.h; label: "SPACE"; onTapped: win.send(" ") }
                Key { width: parent.u * 1.5; height: parent.h; label: "<-"; onTapped: win.send("BKSP") }
                Key { width: parent.u * 1.5; height: parent.h; label: "ENTER"; onTapped: win.send("ENTER") }
                Key { width: parent.u; height: parent.h; label: "[X]"; onTapped: UiState.osk = false }
            }
        }
    }
}
