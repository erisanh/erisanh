import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.modules.bar
import qs.modules.common

MouseArea {
    id: root
    implicitWidth: backgroundRect.implicitWidth
    implicitHeight: 30
    hoverEnabled: true

    WrapperRectangle {
        id: backgroundRect
        implicitHeight: 30
        color: root.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer1
        radius: 15

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }

        leftMargin: 8
        rightMargin: 8

        RowLayout {
            id: trayIconsLayout
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Repeater {
                model: SystemTray.items

                delegate: SysTrayItem {}
            }
        }
    }
}
