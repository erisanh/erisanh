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

    // Auto-discover when panel is shown so BlueZ can resolve device names.
    // Names are fetched lazily by BlueZ only during an active scan — without
    // this, nearby devices appear as raw MAC addresses.
    Component.onCompleted: {
        const adapter = Bluetooth.defaultAdapter;
        if (adapter && adapter.enabled && !adapter.discovering)
            adapter.discovering = true;
    }
    Component.onDestruction: {
        const adapter = Bluetooth.defaultAdapter;
        if (adapter && adapter.discovering)
            adapter.discovering = false;
    }

    color: Appearance.m3colors.m3background
    radius: 20
    border.width: 1
    border.color: Appearance.m3colors.m3outlineVariant

    implicitHeight: 600

    ColumnLayout {
        id: bluetoothPanelLayout
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10

        // Header
        Text {
            text: "Bluetooth devices"
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
            visible: !(Bluetooth.defaultAdapter?.discovering ?? false)
            Layout.leftMargin: -bluetoothPanelLayout.anchors.margins
            Layout.rightMargin: -bluetoothPanelLayout.anchors.margins
        }

        ProgressBar {
            indeterminate: true
            Material.accent: Appearance.m3colors.m3primary
            visible: Bluetooth.defaultAdapter?.discovering ?? false
            Layout.fillWidth: true
            Layout.topMargin: -8
            Layout.bottomMargin: -8
            Layout.leftMargin: -bluetoothPanelLayout.anchors.margins
            Layout.rightMargin: -bluetoothPanelLayout.anchors.margins
        }

        ListView {
            Layout.fillHeight: true
            Layout.fillWidth: true

            Layout.leftMargin: -bluetoothPanelLayout.anchors.margins + 1 // for the border
            Layout.rightMargin: -bluetoothPanelLayout.anchors.margins + 1

            clip: true
            spacing: 0

            model: ScriptModel {
                id: deviceModel

                readonly property var macRegex: /^([0-9A-Fa-f]{2}[:\-]){5}[0-9A-Fa-f]{2}$/

                values: [...Bluetooth.devices.values]
                    .filter(d => {
                        // Always show paired/connected devices regardless of name
                        if (d.paired || d.connected) return true;
                        // Hide devices whose "name" is just a raw MAC address —
                        // BlueZ uses the MAC as a placeholder until it resolves
                        // the real name via a device info request. These unnamed
                        // entries clutter the list without being actionable.
                        return !deviceModel.macRegex.test(d.name);
                    })
                    .sort((a, b) => {
                        // Connected first, then paired, then others
                        const conn = (b.connected - a.connected) || (b.paired - a.paired);
                        if (conn !== 0)
                            return conn;
                        // Alphabetical by name
                        return a.name.localeCompare(b.name);
                    })
            }
            delegate: BluetoothDeviceItem {
                required property BluetoothDevice modelData
                device: modelData
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
            Layout.leftMargin: -bluetoothPanelLayout.anchors.margins
            Layout.rightMargin: -bluetoothPanelLayout.anchors.margins
        }

        RowLayout {
            spacing: 4

            RippleButton {
                id: scanButton
                implicitHeight: 36
                implicitWidth: 80
                padding: 14
                buttonRadius: 9999
                colBackground: Appearance.m3colors.m3background

                contentItem: Text {
                    anchors.fill: parent
                    anchors.leftMargin: scanButton.padding
                    anchors.rightMargin: scanButton.padding
                    text: (Bluetooth.defaultAdapter?.discovering ?? false) ? "Scanning…" : "Scan"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 12
                    font.bold: true
                    color: scanButton.enabled ? Appearance.colors.colOnLayer0 : Appearance.m3colors.m3background
                }

                onClicked: {
                    const adapter = Bluetooth.defaultAdapter;
                    if (!adapter || !adapter.enabled) return;
                    adapter.discovering = !adapter.discovering;
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
