import QtQuick
import QtQuick.Effects

// Botón con borde neón; brilla cuando está activo
Item {
    id: btn
    property Theme theme
    property string title: ""
    property string subtitle: ""
    property color accent: theme.cyan
    property bool active: false
    property bool enabledBtn: true
    signal clicked()

    implicitHeight: subtitle === "" ? 38 : 58
    opacity: enabledBtn ? 1 : 0.4

    Rectangle {
        id: glow
        anchors.fill: parent
        radius: 9
        color: "transparent"
        border.width: 2
        border.color: btn.accent
        visible: false
    }
    MultiEffect {
        source: glow
        anchors.fill: glow
        visible: btn.active
        shadowEnabled: true
        shadowColor: btn.accent
        shadowBlur: 1.0
        shadowOpacity: 0.9
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        blurMax: 20
        autoPaddingEnabled: true
    }

    Rectangle {
        anchors.fill: parent
        radius: 9
        border.width: btn.active ? 0 : 1
        border.color: mouse.containsMouse ? Qt.lighter(btn.theme.line, 1.6) : btn.theme.line
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: btn.active ? Qt.rgba(btn.accent.r, btn.accent.g, btn.accent.b, 0.28) : (mouse.containsMouse ? btn.theme.panelHi : btn.theme.panel) }
            GradientStop { position: 1; color: btn.active ? Qt.rgba(btn.accent.r, btn.accent.g, btn.accent.b, 0.08) : btn.theme.panel }
        }
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    Column {
        anchors.centerIn: parent
        spacing: 2
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: btn.title
            color: btn.active ? btn.theme.text : Qt.darker(btn.theme.text, 1.25)
            font.family: btn.theme.display
            font.pixelSize: btn.subtitle === "" ? 11 : 15
            font.weight: Font.Black
            font.letterSpacing: btn.subtitle === "" ? 1.5 : 3
        }
        Text {
            visible: btn.subtitle !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            text: btn.subtitle
            color: btn.active ? btn.accent : btn.theme.dim
            font.family: btn.theme.display
            font.pixelSize: 10
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: btn.enabledBtn ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (btn.enabledBtn) btn.clicked()
    }

    scale: mouse.pressed ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 90 } }
}
