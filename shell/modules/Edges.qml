// The four edge panels for one screen. Gesture map: docs/IPC.md.
import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.components

Scope {
    id: root
    required property var modelData

    Archive { modelData: root.modelData }
    EdgePanel { modelData: root.modelData; edge: "left"; heading: Vocab.t("spotlight"); focusable: true; IndexPanel {} }
    EdgePanel { modelData: root.modelData; edge: "right"; heading: Vocab.t("quick"); ControlsPanel {} }
    EdgePanel { modelData: root.modelData; edge: "top"; heading: Vocab.t("notifications"); size: 280; MemosPanel {} }
    EdgePanel { modelData: root.modelData; edge: "bottom"; heading: Vocab.t("dock"); size: 200; DockPanel {} }
}
