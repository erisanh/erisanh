import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell
import Quickshell.Services.UPower
import qs.services
import qs.modules.common.widgets
import qs.modules.controlCenter
import qs.modules.common

WrapperMouseArea {
    id: root

    hoverEnabled: true

    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            controlCenter.isOpen = !controlCenter.isOpen;
        }
    }

    WrapperRectangle {
        id: backgroundRect

        readonly property int iconSize: 20
        readonly property string iconColor: controlCenter.isOpen ? Appearance.m3colors.m3onPrimaryFixed : Appearance.colors.colOnLayer0

        implicitHeight: 30
        color: controlCenter.isOpen ? Appearance.colors.colPrimary : (root.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer1)
        radius: 15

        leftMargin: 10
        rightMargin: 10

        RowLayout {
            spacing: 8
            anchors.verticalCenter: parent.verticalCenter

            CustomIcon {
                source: Audio.symbol
                width: backgroundRect.iconSize
                height: backgroundRect.iconSize
                colorize: true
                color: backgroundRect.iconColor
            }

            CustomIcon {
                source: Network.symbol
                width: backgroundRect.iconSize
                height: backgroundRect.iconSize
                colorize: true
                color: backgroundRect.iconColor
            }

            CustomIcon {
                source: BluetoothStatus.connected ? "bluetooth-active-symbolic" : BluetoothStatus.enabled ? "bluetooth-disconnected-symbolic" : "bluetooth-disabled-symbolic"
                width: backgroundRect.iconSize
                height: backgroundRect.iconSize
                colorize: true
                color: backgroundRect.iconColor
            }

            CustomIcon {
                source: {
                    switch (PowerProfiles.profile) {
                    case PowerProfile.PowerSaver:
                        return "power-profile-power-saver-symbolic";
                    case PowerProfile.Balanced:
                        return "power-profile-balanced-symbolic";
                    case PowerProfile.Performance:
                        return "power-profile-performance-symbolic";
                    default:
                        return "power-profile-balanced-symbolic";
                    }
                }
                width: backgroundRect.iconSize
                height: backgroundRect.iconSize
                colorize: true
                color: backgroundRect.iconColor
            }

            CustomIcon {
                source: Audio.source?.audio?.muted ? 'microphone-disabled-symbolic' : 'audio-input-microphone-symbolic'
                width: backgroundRect.iconSize
                height: backgroundRect.iconSize
                colorize: true
                color: backgroundRect.iconColor
            }

            Loader {
                active: GamingModeService.isActive
                visible: active
                Layout.preferredWidth: active ? backgroundRect.iconSize : 0
                Layout.preferredHeight: active ? backgroundRect.iconSize : 0
                Layout.maximumWidth: active ? backgroundRect.iconSize : 0
                Layout.maximumHeight: active ? backgroundRect.iconSize : 0

                sourceComponent: CustomIcon {
                    source: "game-mode"
                    width: backgroundRect.iconSize
                    height: backgroundRect.iconSize
                    colorize: true
                    color: backgroundRect.iconColor
                }
            }

            Loader {
                active: Idle.inhibit
                visible: active
                Layout.preferredWidth: active ? backgroundRect.iconSize : 0
                Layout.preferredHeight: active ? backgroundRect.iconSize : 0
                Layout.maximumWidth: active ? backgroundRect.iconSize : 0
                Layout.maximumHeight: active ? backgroundRect.iconSize : 0

                sourceComponent: CustomIcon {
                    source: "coffee-awake"
                    width: backgroundRect.iconSize
                    height: backgroundRect.iconSize
                    colorize: true
                    color: backgroundRect.iconColor
                }
            }

            Loader {
                active: Notifications.silent
                visible: active
                Layout.preferredWidth: active ? backgroundRect.iconSize : 0
                Layout.preferredHeight: active ? backgroundRect.iconSize : 0
                Layout.maximumWidth: active ? backgroundRect.iconSize : 0
                Layout.maximumHeight: active ? backgroundRect.iconSize : 0

                sourceComponent: CustomIcon {
                    source: "notifications-disabled-symbolic"
                    width: backgroundRect.iconSize
                    height: backgroundRect.iconSize
                    colorize: true
                    color: backgroundRect.iconColor
                }
            }
        }
    }

    ControlCenter {
        id: controlCenter
    }
}
