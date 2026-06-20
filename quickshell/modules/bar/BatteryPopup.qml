import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: root

    property bool isOpen: false
    required property Item anchorItem

    // Helper function to format time in seconds to "Xh, Ym" or "Ym"
    function formatTime(seconds: real): string {
        if (seconds <= 0) return "";
        let totalMinutes = Math.round(seconds / 60);
        let hours = Math.floor(totalMinutes / 60);
        let minutes = totalMinutes % 60;
        if (hours > 0) {
            return hours + "h, " + minutes + "m";
        }
        return minutes + "m";
    }

    Loader {
        id: popupLoader
        active: root.isOpen

        sourceComponent: PopupWindow {
            id: popupPanel
            visible: root.isOpen

            color: "transparent"

            implicitWidth: contentContainer.width
            implicitHeight: contentContainer.height

            anchor {
                window: root.anchorItem.QsWindow?.window
                item: root.anchorItem
                edges: Edges.Bottom
                gravity: Edges.Bottom
                margins.top: 8
            }

            // Main content container
            Rectangle {
                id: contentContainer
                width: contentColumn.implicitWidth + 32
                height: contentColumn.implicitHeight + 24
                color: Appearance.m3colors.m3background
                radius: 12
                border.color: Appearance.m3colors.m3outlineVariant
                border.width: 1

                ColumnLayout {
                    id: contentColumn
                    anchors.centerIn: parent
                    spacing: 10

                    // Time row (conditional)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: {
                            // Hide when fully charged, or time <= 0, or rate <= 0.01
                            if (Battery.chargeState === UPowerDeviceState.FullyCharged) return false;
                            let timeValue = Battery.isCharging ? Battery.timeToFull : Battery.timeToEmpty;
                            if (timeValue <= 0) return false;
                            if (Battery.energyRate <= 0.01) return false;
                            return true;
                        }

                        CustomIcon {
                            width: 18
                            height: 18
                            source: "preferences-system-time-symbolic.svg"
                            colorize: true
                            color: Appearance.colors.colSubtext
                        }

                        Text {
                            text: Battery.isCharging ? "Time to full:" : "Time to empty:"
                            color: Appearance.colors.colSubtext
                            font.pixelSize: 13
                        }

                        Text {
                            text: root.formatTime(Battery.isCharging ? Battery.timeToFull : Battery.timeToEmpty)
                            color: Appearance.colors.colOnLayer0
                            font.pixelSize: 13
                        }
                    }

                    // Power row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: !(Battery.chargeState !== UPowerDeviceState.FullyCharged && Battery.energyRate === 0)

                        MaterialSymbol {
                            iconSize: 18
                            fill: 1
                            text: "bolt"
                            color: Battery.isCharging ? Appearance.colors.colBatteryCharging : Appearance.colors.colSubtext
                        }

                        Text {
                            text: {
                                if (Battery.chargeState === UPowerDeviceState.FullyCharged) {
                                    return "Fully charged";
                                } else if (Battery.isCharging) {
                                    return "Charging: " + Battery.energyRate.toFixed(2) + "W";
                                } else {
                                    return "Discharging: " + Battery.energyRate.toFixed(2) + "W";
                                }
                            }
                            color: Battery.chargeState === UPowerDeviceState.FullyCharged ? Appearance.colors.colBatteryCharging : Appearance.colors.colOnLayer0
                            font.pixelSize: 13
                        }
                    }

                    // Health row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: Battery.health > 0

                        CustomIcon {
                            width: 18
                            height: 18
                            source: "emoji-nature-symbolic.svg"
                            colorize: true
                            color: Appearance.colors.colSubtext
                        }

                        Text {
                            text: "Health:"
                            color: Appearance.colors.colSubtext
                            font.pixelSize: 13
                        }

                        Text {
                            text: Battery.health.toFixed(1) + "%"
                            color: Appearance.colors.colOnLayer0
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }
}
