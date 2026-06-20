import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services

/**
 * Launcher - Main launcher panel with IPC handler and focus grab
 */
Scope {
    id: root

    property bool isOpen: false
    property int desiredPanelWidth: 500
    property int desiredPanelHeight: 700

    Loader {
        id: launcherLoader
        active: root.isOpen

        sourceComponent: PanelWindow {
            id: launcherPanel
            visible: root.isOpen

            exclusiveZone: 0
            implicitWidth: root.desiredPanelWidth
            implicitHeight: Math.min(root.desiredPanelHeight, searchWidget.implicitHeight + 40)

            WlrLayershell.namespace: "quickshell:launcher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            HyprlandFocusGrab {
                id: grab
                windows: [launcherPanel]
                active: launcherLoader.active
                onCleared: () => {
                    if (!active) {
                        root.isOpen = false;
                    }
                }
            }

            // Center the search widget
            Item {
                anchors.fill: parent

                SearchWidget {
                    id: searchWidget
                    anchors.centerIn: parent
                    width: root.desiredPanelWidth - 40

                    onClose: {
                        root.isOpen = false;
                    }

                    // Handle escape key
                    Keys.onEscapePressed: {
                        root.isOpen = false;
                    }

                    // Handle arrow key navigation
                    Keys.onDownPressed: (event) => {
                        // Navigate to results
                        event.accepted = false;
                    }

                    Keys.onUpPressed: (event) => {
                        // Navigate in results
                        event.accepted = false;
                    }
                }

                // Global escape handler
                Keys.onEscapePressed: {
                    root.isOpen = false;
                }

                // Focus handling
                focus: true
                Keys.forwardTo: [searchWidget]
            }

            // Reset search when opening
            onVisibleChanged: {
                if (visible) {
                    LauncherSearch.query = "";
                    searchWidget.cancelSearch();
                    searchWidget.focusSearchInput();
                }
            }
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.isOpen = !root.isOpen;
        }

        function open(): void {
            root.isOpen = true;
        }

        function close(): void {
            root.isOpen = false;
        }
    }
}
