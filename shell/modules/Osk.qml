// ASCII on-screen keyboard: swappable layouts, Keychron-style key editing (EDIT key), terminal print-in animation.
// Layouts live in services/OskLayouts.qml and ~/.config/chronos/osk.json. Types via wtype outside Index.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    anchors { left: true; right: true; bottom: true }
    readonly property int rowH: 48
    readonly property int nRows: Math.max(5, OskLayouts.rows.length)
    implicitHeight: 24 + nRows * rowH + (OskLayouts.editing ? 44 : 0) + 24
    visible: p > 0.001
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "chronos-osk"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // terminal-style reveal: rows print in one by one, header types out
    property real p: UiState.osk ? 1 : 0
    Behavior on p { NumberAnimation { duration: 300 } }
    readonly property real steps: nRows + 1
    readonly property real shown: Math.ceil(p * steps) / steps
    onVisibleChanged: if (UiState.osk) UiState.oskH = implicitHeight
    Binding { target: UiState; property: "oskH"; value: win.implicitHeight; when: UiState.osk }

    property bool shift: false
    property var mods: []

    function wt(args) { Quickshell.execDetached(["wtype"].concat(args)) }
    function modArgs(flag) { return win.mods.flatMap(m => [flag, m]) }
    function fire(d) {
        const L = OskLayouts
        if (d.t === "shift") { shift = !shift; return }
        if (d.t === "m") { mods = mods.indexOf(d.k) >= 0 ? mods.filter(x => x !== d.k) : mods.concat([d.k]); return }
        if (d.t === "l") { L.switchTo(d.k); return }
        if (d.t === "edit") { L.setEditing(true); return }
        if (d.t === "close") { UiState.osk = false; return }
        const inIndex = UiState.panel === "left"
        if (d.t === "c") {
            let out = d.k
            if (shift) out = d.s ? d.s : out.toUpperCase()
            if (inIndex) UiState.key(out)
            else if (out === "-") wt(modArgs("-M").concat(["-k", "minus"], modArgs("-m")))
            else wt(modArgs("-M").concat([out], modArgs("-m")))
        } else if (d.t === "n") {
            if (inIndex) { if (d.k === "BackSpace") UiState.key("BKSP"); else if (d.k === "Return") UiState.key("ENTER") }
            else wt(modArgs("-M").concat(["-k", d.k], modArgs("-m")))
        }
        shift = false; mods = []
    }
    function label(d) {
        if (d.t === "c" && shift) return d.s ? d.s : d.l.toUpperCase()
        return d.l
    }
    function active(d, r, c) {
        if (OskLayouts.editing) return OskLayouts.selR === r && OskLayouts.selC === c
        return (d.t === "shift" && shift) || (d.t === "m" && mods.indexOf(d.k) >= 0)
    }

    component Btn: Item {
        id: b
        property string label: ""
        property bool hot: false
        signal tapped()
        Rectangle {
            anchors.fill: parent; anchors.margins: 2
            color: ma.pressed || b.hot ? Theme.ink : "transparent"
            border.color: Theme.dim; border.width: 1
            Text {
                anchors.centerIn: parent; text: b.label
                color: ma.pressed || b.hot ? Theme.bg : Theme.ink
                font.family: Theme.mono; font.pixelSize: 14
            }
        }
        MouseArea { id: ma; anchors.fill: parent; preventStealing: true; onClicked: b.tapped() }
    }

    Item {
        id: clipper
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: parent.height * win.shown
        clip: true
        Rectangle {
            width: parent.width; height: win.implicitHeight
            color: Theme.bg; border.color: Theme.accent; border.width: 1
        }
        // header
        Text {
            id: head
            x: 12; y: 4; height: 20
            readonly property string full: "> KEYBOARD :: " + OskLayouts.layout.name.toUpperCase()
                + (OskLayouts.editing ? " :: EDIT" : "") + (win.mods.length ? " :: " + win.mods.join("+").toUpperCase() : "")
            text: full.substring(0, Math.round(Math.min(1, win.p * 1.5) * full.length)) + (blink.on ? "█" : " ")
            color: Theme.ink; font.family: Theme.mono; font.pixelSize: 13
            Timer { id: blink; property bool on: true; interval: 500; running: win.visible; repeat: true; onTriggered: on = !on }
        }
        Text {
            anchors { right: parent.right; rightMargin: 12; top: parent.top; topMargin: 4 }
            visible: OskLayouts.editing
            text: "[DONE]"; color: Theme.ink; font.family: Theme.mono; font.pixelSize: 13
            MouseArea { anchors.fill: parent; anchors.margins: -10; onClicked: OskLayouts.setEditing(false) }
        }

        // edit toolbar
        Flickable {
            id: tools
            visible: OskLayouts.editing
            x: 8; y: 26; width: parent.width - 16; height: 40
            contentWidth: trow.width; clip: true; boundsBehavior: Flickable.StopAtBounds
            Row {
                id: trow
                Repeater {
                    model: [
                        { l: "<", f: () => OskLayouts.swap(-1) }, { l: ">", f: () => OskLayouts.swap(1) },
                        { l: "^", f: () => OskLayouts.moveRow(-1) }, { l: "v", f: () => OskLayouts.moveRow(1) },
                        { l: "W-", f: () => OskLayouts.width(-0.5) }, { l: "W+", f: () => OskLayouts.width(0.5) },
                        { l: "SET", f: () => { if (OskLayouts.selKey) OskLayouts.palette = "set" } },
                        { l: "ADD", f: () => OskLayouts.palette = "add" },
                        { l: "DEL", f: () => OskLayouts.remove() },
                        { l: "ROW+", f: () => OskLayouts.addRow() },
                        { l: "LAY>", f: () => OskLayouts.switchTo("next") },
                        { l: "NEW", f: () => OskLayouts.newLayout() },
                        { l: "DUP", f: () => OskLayouts.dupLayout() },
                        { l: "LAY-", f: () => OskLayouts.delLayout() },
                        { l: "RESET", f: () => OskLayouts.reset() }
                    ]
                    Btn { required property var modelData; width: 64; height: 40; label: modelData.l; onTapped: modelData.f() }
                }
            }
        }

        // key rows
        Column {
            id: kb
            visible: OskLayouts.palette === ""
            x: 8; y: 24 + (OskLayouts.editing ? 44 : 0); width: parent.width - 16
            Repeater {
                model: OskLayouts.rows
                Row {
                    id: rowItem
                    required property var modelData
                    required property int index
                    readonly property real avail: kb.width
                    readonly property real sum: modelData.reduce((a, k) => a + (k.w || 1), 0)
                    readonly property real unit: Math.min(avail / 10, avail / Math.max(1, sum))
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: win.rowH
                    Repeater {
                        model: rowItem.modelData
                        Btn {
                            required property var modelData
                            required property int index
                            width: rowItem.unit * (modelData.w || 1); height: win.rowH
                            label: win.label(modelData)
                            hot: win.active(modelData, rowItem.index, index)
                            onTapped: OskLayouts.editing ? OskLayouts.select(rowItem.index, index) : win.fire(modelData)
                        }
                    }
                    // empty row placeholder while editing
                    Text { visible: rowItem.modelData.length === 0; text: "(empty row)"; color: Theme.dim; font.family: Theme.mono; font.pixelSize: 12 }
                }
            }
        }

        // key picker (SET / ADD)
        Item {
            visible: OskLayouts.palette !== ""
            x: 8; y: 24 + 44; width: parent.width - 16; height: win.nRows * win.rowH
            Flickable {
                anchors.fill: parent; clip: true; contentHeight: pal.height; boundsBehavior: Flickable.StopAtBounds
                Flow {
                    id: pal
                    width: parent.width
                    Repeater {
                        model: OskLayouts.palette !== "" ? OskLayouts.paletteItems() : []
                        Btn {
                            required property var modelData
                            width: Math.max(44, modelData.l.length * 11 + 14); height: 40
                            label: modelData.l
                            onTapped: OskLayouts.apply(JSON.parse(JSON.stringify(modelData)))
                        }
                    }
                }
            }
        }
    }
}
