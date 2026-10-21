// Notification server. Only one process can own org.freedesktop.Notifications (dynisland must not run).
// A new notification pops the Memos panel (top) for 5 s if nothing else is open.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root
    readonly property bool ready: true
    property bool dnd: false
    property bool autoOpened: false
    readonly property var list: server.trackedNotifications.values

    function clear() { for (const n of Array.from(server.trackedNotifications.values)) n.dismiss() }

    Timer {
        id: pop; interval: 5000
        onTriggered: { if (root.autoOpened && UiState.panel === "top") UiState.close(); root.autoOpened = false }
    }
    Connections {
        target: UiState
        function onPanelChanged() { if (UiState.panel !== "top") root.autoOpened = false }
    }
    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        onNotification: n => {
            n.tracked = true
            if (root.dnd || UiState.panel !== "") return
            root.autoOpened = true
            UiState.panel = "top"
            pop.restart()
        }
    }
}
