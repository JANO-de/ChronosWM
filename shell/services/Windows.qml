// Open windows (for the Dock). Refreshed by Ipc on any niri Window* event.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var windows: []   // [{id, app_id, title, is_focused, workspace_id}]
    function refresh() { debounce.restart() }
    function focus(id) { Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", String(id)]) }
    function close(id) { Quickshell.execDetached(["niri", "msg", "action", "close-window", "--id", String(id)]) }
    function iconFor(appId) {
        const e = DesktopEntries.heuristicLookup(appId || "")
        const n = e ? e.icon : ""
        if (n && n.charAt(0) === "/") return "file://" + n
        return (n && Quickshell.iconPath(n, true)) || Quickshell.iconPath("application-x-executable")
    }
    Timer { id: debounce; interval: 120; onTriggered: list.running = true }
    Process {
        id: list; command: ["niri", "msg", "-j", "windows"]
        stdout: StdioCollector { onStreamFinished: { try { root.windows = JSON.parse(text) } catch (e) {} } }
    }
    Component.onCompleted: list.running = true
}
