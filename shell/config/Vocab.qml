// UI text only. Code, IPC and config keys stay plain.
pragma Singleton
import Quickshell

Singleton {
    readonly property var table: ({
        desktop: "Office", tablet: "Field", workspace: "Timeline", window: "Dossier",
        overview: "Archive", spotlight: "Index", notifications: "Memos", lock: "Clearance",
        quick: "Controls", dock: "Dock"
    })
    function t(key) { return table[key] || key }
}
