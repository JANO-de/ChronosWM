// OSK layouts: swappable, user-editable, saved to ~/.config/chronos/osk.json
// key = {t: c|n|m|l|shift|edit|close, l: label, k: output, s: shifted output, w: width units}
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var layouts: defaults()
    property int cur: 0
    property bool editing: false
    property int selR: -1
    property int selC: -1
    property string palette: ""          // "" | "set" | "add"
    readonly property var layout: layouts[Math.min(cur, layouts.length - 1)]
    readonly property var rows: layout.rows
    readonly property var selKey: (selR >= 0 && selC >= 0 && rows[selR] && rows[selR][selC]) || null
    readonly property string dir: Quickshell.env("HOME") + "/.config/chronos"

    FileView {
        id: f
        path: root.dir + "/osk.json"
        printErrors: false
        onLoaded: root.load(text())
    }
    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", root.dir])

    function load(t) {
        try {
            const o = JSON.parse(t)
            if (o.layouts && o.layouts.length > 0) { layouts = o.layouts; cur = Math.min(o.current || 0, o.layouts.length - 1) }
        } catch (e) { console.warn("osk.json invalid, using defaults") }
    }
    function save() { f.setText(JSON.stringify({ current: cur, layouts: layouts }, null, 1)) }
    function clone() { return JSON.parse(JSON.stringify(layouts)) }
    function edit(fn) { const l = clone(); fn(l[cur].rows, l); layouts = l; save() }

    // ---- layout switching
    function switchTo(name) {
        if (name === "next") cur = (cur + 1) % layouts.length
        else { const i = layouts.findIndex(x => x.name === name); if (i >= 0) cur = i }
        selR = selC = -1; save()
    }
    // ---- editing
    function setEditing(on) {
        editing = on; palette = ""; selR = selC = -1
        if (!on) edit(rows => { for (let i = rows.length - 1; i > 0; i--) if (rows[i].length === 0) rows.splice(i, 1) })
    }
    function select(r, c) { selR = r; selC = c }
    function swap(d) {
        if (!selKey) return
        const c2 = selC + d
        if (c2 < 0 || c2 >= rows[selR].length) return
        edit(rows => { const a = rows[selR]; const t = a[selC]; a[selC] = a[c2]; a[c2] = t }); selC = c2
    }
    function moveRow(d) {
        if (!selKey) return
        const r2 = selR + d
        if (r2 < 0 || r2 >= rows.length) return
        const c2 = Math.min(selC, rows[r2].length)
        edit(rows => { const k = rows[selR].splice(selC, 1)[0]; rows[r2].splice(c2, 0, k) }); selR = r2; selC = c2
    }
    function width(d) {
        if (!selKey) return
        edit(rows => { const k = rows[selR][selC]; k.w = Math.max(0.5, Math.min(8, (k.w || 1) + d)) })
    }
    function remove() {
        if (!selKey) return
        edit(rows => rows[selR].splice(selC, 1)); selC = Math.min(selC, rows[selR].length - 1)
        if (selC < 0) selR = -1
    }
    function addRow() { edit(rows => rows.push([])) }
    function apply(def) {      // palette choice
        const mode = palette; palette = ""
        if (mode === "set" && selKey) { edit(rows => { def.w = rows[selR][selC].w || 1; rows[selR][selC] = def }) }
        else if (mode === "add") {
            const r = selR >= 0 ? selR : rows.length - 1
            const c = selR >= 0 ? selC + 1 : rows[r].length
            edit(rows => rows[r].splice(c, 0, def)); selR = r; selC = c
        }
    }
    function newLayout() { const l = clone(); l.push({ name: "custom" + (l.length + 1), rows: [[]] }); layouts = l; cur = l.length - 1; save() }
    function dupLayout() { const l = clone(); const c = JSON.parse(JSON.stringify(l[cur])); c.name += "+"; l.push(c); layouts = l; cur = l.length - 1; save() }
    function delLayout() { if (layouts.length < 2) return; const l = clone(); l.splice(cur, 1); layouts = l; cur = 0; save() }
    function reset() { layouts = defaults(); cur = 0; save() }

    // ---- key builders + defaults
    function kc(l, k, s, w) { return { t: "c", l: l, k: k || l, s: s || "", w: w || 1 } }
    function kn(l, k, w) { return { t: "n", l: l, k: k, w: w || 1 } }
    function km(l, k, w) { return { t: "m", l: l, k: k, w: w || 1 } }
    function kl(l, k, w) { return { t: "l", l: l, k: k, w: w || 1 } }
    function chars(str, shifted) { return str.split("").map((c, i) => kc(c, c, shifted ? shifted.charAt(i) : "")) }
    function paletteItems() {
        const out = []
        for (let i = 33; i < 127; i++) out.push(kc(String.fromCharCode(i)))
        out.push(kc("SPACE", " ", "", 3), kn("TAB", "Tab"), kn("ESC", "Escape"), kn("ENTER", "Return", 1.5), kn("<-", "BackSpace"), kn("DEL", "Delete"),
                 kn("INS", "Insert"), kn("HOME", "Home"), kn("END", "End"), kn("PGUP", "Page_Up"), kn("PGDN", "Page_Down"),
                 kn("LEFT", "Left"), kn("DOWN", "Down"), kn("UP", "Up"), kn("RIGHT", "Right"))
        for (let i = 1; i <= 12; i++) out.push(kn("F" + i, "F" + i))
        out.push(km("CTRL", "ctrl"), km("ALT", "alt"), km("SUPER", "logo"), { t: "shift", l: "SHIFT", w: 1.5 },
                 kl("LAY", "next"), { t: "edit", l: "EDIT", w: 1 }, { t: "close", l: "[X]", w: 1 })
        for (const x of layouts) out.push(kl(x.name.toUpperCase(), x.name))
        return out
    }
    function defaults() {
        const shift = { t: "shift", l: "SHIFT", w: 1.5 }
        const edit = { t: "edit", l: "EDIT", w: 1 }
        const close = { t: "close", l: "[X]", w: 1 }
        return [
            { name: "qwerty", rows: [
                chars("1234567890", "!@#$%^&*()"),
                chars("qwertyuiop"),
                [].concat(chars("asdfghjkl"), [kn("<-", "BackSpace")]),
                [].concat([shift], chars("zxcvbnm"), [kn("ENTER", "Return", 1.5)]),
                [kl("123", "symbols"), km("CTRL", "ctrl"), kc("SPACE", " ", "", 3), kc(","), kc("."), kl("FN", "fn"), edit, close]
            ] },
            { name: "symbols", rows: [
                chars("1234567890"),
                chars("@#$%&*-+=/"),
                [].concat(chars("()[]{}<>_|")),
                [].concat([kl("ABC", "qwerty", 1.5)], chars("!?:;\"'~"), [kn("<-", "BackSpace", 1.5)]),
                [kn("TAB", "Tab"), kc("SPACE", " ", "", 4), kc(","), kc("."), kc("^"), kc("`"), edit]
            ] },
            { name: "fn", rows: [
                [kn("ESC", "Escape")].concat(["1","2","3","4","5","6","7","8","9"].map(n => kn("F" + n, "F" + n))),
                [kn("F10", "F10"), kn("F11", "F11"), kn("F12", "F12"), kn("INS", "Insert"), kn("DEL", "Delete"), kn("HOME", "Home"), kn("END", "End"), kn("PGUP", "Page_Up"), kn("PGDN", "Page_Down"), kn("TAB", "Tab")],
                [km("CTRL", "ctrl"), km("ALT", "alt"), km("SUPER", "logo"), kn("LEFT", "Left"), kn("DOWN", "Down"), kn("UP", "Up"), kn("RIGHT", "Right")],
                [kl("ABC", "qwerty", 2), kn("ENTER", "Return", 2), kn("<-", "BackSpace", 2), edit, close]
            ] }
        ]
    }
}
