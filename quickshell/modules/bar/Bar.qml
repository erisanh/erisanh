import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions

Scope {
    id: bar

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            switch (event.name) {
            case "openwindow":
            case "closewindow":
            case "movewindow":
            case "changefloatingmode":
                Hyprland.refreshToplevels();
                break;
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            color: "transparent"
            implicitHeight: 40

            WlrLayershell.namespace: "quickshell:bar"

            Rectangle {
                anchors.fill: parent
                color: Appearance.m3colors.m3background

                // left section
                RowLayout {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    anchors.leftMargin: 5

                    // distro logo
                    Rectangle {
                        id: distroLogo
                        width: 35
                        height: 30
                        radius: 15
                        color: Appearance.colors.colLayer1
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: "󰣇"
                            color: Appearance.colors.colArchBlue
                            font.bold: true
                            font.pixelSize: 20
                        }
                    }
                    WorkspaceIndicator {}
                    ActiveWindow {}
                }

                // middle section
                RowLayout {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    TimeWidget {}
                }

                // right section
                RowLayout {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 5
                    spacing: 8

                    Media {}
                    Resources {}

                    SysTray {}
                    StatusIcons {}
                    BatteryIndicator {}
                    PowerButton {}
                }
            }

            // // bind Pipewire objects to ensure properties are available
            // PwObjectTracker {
            //     objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
            // }
        }
    }
}
