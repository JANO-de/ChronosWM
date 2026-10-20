// niri event stream -> shell state. Compositor emits End only when a swipe committed (Cancel otherwise).
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property bool ready: true
    property string edge: ""         // edge being dragged ("" = none)
    property real progress: 0        // 1.0 = 160 px inward
    property int timeline: 1         // focused workspace idx
    readonly property real overviewAt: 1.8   // bottom swipe past this = compositor Overview

    function feed(ev) {
        if (ev.EdgeSwipe) {
            const s = ev.EdgeSwipe
            if (s.phase === "Begin" || s.phase === "Update") { edge = s.edge; progress = s.progress; return }
            if (s.phase === "End" && !(s.edge === "bottom" && s.progress >= overviewAt)) UiState.toggle(s.edge)
            edge = ""; progress = 0
        } else if (ev.GestureTriggered) {
            const g = ev.GestureTriggered
            if (g.name === "archive" && g.phase === "End")
                Quickshell.execDetached(["niri", "msg", "action", "toggle-overview"])
        }
    }

    Process {
        running: true
        command: ["niri", "msg", "-j", "event-stream"]
        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf("EdgeSwipe") >= 0 || line.indexOf("GestureTriggered") >= 0) {
                    try { root.feed(JSON.parse(line)) } catch (e) {}
                } else if (line.indexOf("Workspace") >= 0) {
                    wsDebounce.restart()
                }
            }
        }
    }
    Timer { id: wsDebounce; interval: 60; onTriggered: wsList.running = true }
    Process {
        id: wsList
        command: ["niri", "msg", "-j", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const f = JSON.parse(text).find(w => w.is_focused)
                    if (f) root.timeline = f.idx
                } catch (e) {}
            }
        }
    }
    Component.onCompleted: wsList.running = true
}
