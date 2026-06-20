import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell.Services.UPower
import QtQuick

QuickToggleButton {
    id: root

    property string currentProfile: {
        switch (PowerProfileService.profile) {
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

    contentItem: Item {
        implicitWidth: 24
        implicitHeight: 24

        CustomIcon {
            id: cloudflareIcon
            source: root.currentProfile

            anchors.centerIn: parent
            width: 24
            height: 24
            colorize: true
            color: Appearance.m3colors.m3background

            Behavior on color {
                ColorAnimation {
                    duration: 200
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.34, 0.80, 0.34, 1.00, 1, 1]
                }
            }
        }
    }

    toggled: true

    onClicked: PowerProfileService.cycleProfile()
}
