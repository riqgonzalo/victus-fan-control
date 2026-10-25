import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Theme { id: vt }

    readonly property string script: Qt.resolvedUrl("../code/victus-fan.sh").toString().replace(/^file:\/\//, "")
    property var st: ({})
    property string error: ""
    property bool busy: false
    readonly property bool turbo: st.pwm === 0
    readonly property color accent: turbo ? vt.red : vt.cyan
    readonly property color accent2: turbo ? vt.amber : vt.magenta
    readonly property bool shown: root.expanded || root.Window.visibility === Window.Windowed || root.Window.visibility === Window.Maximized

    toolTipMainText: "Ventiladores: " + (st.fan1 ?? "--") + " / " + (st.fan2 ?? "--") + " RPM"
    toolTipSubText: (turbo ? "Modo TURBO (máximo)" : "Modo automático") + " · CPU " + (st.cpu ?? "--") + "°C"
    Plasmoid.icon: "temperature-normal"
    Plasmoid.status: PlasmaCore.Types.ActiveStatus

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source)
            const out = (data["stdout"] || "").trim()
            let obj = null
            try { obj = JSON.parse(out) } catch (e) { obj = null }
            if (source.endsWith(" status")) {
                if (obj && obj.ok) {
                    root.st = obj
                    if (!obj.driver) root.error = "No se encontró el driver hp-wmi"
                    else if (!obj.writable) root.error = "Falta el permiso de escritura (regla udev)"
                    else if (root.error.startsWith("No se") || root.error.startsWith("Falta")) root.error = ""
                } else {
                    root.error = "No se pudieron leer los sensores"
                }
            } else {
                root.busy = false
                root.error = (obj && obj.ok) ? "" : (obj && obj.error ? obj.error : "La orden falló")
                refresh()
            }
        }
    }

    function run(args) { exec.connectSource("bash '" + script + "' " + args) }
    function refresh() { run("status") }
    function act(args) { if (busy) return; busy = true; run(args) }

    Timer {
        interval: root.shown ? 1500 : 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    compactRepresentation: MouseArea {
        id: compact
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded
        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.minimumHeight: Kirigami.Units.iconSizes.small
        FanBlades {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) * 0.86
            height: width
            color: root.turbo ? vt.red : (compact.containsMouse ? vt.cyan : Kirigami.Theme.textColor)
            rpm: 0
            spinning: false
        }
    }

    fullRepresentation: Item {
        id: full
        Layout.preferredWidth: 452
        Layout.preferredHeight: 606
        Layout.minimumWidth: 452
        Layout.minimumHeight: 606
        Layout.maximumWidth: 452
        Layout.maximumHeight: 606

        // Fondo oscuro completo (evita bordes claros en modo ventana)
        Rectangle {
            anchors.fill: parent
            color: vt.bg
            radius: full.Window.visibility === Window.Windowed || full.Window.visibility === Window.Maximized ? 0 : 18
        }

        // Marco con degradado neón
        Rectangle {
            id: frame
            anchors.fill: parent
            anchors.margins: 4
            radius: 16
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: root.accent2 }
                GradientStop { position: 1; color: root.accent }
            }
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
        Rectangle {
            id: body
            anchors.fill: frame
            anchors.margins: 1.5
            radius: 15
            gradient: Gradient {
                GradientStop { position: 0; color: "#0e1322" }
                GradientStop { position: 1; color: vt.bg }
            }
            clip: true

            // Rejilla tenue de fondo
            Canvas {
                anchors.fill: parent
                opacity: 0.35
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.strokeStyle = "#1a2442"
                    ctx.lineWidth = 1
                    for (let x = 0; x < width; x += 22) { ctx.beginPath(); ctx.moveTo(x + 0.5, 0); ctx.lineTo(x + 0.5, height); ctx.stroke() }
                    for (let y = 0; y < height; y += 22) { ctx.beginPath(); ctx.moveTo(0, y + 0.5); ctx.lineTo(width, y + 0.5); ctx.stroke() }
                }
            }
            // Destello diagonal
            Rectangle {
                width: parent.width * 1.4; height: 120
                x: -parent.width * 0.2; y: -60
                rotation: -8
                opacity: 0.10
                gradient: Gradient {
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 0.5; color: root.accent }
                    GradientStop { position: 1; color: "transparent" }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                // Cabecera
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Canvas {
                        id: logo
                        width: 30; height: 26
                        property color c1: root.accent
                        onC1Changed: requestPaint()
                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.reset()
                            const g = ctx.createLinearGradient(0, 0, width, height)
                            g.addColorStop(0, root.accent2); g.addColorStop(1, root.accent)
                            ctx.fillStyle = g
                            ctx.beginPath()
                            ctx.moveTo(0, 0); ctx.lineTo(9, 0); ctx.lineTo(15, 15); ctx.lineTo(21, 0)
                            ctx.lineTo(30, 0); ctx.lineTo(18, 26); ctx.lineTo(12, 26); ctx.closePath()
                            ctx.fill()
                        }
                    }
                    ColumnLayout {
                        spacing: -2
                        Text {
                            text: "VICTUS"
                            color: vt.text
                            font.family: vt.display; font.pixelSize: 22; font.weight: Font.Black; font.letterSpacing: 6
                        }
                        Text {
                            text: "CONTROL TÉRMICO"
                            color: root.accent
                            font.family: vt.display; font.pixelSize: 10; font.weight: Font.Black; font.letterSpacing: 3.5
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        radius: 11
                        implicitHeight: 24
                        implicitWidth: pill.implicitWidth + 22
                        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.14)
                        border.color: root.accent
                        border.width: 1
                        Row {
                            id: pill
                            anchors.centerIn: parent
                            spacing: 6
                            Rectangle {
                                width: 7; height: 7; radius: 3.5
                                anchors.verticalCenter: parent.verticalCenter
                                color: root.accent
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    running: root.shown
                                    NumberAnimation { to: 0.25; duration: 700 }
                                    NumberAnimation { to: 1; duration: 700 }
                                }
                            }
                            Text {
                                text: root.turbo ? "TURBO" : "AUTO"
                                color: vt.text
                                font.family: vt.display; font.pixelSize: 10; font.weight: Font.Black; font.letterSpacing: 2
                            }
                        }
                    }
                }

                // Medidores
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    spacing: 0
                    FanGauge {
                        theme: vt
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        label: "VENTILADOR 1"
                        rpm: root.st.fan1 ?? null
                        accent: root.accent
                        accent2: root.accent2
                        animate: root.shown
                    }
                    FanGauge {
                        theme: vt
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        label: "VENTILADOR 2"
                        rpm: root.st.fan2 ?? null
                        accent: root.accent
                        accent2: root.accent2
                        animate: root.shown
                    }
                }

                // Temperaturas
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: temps.implicitHeight + 24
                    radius: 12
                    color: Qt.rgba(0.07, 0.09, 0.15, 0.85)
                    border.color: vt.line
                    ColumnLayout {
                        id: temps
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 9
                        TempBar { theme: vt; label: "CPU"; value: root.st.cpu ?? null }
                        TempBar {
                            theme: vt; label: "GPU"; value: root.st.gpu ?? null
                            note: root.st.gpuState === "suspended" ? "EN REPOSO" : "--"
                        }
                        TempBar { theme: vt; label: "SSD"; value: root.st.ssd ?? null; maxTemp: 85 }
                    }
                }

                // Modo de ventiladores
                Text {
                    text: "MODO DE VENTILADORES"
                    color: vt.dim
                    font.family: vt.display; font.pixelSize: 10; font.weight: Font.Black; font.letterSpacing: 2.5
                    Layout.topMargin: 2
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    NeonButton {
                        theme: vt
                        Layout.fillWidth: true
                        title: "AUTO"
                        subtitle: "El equipo decide"
                        accent: vt.cyan
                        active: root.st.pwm === 2
                        enabledBtn: !root.busy && root.st.writable === true
                        onClicked: root.act("auto")
                    }
                    NeonButton {
                        theme: vt
                        Layout.fillWidth: true
                        title: "TURBO"
                        subtitle: "Ventiladores al 100 %"
                        accent: vt.red
                        active: root.st.pwm === 0
                        enabledBtn: !root.busy && root.st.writable === true
                        onClicked: root.act("max")
                    }
                }

                // Perfil de energía
                Text {
                    text: "PERFIL DE ENERGÍA"
                    color: vt.dim
                    font.family: vt.display; font.pixelSize: 10; font.weight: Font.Black; font.letterSpacing: 2.5
                    Layout.topMargin: 2
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: [
                            { id: "power-saver", name: "AHORRO", col: vt.green },
                            { id: "balanced", name: "EQUILIBRADO", col: vt.cyan },
                            { id: "performance", name: "RENDIMIENTO", col: vt.red }
                        ]
                        NeonButton {
                            required property var modelData
                            theme: vt
                            Layout.fillWidth: true
                            title: modelData.name
                            accent: modelData.col
                            active: root.st.profile === modelData.id
                            enabledBtn: !root.busy
                            onClicked: root.act("profile " + modelData.id)
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Pie
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: root.error !== "" ? "⚠ " + root.error
                                            : "Driver hp-wmi · modos Auto y Turbo del firmware HP"
                    color: root.error !== "" ? vt.amber : Qt.darker(vt.dim, 1.15)
                    font.family: vt.display; font.pixelSize: 10; font.weight: Font.DemiBold
                }
            }
        }
    }
}
