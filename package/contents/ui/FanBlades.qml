import QtQuick

// Rotor de ventilador dibujado a mano; gira según las RPM reales
Item {
    id: fan
    property color color: "#00e5ff"
    property real rpm: 0
    property bool spinning: true

    Canvas {
        id: blades
        anchors.fill: parent
        antialiasing: true
        onPaint: {
            const ctx = getContext("2d")
            const w = width, h = height, cx = w / 2, cy = h / 2
            const r = Math.min(w, h) / 2
            ctx.reset()
            ctx.fillStyle = fan.color
            for (let i = 0; i < 7; i++) {
                ctx.save()
                ctx.translate(cx, cy)
                ctx.rotate(i * 2 * Math.PI / 7)
                ctx.beginPath()
                ctx.moveTo(0, -r * 0.22)
                ctx.bezierCurveTo(r * 0.45, -r * 0.35, r * 0.62, -r * 0.78, r * 0.18, -r * 0.98)
                ctx.bezierCurveTo(r * 0.02, -r * 0.70, -r * 0.08, -r * 0.45, 0, -r * 0.22)
                ctx.closePath()
                ctx.globalAlpha = 0.92
                ctx.fill()
                ctx.restore()
            }
            ctx.globalAlpha = 1
            ctx.beginPath()
            ctx.arc(cx, cy, r * 0.24, 0, 2 * Math.PI)
            ctx.fillStyle = "#0d1220"
            ctx.fill()
            ctx.lineWidth = Math.max(1.5, r * 0.05)
            ctx.strokeStyle = fan.color
            ctx.stroke()
        }
    }

    onColorChanged: blades.requestPaint()
    onWidthChanged: blades.requestPaint()

    FrameAnimation {
        running: fan.spinning && fan.rpm > 0 && fan.visible
        // 1/20 de la velocidad real para que se vea fluido
        onTriggered: blades.rotation = (blades.rotation + frameTime * fan.rpm / 60 * 360 / 20) % 360
    }
}
