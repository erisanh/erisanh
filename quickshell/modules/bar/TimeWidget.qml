import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.modules.common

WrapperMouseArea {
    id: root

    Layout.alignment: Qt.AlignVCenter
    hoverEnabled: true

    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            dateTimePopup.isOpen = !dateTimePopup.isOpen;
        }
    }

    WrapperRectangle {
        implicitHeight: 30
        color: dateTimePopup.isOpen ? Appearance.colors.colPrimary : (root.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer1)
        radius: 15

        leftMargin: 10
        rightMargin: 10

        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Text {
                text: Time.hoursMinutes
                color: dateTimePopup.isOpen ? Appearance.m3colors.m3onPrimaryFixed : Appearance.colors.colOnLayer0
                font.pixelSize: 12
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                width: 1
                color: dateTimePopup.isOpen ? Appearance.m3colors.m3onPrimaryFixed : Appearance.colors.colOnLayer0
                opacity: 0.5

                implicitHeight: parent.height * 0.6
                Layout.alignment: Qt.AlignVCenter
            }

            RowLayout {
                spacing: 5
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: Time.dayOfWeek
                    color: dateTimePopup.isOpen ? Appearance.m3colors.m3onPrimaryFixed : Appearance.colors.colOnLayer0
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: Time.dateMonth
                    color: dateTimePopup.isOpen ? Appearance.m3colors.m3onPrimaryFixed : Appearance.colors.colOnLayer0
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }

    DateTimePopup {
        id: dateTimePopup
    }
}
