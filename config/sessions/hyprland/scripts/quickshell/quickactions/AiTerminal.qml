//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    // =========================================================
    // --- MODULE CAPABILITIES EXPORT
    // =========================================================
    property int requestedLayoutTemplate: 1
    property string safeActiveEdge: typeof activeEdge !== "undefined" ? activeEdge : "left"

    function s(val) {
        return typeof scaleFunc === "function" ? scaleFunc(val) : val;
    }

    property real baseW: s(320)
    property real baseL: s(220)

    property real preferredWidth: safeActiveEdge === "bottom" ? baseL + 50 : baseW
    property real preferredExtraLength: safeActiveEdge === "bottom" ? baseW : baseL

    property real counterRotation: {
        if (safeActiveEdge === "right") return 180;
        if (safeActiveEdge === "bottom") return 90;
        return 0;
    }

    // =========================================================
    // --- THEMING
    // =========================================================
    property color cSurface0: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.surface0 : "#313244"
    property color cSurface1: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.surface1 : "#45475a"
    property color cText: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.text : "#cdd6f4"
    property color cSubtext0: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.subtext0 : "#a6adc8"
    property color cMauve: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.mauve : "#cba6f7"
    property color cGreen: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.green : "#a6e3a1"

    function alpha(color, a) { return Qt.rgba(color.r, color.g, color.b, a); }

    // =========================================================
    // --- STATE POLLING
    // =========================================================
    property bool sessionRunning: false

    Process {
        id: statusProc
        command: ["bash", "-c", "$HOME/.config/hypr/scripts/quickshell/quickactions/ai_terminal.sh status"]
        stdout: StdioCollector {
            onStreamFinished: {
                var outStr = this.text.trim();
                if (outStr.length > 0) {
                    try { root.sessionRunning = JSON.parse(outStr).running === true; } catch(e) {}
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!statusProc.running) statusProc.running = true
    }

    function toggleSession() {
        var p = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["bash", "-c", "$HOME/.config/hypr/scripts/quickshell/quickactions/ai_terminal.sh"]
                running: true
                onExited: (exitCode) => destroy()
            }
        `, root);
    }

    // =========================================================
    // --- UI
    // =========================================================
    Item {
        id: orientedRoot
        anchors.fill: parent
        rotation: root.counterRotation
        transformOrigin: Item.Center
        width: root.safeActiveEdge === "bottom" ? parent.height : parent.width
        height: root.safeActiveEdge === "bottom" ? parent.width : parent.height
        anchors.centerIn: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: s(4)
            spacing: s(14)

            Text {
                text: "AI Terminal"
                color: root.cText
                font.family: "JetBrains Mono"
                font.pixelSize: s(16)
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: s(14)
                color: root.cSurface0
                border.color: root.sessionRunning ? root.cGreen : root.cSurface1
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 250 } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: s(10)

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: s(14); height: s(14); radius: width / 2
                        color: root.sessionRunning ? root.cGreen : root.cSubtext0
                        Behavior on color { ColorAnimation { duration: 250 } }

                        SequentialAnimation on opacity {
                            running: root.sessionRunning
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.sessionRunning ? "Session active" : "Not running"
                        color: root.sessionRunning ? root.cGreen : root.cSubtext0
                        font.family: "JetBrains Mono"
                        font.pixelSize: s(13)
                        font.bold: true
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.sessionRunning ? "click to show/hide" : "click to launch"
                        color: root.cSubtext0
                        font.family: "Inter"
                        font.pixelSize: s(11)
                        opacity: 0.7
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.toggleSession();
                        statusProc.running = true;
                    }
                }
            }
        }
    }
}
