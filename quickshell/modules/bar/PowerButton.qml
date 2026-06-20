import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Power button component - opens session screen on click
MouseArea {
    id: root

    implicitWidth: 30
    implicitHeight: 30
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: {
        Session.toggleSession();
    }

    Rectangle {
        anchors.fill: parent
        radius: 15
        color: root.containsMouse ? Appearance.colors.colLayer2Hover : "transparent"

        CustomIcon {
            anchors.centerIn: parent
            width: 20
            height: 20
            source: "system-shutdown-symbolic.svg"
            colorize: true
            color: Appearance.colors.colPowerButton
        }
    }
}
