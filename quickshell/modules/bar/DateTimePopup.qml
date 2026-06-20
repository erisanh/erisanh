import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.common

Scope {
    id: root

    property bool isOpen: false

    Loader {
        id: popupLoader
        active: root.isOpen

        sourceComponent: PanelWindow {
            id: popupPanel
            visible: root.isOpen

            exclusiveZone: 0
            implicitWidth: 900
            implicitHeight: Math.max(calendarWidget.implicitHeight, weatherWidget.implicitHeight) + 20

            WlrLayershell.namespace: "quickshell:datetime-popup"
            color: "transparent"

            anchors {
                top: true
            }

            HyprlandFocusGrab {
                id: focusGrab
                windows: [popupPanel]
                active: popupLoader.active
                onCleared: () => {
                    if (!active) {
                        root.isOpen = false;
                    }
                }
            }

            // Main content container
            Rectangle {
                id: contentContainer
                anchors.fill: parent
                anchors.margins: 10
                color: Appearance.m3colors.m3background
                radius: 16
                border.color: Appearance.m3colors.m3outlineVariant
                border.width: 1

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: 0

                    // Left panel - Calendar
                    CalendarWidget {
                        id: calendarWidget
                        Layout.preferredWidth: 350
                        Layout.alignment: Qt.AlignTop
                    }

                    // Vertical divider
                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: Math.max(calendarWidget.implicitHeight, weatherWidget.implicitHeight) - 32
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: 16
                        color: Appearance.m3colors.m3outline
                        opacity: 0.3
                    }

                    // Right panel - Weather
                    WeatherWidget {
                        id: weatherWidget
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                    }
                }
            }
        }
    }
}
