import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell.Bluetooth
import "./quickToggles/"
import "./notifications/"
import "./wifiNetwork/"
import "./bluetoothDevice/"

ColumnLayout {
    id: root
    spacing: 10

    implicitWidth: 420

    property real availableHeight: 780 // default fallback

    property int radius: 20
    property int margins: 15
    property int notificationCount: Notifications.list.length

    readonly property real maxNotificationHeight: availableHeight - controlPannel.height - spacing // - margins * 2

    property alias topWindow: controlPannel
    property alias bottomWindow: contentLoader

    property bool wifiPanelOpen: false
    property bool bluetoothPanelOpen: false

    onBluetoothPanelOpenChanged: {
        if (!bluetoothPanelOpen)
            Bluetooth.defaultAdapter.discovering = false;
    }

    Rectangle {
        id: controlPannel

        height: mainLayout.implicitHeight + root.margins * 2

        radius: root.radius
        color: Appearance.m3colors.m3background
        border.width: 1
        border.color: Appearance.m3colors.m3outlineVariant
        Layout.fillWidth: true

        ColumnLayout {
            id: mainLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.margins
            spacing: 10

            RowLayout {
                id: bigToggleRow
                Layout.fillWidth: true
                spacing: 10

                property real buttonBaseWidth: (width - spacing) / 2

                NetworkToggle {
                    Layout.fillWidth: true
                    baseWidth: bigToggleRow.buttonBaseWidth

                    onOpenWifiPanel: {
                        Network.enableWifi();
                        Network.rescanWifi();
                        root.bluetoothPanelOpen = false;
                        root.wifiPanelOpen = true;
                    }
                }

                BluetoothToggle {
                    Layout.fillWidth: true
                    baseWidth: bigToggleRow.buttonBaseWidth

                    onOpenBluetoothPanel: {
                        Bluetooth.defaultAdapter.enabled = true;
                        Bluetooth.defaultAdapter.discovering = true;
                        root.wifiPanelOpen = false;
                        root.bluetoothPanelOpen = true;
                    }
                }
            }

            ButtonGroup {
                Layout.fillWidth: true
                spacing: 10

                PowerProfile {}
                NightLight {}
                IdleInhibitor {}
                GameMode {}
                SilentNotification {}
                MicToggle {}
            }

            ColumnLayout {
                id: slidersLayout
                Layout.fillWidth: true
                spacing: 20

                AudioSlider {}
                BrightnessSlider {}
            }
        }
    }

    // Bottom container: WiFi panel, Bluetooth panel, or notifications

    Loader {
        id: contentLoader
        Layout.fillWidth: true
        Layout.fillHeight: root.wifiPanelOpen || root.bluetoothPanelOpen
        sourceComponent: {
            if (root.wifiPanelOpen)
                return wifiPanelComponent;
            if (root.bluetoothPanelOpen)
                return bluetoothPanelComponent;
            return notificationPanelComponent;
        }
    }

    Component {
        id: wifiPanelComponent

        WiFiPanel {
            onClosePanel: {
                root.wifiPanelOpen = false;
            }
        }
    }

    Component {
        id: bluetoothPanelComponent

        BluetoothPanel {
            onClosePanel: {
                root.bluetoothPanelOpen = false;
            }
        }
    }

    Component {
        id: notificationPanelComponent

        Rectangle {
            id: notificationsPannel
            color: Appearance.m3colors.m3background
            radius: root.radius

            property bool isInitialized: false

            implicitHeight: Math.min(notifColumn.implicitHeight + root.margins * 2, root.maxNotificationHeight)

            height: implicitHeight
            border.width: 1
            border.color: Appearance.m3colors.m3outlineVariant
            visible: root.notificationCount > 0

            Component.onCompleted: {
                initTimer.start();
            }

            Timer {
                id: initTimer
                interval: 1
                repeat: false
                onTriggered: {
                    notificationsPannel.isInitialized = true;
                }
            }

            Behavior on implicitHeight {
                enabled: isInitialized
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
            }

            ColumnLayout {
                id: notifColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: root.margins
                spacing: 5

                NotificationHeader {
                    id: notifHeader
                }

                Rectangle {
                    id: separator
                    implicitHeight: 1
                    Layout.fillWidth: true
                    color: Appearance.colors.colOnLayer0
                    opacity: 0.3
                }

                NotificationList {
                    id: list
                    headerAndMarginHeight: notifHeader.implicitHeight + root.margins * 2 + separator.implicitHeight + (notifColumn.spacing * 2)
                    maxPanelHeight: root.maxNotificationHeight
                }
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
