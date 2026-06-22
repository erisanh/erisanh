import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// Sunset/color temperature toggle button in the bar.
// Click cycles: Auto → Warm (3200K) → Cool (6500K) → Auto
WrapperMouseArea {
    id: root

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: HyprSunset.cycle()

    WrapperRectangle {
        id: bg
        implicitHeight: 30
        color: root.containsMouse ? Appearance.colors.colLayer2Hover : "transparent"
        radius: 15
        leftMargin: 6
        rightMargin: 6

        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            CustomIcon {
                source: HyprSunset.icon
                width: 18
                height: 18
                colorize: true
                color: {
                    switch (HyprSunset.mode) {
                    case 1: return "#ffb347"; // warm orange
                    case 2: return "#87ceeb"; // cool blue-white
                    default: return Appearance.colors.colOnLayer0;
                    }
                }

                ToolTip.visible: root.containsMouse
                ToolTip.text: HyprSunset.tooltip
                ToolTip.delay: 500
            }
        }
    }
}
