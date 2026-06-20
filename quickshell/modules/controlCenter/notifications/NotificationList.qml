import QtQuick
import Quickshell
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common

ListView {
    id: notifList
    Layout.fillWidth: true

    implicitHeight: Math.min(contentHeight, maxPanelHeight - headerAndMarginHeight)

    // set explicit height to respect the allocated space from parent
    height: implicitHeight

    clip: true
    spacing: 6

    model: ScriptModel {
        values: Notifications.listArray
    }

    property real headerAndMarginHeight: 0
    property real maxPanelHeight: 400

    maximumFlickVelocity: 3500
    boundsBehavior: Flickable.DragOverBounds
    flickableDirection: Flickable.VerticalFlick

    // Handle mouse wheel explicitly for overlay windows
    WheelHandler {
        onWheel: event => {
            notifList.flick(0, event.angleDelta.y * 3)
            event.accepted = true
        }
    }

    // ScrollBar for visual feedback - only visible when scrolling
    ScrollBar.vertical: ScrollBar {
        id: scrollBar
        policy: ScrollBar.AsNeeded
        active: notifList.moving || hovered || pressed
        minimumSize: 0.1
        width: 2
        
        background: Item {} // Remove the track/line indicator
        
        contentItem: Rectangle {
            implicitWidth: 2
            implicitHeight: scrollBar.visualSize
            radius: 9999
            color: Appearance.colors.colPrimary
            opacity: scrollBar.active && scrollBar.size < 1.0 ? 0.8 : 0
            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
        }
    }

    delegate: NotificationItem {
        width: notifList.width
        notif: modelData
    }

    interactive: true
}
