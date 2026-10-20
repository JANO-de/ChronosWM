// Chronos Terminal. Run from the repo root:  qs -p shell
import QtQuick
// Test without the compositor:  qs -p shell ipc call mock swipe left
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules

ShellRoot {
    Component.onCompleted: Ipc.ready

    Variants { model: Quickshell.screens; Edges {} }

    IpcHandler {
        target: "mock"
        function edge(name: string, phase: string, progress: real): void {
            Ipc.feed({ EdgeSwipe: { edge: name, phase: phase, progress: progress } })
        }
        function swipe(name: string): void {
            Ipc.feed({ EdgeSwipe: { edge: name, phase: "Begin", progress: 0 } })
            Ipc.feed({ EdgeSwipe: { edge: name, phase: "End", progress: 1 } })
        }
        function timeline(n: int): void { Ipc.timeline = n }
    }
    IpcHandler {
        target: "theme"
        function set(name: string): void { Theme.name = name }
        function cycle(): void { Theme.cycle() }
    }
}
