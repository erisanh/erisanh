import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common.widgets
import qs.modules.common
import qs.services

RowLayout {
    id: header
    spacing: 0

    MaterialSymbol {
        text: "notifications"
        iconSize: 20
        color: Appearance.colors.colOnLayer0
        fill: 1
    }

    Text {
        text: "Notifications"
        color: Appearance.colors.colOnLayer0
        font.pixelSize: 18
        font.bold: true
        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
    }

    Item {
        Layout.fillWidth: true
    }

    MouseArea {
        id: clearButton
        Layout.preferredWidth: content.implicitWidth + 10
        Layout.preferredHeight: content.implicitHeight + 5
        hoverEnabled: true

        onClicked: {
            Notifications.discardAllNotifications();
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: 10

            RowLayout {
                id: content
                anchors.centerIn: parent
                spacing: 4

                CustomIcon {
                    source: "user-trash-full-symbolic"
                    Layout.alignment: Qt.AlignVCenter
                    width: 15
                    height: 15
                    colorize: true
                    color: clearButton.pressed ? "#fa5252" : Appearance.colors.colPowerButton
                }

                Text {
                    text: "Clear"
                    font.bold: true
                    color: clearButton.pressed ? "#fa5252" : Appearance.colors.colPowerButton
                }
            }
        }
    }
}
