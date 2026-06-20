import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.modules.common

PopupWindow {
    id: root

    required property SystemTrayItem item
    required property Item anchorItem

    visible: true

    color: "transparent"

    implicitWidth: tooltipRect.width
    implicitHeight: tooltipRect.height

    anchor {
        window: anchorItem.QsWindow?.window
        item: anchorItem
        edges: Edges.Bottom
        gravity: Edges.Bottom
        margins.top: 8
    }

    Rectangle {
        id: tooltipRect
        width: tooltipText.implicitWidth + 16
        height: tooltipText.implicitHeight + 8

        color: Appearance.m3colors.m3background
        radius: 8
        border.color: Appearance.m3colors.m3outlineVariant
        border.width: 1

        Text {
            id: tooltipText
            anchors.centerIn: parent

            text: {
                let result = item.tooltipTitle || item.title || item.id;
                if (item.tooltipdescription && item.tooltipdescription.length > 0) {
                    result + "\n" + item.tooltipdescription;
                }
                return result;
            }

            color: "white"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
