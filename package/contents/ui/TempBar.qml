import QtQuick
import QtQuick.Layouts

// Barra de temperatura segmentada estilo HUD
RowLayout {
    id: bar
    property Theme theme
    property string label: "CPU"
    property var value: null
    property string note: ""
    property real maxTemp: 100
    readonly property color col: theme.tempColor(value)
    readonly property int lit: value === null ? 0 : Math.round(Math.max(0, Math.min(1, value / maxTemp)) * 24)

    spacing: 10
    Layout.fillWidth: true

    Text {
        text: bar.label
        color: bar.theme.dim
        font.family: bar.theme.display
        font.pixelSize: 11
        font.weight: Font.Black
        font.letterSpacing: 2
        Layout.preferredWidth: 38
    }

    Item {
        id: track
        Layout.fillWidth: true
        implicitHeight: 10
        Row {
        spacing: 2
        Repeater {
            model: 24
            Rectangle {
                width: Math.max(1, (track.width - 23 * 2) / 24)
                height: 10
                radius: 1.5
                color: index < bar.lit ? bar.theme.tempColor(index / 24 * bar.maxTemp + 1) : "#1b2340"
                opacity: index < bar.lit ? 1 : 0.9
                Behavior on color { ColorAnimation { duration: 300 } }
            }
        }
        }
    }

    Text {
        text: bar.value === null ? (bar.note !== "" ? bar.note : "--") : bar.value + "°C"
        color: bar.value === null ? bar.theme.dim : bar.col
        font.family: bar.value === null ? bar.theme.display : bar.theme.mono
        font.pixelSize: bar.value === null ? 10 : 15
        font.weight: Font.Bold
        horizontalAlignment: Text.AlignRight
        Layout.preferredWidth: 64
    }
}
