import QtQuick
import QtQuick.Effects

// Medidor circular de RPM con brillo neón
Item {
    id: gauge
    property Theme theme
    property string label: "VENT."
    property var rpm: null
    property real maxRpm: 5600
    property color accent: theme.cyan
    property color accent2: theme.magenta
    property bool animate: true

    readonly property real frac: rpm === null ? 0 : Math.max(0, Math.min(1, rpm / maxRpm))
    property real shown: frac
    Behavior on shown { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
    onShownChanged: arc.requestPaint()
    onAccentChanged: arc.requestPaint()

    implicitWidth: 176
    implicitHeight: 176

    Canvas {
        id: arc
        anchors.fill: parent
        visible: false
        antialiasing: true
        onPaint: {
            const ctx = getContext("2d")
            const cx = width / 2, cy = height / 2, r = Math.min(width, height) / 2 - 14
            const start = Math.PI * 0.75, span = Math.PI * 1.5
            ctx.reset()
            ctx.lineCap = "round"
            // pista
            ctx.lineWidth = 10
            ctx.strokeStyle = "#1c2440"
            ctx.beginPath(); ctx.arc(cx, cy, r, start, start + span); ctx.stroke()
            // marcas
            ctx.lineWidth = 2
            for (let i = 0; i <= 20; i++) {
                const a = start + span * i / 20
                const r1 = r - 14, r2 = r - (i % 5 === 0 ? 22 : 18)
                ctx.strokeStyle = (i / 20 <= gauge.shown) ? Qt.rgba(1, 1, 1, 0.55) : "#2a3454"
                ctx.beginPath()
                ctx.moveTo(cx + r1 * Math.cos(a), cy + r1 * Math.sin(a))
                ctx.lineTo(cx + r2 * Math.cos(a), cy + r2 * Math.sin(a))
                ctx.stroke()
            }
            // valor
            if (gauge.shown > 0.002) {
                const g = ctx.createLinearGradient(0, height, width, 0)
                g.addColorStop(0, gauge.accent2)
                g.addColorStop(1, gauge.accent)
                ctx.lineWidth = 10
                ctx.strokeStyle = g
                ctx.beginPath(); ctx.arc(cx, cy, r, start, start + span * gauge.shown); ctx.stroke()
            }
        }
    }

    MultiEffect {
        source: arc
        anchors.fill: arc
        shadowEnabled: true
        shadowColor: gauge.accent
        shadowBlur: 0.9
        shadowOpacity: 0.85
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        blurMax: 24
        autoPaddingEnabled: true
    }

    FanBlades {
        width: parent.width * 0.30
        height: width
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.20
        color: gauge.accent
        rpm: gauge.rpm === null ? 0 : gauge.rpm
        spinning: gauge.animate
        opacity: 0.95
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.54
        spacing: 0
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: gauge.rpm === null ? "--" : gauge.rpm.toLocaleString(Qt.locale("es_ES"), "f", 0)
            color: gauge.theme.text
            font.family: gauge.theme.mono
            font.pixelSize: 26
            font.weight: Font.Bold
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "RPM"
            color: gauge.accent
            font.family: gauge.theme.display
            font.pixelSize: 10
            font.weight: Font.Black
            font.letterSpacing: 3
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        text: gauge.label
        color: gauge.theme.dim
        font.family: gauge.theme.display
        font.pixelSize: 11
        font.weight: Font.Black
        font.letterSpacing: 2.5
    }
}
