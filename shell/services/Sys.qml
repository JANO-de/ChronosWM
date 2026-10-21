// Controls data: wifi (nmcli), bluetooth (BlueZ), brightness (brightnessctl), battery (UPower), volume (PipeWire).
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire

Singleton {
    id: root
    readonly property bool watching: UiState.panel === "right"

    property bool wifiOn: false
    property string wifiName: ""
    function toggleWifi() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", wifiOn ? "off" : "on"])
        wifiOn = !wifiOn
    }

    readonly property var bt: Bluetooth.defaultAdapter
    readonly property bool btOn: bt ? bt.enabled : false
    function toggleBt() { if (bt) bt.enabled = !bt.enabled }

    property real brightness: 0
    property bool hasBacklight: false
    function setBrightness(v) {
        brightness = v
        Quickshell.execDetached(["brightnessctl", "-c", "backlight", "set", Math.max(1, Math.round(v * 100)) + "%"])
    }

    readonly property var bat: UPower.displayDevice
    readonly property bool hasBattery: bat ? bat.isPresent : false
    readonly property real battery: bat ? bat.percentage : 0     // 0..1
    readonly property bool charging: bat ? bat.state === UPowerDeviceState.Charging : false

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    readonly property real volume: audio ? audio.volume : 0
    function setVolume(v) { if (audio) { audio.volume = v; audio.muted = false } }

    Timer {
        interval: 3000; repeat: true; triggeredOnStart: true; running: root.watching
        onTriggered: { wifiP.running = true; connP.running = true; briP.running = true }
    }
    Process {
        id: wifiP; command: ["nmcli", "-t", "-f", "WIFI", "g"]
        stdout: StdioCollector { onStreamFinished: root.wifiOn = text.trim() === "enabled" }
    }
    Process {
        id: connP; command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n").find(x => x.indexOf("wireless") >= 0)
                root.wifiName = l ? l.split(":")[0] : ""
            }
        }
    }
    Process {
        id: briP; command: ["brightnessctl", "-c", "backlight", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(",")
                root.hasBacklight = p.length >= 4
                if (root.hasBacklight) root.brightness = parseInt(p[3]) / 100
            }
        }
    }
}
