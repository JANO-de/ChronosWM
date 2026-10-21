import QtQuick
import qs.services
import qs.components

Column {
    width: parent.width
    DataRow { label: "wifi"; value: Sys.wifiOn ? (Sys.wifiName || "on") : "off"
        MouseArea { anchors.fill: parent; onClicked: Sys.toggleWifi() } }
    DataRow { label: "bluetooth"; value: Sys.bt ? (Sys.btOn ? "on" : "off") : "--"
        MouseArea { anchors.fill: parent; onClicked: Sys.toggleBt() } }
    BarRow { label: "light"; value: Sys.brightness; enabled: Sys.hasBacklight; onMoved: v => Sys.setBrightness(v) }
    BarRow { label: "volume"; value: Sys.volume; enabled: Sys.audio !== null; onMoved: v => Sys.setVolume(v) }
    DataRow { label: "battery"
        value: Sys.hasBattery ? Math.round(Sys.battery * 100) + "%" + (Sys.charging ? " chg" : "") : "--"
        warn: Sys.hasBattery && Sys.battery < 0.15 && !Sys.charging }
    DataRow { label: "silence"; value: Notifs.dnd ? "on" : "off"
        MouseArea { anchors.fill: parent; onClicked: Notifs.dnd = !Notifs.dnd } }
    DataRow { label: "mode"; value: UiState.field ? "field" : "office"
        MouseArea { anchors.fill: parent; onClicked: UiState.mode = UiState.field ? "office" : "field" } }
    DataRow { label: "theme"; value: Theme.name
        MouseArea { anchors.fill: parent; onClicked: Theme.cycle() } }
}
