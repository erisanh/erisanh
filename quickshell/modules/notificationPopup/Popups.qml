import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.modules.common

PanelWindow {
    id: root
    visible: Notifications.popupList.length > 0
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

    WlrLayershell.namespace: "quickshell-notification-popups"
    WlrLayershell.layer: WlrLayer.Overlay // popups should appear above everything
    exclusiveZone: 0 // popups should not reserve screen space

    // anchor the window as a strip on the top-right of the screen
    anchors {
        top: true
        right: true
    }

    color: "transparent"

    implicitWidth: 400
    implicitHeight: popupListView.contentHeight + 26 // 13px margin top/bottom

    // makes the PanelWindow itself click-through, except
    // for the areas where the actual popups are.
    mask: Region {
        item: popupListView // .contentItem
    }

    ListView {
        id: popupListView
        anchors.fill: parent
        anchors.margins: 13
        spacing: 10

        implicitHeight: contentHeight

        model: Notifications.popupList
        interactive: false // we don't want to scroll it

        delegate: NotificationPopup {
            required property var modelData
            notif: modelData
            width: popupListView.width
        }

        // add smooth transitions for popups appearing and disappearing
        add: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1.0
                duration: 250
            }
            NumberAnimation {
                property: "scale"
                from: 0.9
                to: 1.0
                duration: 250
            }
        }
        remove: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1.0
                to: 0
                duration: 250
            }
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.9
                duration: 250
            }
        }
    }
}
