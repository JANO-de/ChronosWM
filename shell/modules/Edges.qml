// The four edge panels for one screen. Gesture map: docs/IPC.md.
import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.components

Scope {
    id: root
    required property var modelData
    SystemClock { id: clock; precision: SystemClock.Seconds }

    EdgePanel {
        modelData: root.modelData; edge: "left"; heading: Vocab.t("spotlight")
        Column { width: parent.width
            DataRow { label: "query"; value: "_" }
            DataRow { label: Vocab.t("window") + "s"; value: "--" }
        }
    }
    EdgePanel {
        modelData: root.modelData; edge: "right"; heading: Vocab.t("quick")
        Column { width: parent.width
            DataRow { label: "signal"; value: "ok" }
            DataRow { label: "battery"; value: "--" }
            DataRow { label: "light"; value: "--" }
            DataRow { id: themeRow; label: "theme"; value: Theme.name
                MouseArea { anchors.fill: parent; onClicked: Theme.cycle() } }
        }
    }
    EdgePanel {
        modelData: root.modelData; edge: "top"; heading: Vocab.t("notifications"); size: 200
        Column { width: parent.width
            DataRow { label: "time"; value: Qt.formatDateTime(clock.date, "HH:mm:ss") }
            DataRow { label: Vocab.t("workspace"); value: String(Ipc.timeline) }
            DataRow { label: Vocab.t("notifications"); value: "0" }
        }
    }
    EdgePanel {
        modelData: root.modelData; edge: "bottom"; heading: Vocab.t("dock"); size: 200
        Column { width: parent.width
            DataRow { label: "launcher"; value: "--" }
            DataRow { label: "running"; value: "--" }
        }
    }
}
