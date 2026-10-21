// 3-line ASCII icon picked by app name / id. Falls back to a boxed first letter.
import QtQuick
import qs.services

Text {
    id: root
    property string name: ""
    property real size: 14
    readonly property var pack: [
        [["firefox","chrom","browser","brave","zen","web"], "(@)\n/|\\\n www"],
        [["term","kitty","alacritty","foot","wezterm","konsole","ghostty"], "┌──┐\n│>_│\n└──┘"],
        [["code","vim","nvim","emacs","edit","text","kate","gedit","codium","zed"], "┌──┐\n│{}│\n└──┘"],
        [["file","nautilus","dolphin","thunar","nemo","pcmanfm","yazi"], "┌─┐_\n│ └─┐\n└───┘"],
        [["music","spotify","audio","player","rhythm","tidal"], " ♪♫ \n┌──┐\n└○─┘"],
        [["video","vlc","mpv","movie","obs","stream"], "┌───┐\n│ ▶ │\n└───┘"],
        [["image","photo","gimp","krita","inkscape","paint","draw","viewer"], "┌───┐\n│^o^│\n└───┘"],
        [["mail","thunderbird","outlook","geary","evolution"], "┌───┐\n│\\_/│\n└───┘"],
        [["chat","discord","telegram","signal","element","slack","whatsapp","message"], "┌───┐\n│...│\n└─┬─┘"],
        [["setting","config","control","pref","tweak"], " ┌*┐ \n*   *\n └*┘ "],
        [["calc","numbers","spreadsheet","sheet","calligra"], "┌───┐\n│+ -│\n│× ÷│"],
        [["calendar","clock","time","date"], "┌───┐\n│ 21│\n└───┘"],
        [["note","memo","obsidian","joplin","logseq","write","word","doc","libreoffice","pdf","reader","evince","okular","zathura"], "┌──┐\n│≡≡│\n│≡ │"],
        [["game","steam","lutris","minecraft","heroic"], "┌────┐\n│+  o│\n└────┘"],
        [["map","gps","nav"], " /\\ \n/  \\\n\\()/"],
        [["camera","cheese"], " ┌─┐ \n[(o)]\n └─┘ "],
        [["bluetooth","wifi","network","nm-"], " ))) \n  ·  \n  |  "],
        [["monitor","htop","btop","top","task","system"], "┌───┐\n│▂▅█│\n└───┘"],
        [["store","software","discover","flatpak","package"], "┌───┐\n│[#]│\n└───┘"]
    ]
    readonly property string art: {
        const k = (name || "").toLowerCase()
        for (const e of pack)
            for (const w of e[0])
                if (k.indexOf(w) >= 0) return e[1]
        const c = k.replace(/[^a-z0-9]/g, "").charAt(0).toUpperCase() || "?"
        return "┌───┐\n│ " + c + " │\n└───┘"
    }
    text: art
    color: Theme.ink
    font.family: Theme.mono; font.pixelSize: size
    lineHeight: 0.85; horizontalAlignment: Text.AlignHCenter
    textFormat: Text.PlainText
}
