import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property bool isOpen: false
    property int desiredPanelWidth: 430
    property int desiredPanelHeight: 800

    Loader {
        id: controlCenterLoader
        active: root.isOpen

        sourceComponent: PanelWindow {
            id: controlCenterPanel
            visible: root.isOpen

            exclusiveZone: 0
            implicitWidth: root.desiredPanelWidth
            implicitHeight: root.desiredPanelHeight

            WlrLayershell.namespace: "quickshell:controlCenter"
            color: "transparent"

            anchors {
                top: true
                right: true
            }

            HyprlandFocusGrab {
                id: grab
                windows: [controlCenterPanel]
                active: controlCenterLoader.active
                onCleared: () => {
                    if (!active) {
                        root.isOpen = false;
                    }
                }
            }

            ControlCenterContent {
                id: content
                anchors.fill: parent
                anchors.margins: 10

                availableHeight: parent.height - anchors.margins * 2
            }

            mask: Region {
                Region {
                    item: content.topWindow
                }
                Region {
                    item: content.bottomWindow.item
                }
            }
        }
    }
}
