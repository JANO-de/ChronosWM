import QtQuick

Canvas {
    opacity: 0.2
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const c = getContext("2d")
        c.clearRect(0, 0, width, height)
        c.fillStyle = "#000"
        for (let y = 0; y < height; y += 3) c.fillRect(0, y, width, 1)
    }
}
