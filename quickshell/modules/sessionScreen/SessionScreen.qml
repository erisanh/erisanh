import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Scope {
    id: root

    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)

    Loader {
        id: sessionLoader
        active: Session.sessionOpen

        sourceComponent: PanelWindow {
            id: sessionPanel
            visible: sessionLoader.active
            property string subtitle: ""

            function hide() {
                Session.sessionOpen = false;
            }

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:session"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: ColorUtils.transparentize(Appearance.m3colors.m3background, 0.05)

            anchors {
                top: true
                left: true
                right: true
            }

            implicitWidth: root.focusedScreen?.width ?? 1920
            implicitHeight: root.focusedScreen?.height ?? 1080

            // Click outside to close
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    sessionPanel.hide();
                }
            }

            // Main content
            ColumnLayout {
                id: contentColumn
                anchors.centerIn: parent
                spacing: 20

                focus: true

                // Global keyboard handling for Esc
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        sessionPanel.hide();
                        event.accepted = true;
                    }
                }

                // Title
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Session"
                    color: Appearance.colors.colOnLayer0
                    font.pixelSize: 28
                    font.bold: true
                }

                // Subtitle / instruction
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Arrow keys or vim keys to navigate, Enter to select\nEsc or click anywhere to cancel"
                    color: Appearance.colors.colSubtext
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                }

                // Action buttons grid (3x2)
                GridLayout {
                    Layout.alignment: Qt.AlignHCenter
                    columns: 3
                    columnSpacing: 20
                    rowSpacing: 20

                    SessionActionButton {
                        id: btnLock
                        focus: sessionLoader.active
                        buttonIconSource: "system-lock-screen-symbolic.svg"
                        buttonText: "Lock"
                        onClicked: Session.lock()
                        Keys.onPressed: event => handleNavigation(event, null, btnSleep, btnShutdown, null)
                    }

                    SessionActionButton {
                        id: btnSleep
                        buttonIcon: "dark_mode"
                        buttonText: "Sleep"
                        onClicked: Session.suspend()
                        Keys.onPressed: event => handleNavigation(event, btnLock, btnLogout, btnHibernate, null)
                    }

                    SessionActionButton {
                        id: btnLogout
                        buttonIconSource: "system-log-out-symbolic.svg"
                        buttonText: "Logout"
                        onClicked: Session.logout()
                        Keys.onPressed: event => handleNavigation(event, btnSleep, null, btnReboot, null)
                    }

                    SessionActionButton {
                        id: btnShutdown
                        buttonIconSource: "system-shutdown-symbolic.svg"
                        buttonText: "Shutdown"
                        onClicked: Session.poweroff()
                        Keys.onPressed: event => handleNavigation(event, null, btnHibernate, null, btnLock)
                    }

                    SessionActionButton {
                        id: btnHibernate
                        buttonIcon: "downloading"
                        buttonText: "Hibernate"
                        onClicked: Session.hibernate()
                        Keys.onPressed: event => handleNavigation(event, btnShutdown, btnReboot, null, btnSleep)
                    }

                    SessionActionButton {
                        id: btnReboot
                        buttonIconSource: "system-reboot-symbolic.svg"
                        buttonText: "Reboot"
                        onClicked: Session.reboot()
                        Keys.onPressed: event => handleNavigation(event, btnHibernate, null, null, btnLogout)
                    }
                }

                // Currently focused action label
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    visible: sessionPanel.subtitle !== ""
                    width: subtitleText.implicitWidth + 24
                    height: subtitleText.implicitHeight + 12
                    color: Appearance.colors.colTooltip
                    radius: 8

                    Text {
                        id: subtitleText
                        anchors.centerIn: parent
                        text: sessionPanel.subtitle
                        color: Appearance.colors.colOnTooltip
                        font.pixelSize: 14
                    }
                }
            }

            // Update subtitle when focus changes
            Connections {
                target: btnLock
                function onFocusChanged() { if (btnLock.focus) sessionPanel.subtitle = btnLock.buttonText; }
            }
            Connections {
                target: btnSleep
                function onFocusChanged() { if (btnSleep.focus) sessionPanel.subtitle = btnSleep.buttonText; }
            }
            Connections {
                target: btnLogout
                function onFocusChanged() { if (btnLogout.focus) sessionPanel.subtitle = btnLogout.buttonText; }
            }
            Connections {
                target: btnHibernate
                function onFocusChanged() { if (btnHibernate.focus) sessionPanel.subtitle = btnHibernate.buttonText; }
            }
            Connections {
                target: btnShutdown
                function onFocusChanged() { if (btnShutdown.focus) sessionPanel.subtitle = btnShutdown.buttonText; }
            }
            Connections {
                target: btnReboot
                function onFocusChanged() { if (btnReboot.focus) sessionPanel.subtitle = btnReboot.buttonText; }
            }

            // Navigation helper function (arrow keys + vim keys)
            function handleNavigation(event, left, right, down, up) {
                // Left: Arrow Left or 'h'
                if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                    if (left) left.forceActiveFocus();
                    event.accepted = true;
                }
                // Right: Arrow Right or 'l'
                else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                    if (right) right.forceActiveFocus();
                    event.accepted = true;
                }
                // Down: Arrow Down or 'j'
                else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                    if (down) down.forceActiveFocus();
                    event.accepted = true;
                }
                // Up: Arrow Up or 'k'
                else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                    if (up) up.forceActiveFocus();
                    event.accepted = true;
                }
                // Escape
                else if (event.key === Qt.Key_Escape) {
                    sessionPanel.hide();
                    event.accepted = true;
                }
            }
        }
    }

    IpcHandler {
        target: "session"

        function toggle(): void {
            Session.sessionOpen = !Session.sessionOpen;
        }

        function open(): void {
            Session.sessionOpen = true;
        }

        function close(): void {
            Session.sessionOpen = false;
        }
    }
}
