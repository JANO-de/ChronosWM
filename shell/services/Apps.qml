// App list + fuzzy search + tiny calculator for the Index panel.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root
    readonly property var apps: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .map(e => ({
            entry: e, name: e.name, nameL: (e.name || "").toLowerCase(),
            genL: (e.genericName || "").toLowerCase(),
            kwL: Array.from(e.keywords || []).join(" ").toLowerCase()
        }))

    function iconFor(entry) {
        const n = entry ? entry.icon : ""
        if (n && n.charAt(0) === "/") return "file://" + n
        return (n && Quickshell.iconPath(n, true)) || Quickshell.iconPath("application-x-executable")
    }
    // prefix 100, word start 85, inside 60, letters in order 10..35, none -1
    function fz(q, t) {
        if (!t) return -1
        const i = t.indexOf(q)
        if (i === 0) return 100
        if (i > 0) return (t[i - 1] === " " || t[i - 1] === "-") ? 85 : 60
        if (q.length < 2) return -1
        let qi = 0, last = -2, sc = 0
        for (let ti = 0; ti < t.length && qi < q.length; ti++)
            if (t[ti] === q[qi]) { sc += (ti === last + 1) ? 3 : 1; last = ti; qi++ }
        return qi === q.length ? 10 + Math.min(sc, 25) : -1
    }
    function list(query) {
        const q = (query || "").trim().toLowerCase()
        const out = []
        for (const a of apps) {
            if (!q) { out.push({ a: a, s: 0 }); continue }
            const s = Math.max(fz(q, a.nameL), 0.8 * fz(q, a.genL), 0.7 * fz(q, a.kwL))
            if (s > 0) out.push({ a: a, s: s })
        }
        out.sort((x, y) => (y.s - x.s) || x.a.name.localeCompare(y.a.name))
        return out.slice(0, 60).map(o => o.a)
    }
    // digits and + - * / % ^ ( ) . only; safe to eval after the whitelist
    function calc(q) {
        let s = (q || "").toLowerCase().replace(/\s+/g, "").replace(/,/g, ".")
        if (!/\d/.test(s) || !/[-+*\/%^()]/.test(s) || !/^[0-9+\-*\/().%^]*$/.test(s)) return ""
        try {
            const v = eval(s.replace(/\^/g, "**"))
            return (typeof v === "number" && isFinite(v)) ? String(Math.round(v * 1e10) / 1e10) : ""
        } catch (e) { return "" }
    }
}
