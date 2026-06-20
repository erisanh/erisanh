import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick

QuickToggleButton {
    id: root

    contentItem: Item {
        implicitWidth: 24
        implicitHeight: 24

        CustomIcon {
            id: microphoneIcon
            source: "game-mode"

            anchors.centerIn: parent
            width: 24
            height: 24
            colorize: true
            color: root.toggled ? Appearance.m3colors.m3background : Appearance.colors.colOnLayer0

            Behavior on color {
                ColorAnimation {
                    duration: 200
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.34, 0.80, 0.34, 1.00, 1, 1]
                }
            }
        }
    }

    // Bind to the singleton's state - this keeps all instances in sync!
    toggled: GamingModeService.isActive

    onClicked: GamingModeService.toggle()
}
