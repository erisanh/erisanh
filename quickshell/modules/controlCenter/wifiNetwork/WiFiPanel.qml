import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell
import Quickshell.Bluetooth

Rectangle {
    id: root

    signal closePanel

    color: Appearance.m3colors.m3background
    radius: 20
    border.width: 1
    border.color: Appearance.m3colors.m3outlineVariant

    implicitHeight: 600

    ColumnLayout {
        id: wifiPanelLayout
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10

        // Header
        Text {
            text: "Connect to Wi-Fi"
            color: Appearance.colors.colOnLayer0
            font.pixelSize: 18
            font.bold: true
            Layout.fillWidth: true
        }

        Rectangle {
            implicitHeight: 1
            Layout.fillWidth: true
            color: Appearance.colors.colOnLayer0
            opacity: 0.3
            visible: !Network.wifiScanning
            Layout.leftMargin: -wifiPanelLayout.anchors.margins
            Layout.rightMargin: -wifiPanelLayout.anchors.margins
        }

        ProgressBar {
            indeterminate: true
            Material.accent: Appearance.m3colors.m3primary
            visible: Network.wifiScanning
            Layout.fillWidth: true
            Layout.topMargin: -8
            Layout.bottomMargin: -8
            Layout.leftMargin: -wifiPanelLayout.anchors.margins
            Layout.rightMargin: -wifiPanelLayout.anchors.margins
        }

        ListView {
            Layout.fillHeight: true
            Layout.fillWidth: true

            Layout.leftMargin: -wifiPanelLayout.anchors.margins + 1 // for the border
            Layout.rightMargin: -wifiPanelLayout.anchors.margins + 1

            clip: true
            spacing: 0

            model: ScriptModel {
                values: [...Network.wifiNetworks].sort((a, b) => {
                    if (a.active && !b.active)
                        return -1;
                    if (!a.active && b.active)
                        return 1;
                    return b.strength - a.strength;
                })
            }
            delegate: WiFiNetworkItem {
                required property WifiAccessPoint modelData
                wifiNetwork: modelData
                anchors {
                    left: parent?.left
                    right: parent?.right
                }
            }
        }

        Rectangle {
            implicitHeight: 1
            Layout.fillWidth: true
            color: Appearance.colors.colOnLayer0
            opacity: 0.3
            Layout.leftMargin: -wifiPanelLayout.anchors.margins
            Layout.rightMargin: -wifiPanelLayout.anchors.margins
        }

        RowLayout {
            spacing: 4

            RippleButton {
                id: detailButton
                implicitHeight: 36
                implicitWidth: 80
                padding: 14
                buttonRadius: 9999
                colBackground: Appearance.m3colors.m3background

                contentItem: Text {
                    anchors.fill: parent
                    anchors.leftMargin: detailButton.padding
                    anchors.rightMargin: detailButton.padding
                    text: "Details"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 12
                    font.bold: true
                    color: detailButton.enabled ? Appearance.colors.colOnLayer0 : Appearance.m3colors.m3background
                }
            }

            Item {
                Layout.fillWidth: true
            }

            RippleButton {
                id: doneButton
                implicitHeight: 36
                implicitWidth: 80
                padding: 14
                buttonRadius: 9999
                colBackground: Appearance.m3colors.m3background

                contentItem: Text {
                    anchors.fill: parent
                    anchors.leftMargin: doneButton.padding
                    anchors.rightMargin: doneButton.padding
                    text: "Done"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 12
                    font.bold: true
                    color: doneButton.enabled ? Appearance.colors.colOnLayer0 : Appearance.m3colors.m3background
                }

                onClicked: root.closePanel()
            }
        }
    }
}
