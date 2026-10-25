import QtQuick

QtObject {
    readonly property color bg: "#090c13"
    readonly property color panel: "#111726"
    readonly property color panelHi: "#18203a"
    readonly property color line: "#232d48"
    readonly property color text: "#e8f1ff"
    readonly property color dim: "#7584a6"
    readonly property color cyan: "#00e5ff"
    readonly property color red: "#ff2d55"
    readonly property color magenta: "#c03cff"
    readonly property color green: "#39ff88"
    readonly property color amber: "#ffb020"
    readonly property string display: "Inter Display"
    readonly property string mono: "JetBrains Mono"

    function tempColor(t) {
        if (t === null || t === undefined) return dim
        if (t < 60) return green
        if (t < 80) return amber
        return red
    }
}
