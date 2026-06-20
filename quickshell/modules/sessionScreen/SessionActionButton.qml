import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: button

    property string buttonIcon  // MaterialSymbol icon name
    property string buttonIconSource: ""  // CustomIcon SVG source (if set, uses CustomIcon instead)
    property string buttonText
    property bool keyboardDown: false
    property real size: 100

    buttonRadius: (button.focus || button.down) ? size / 2 : 20
    colBackground: button.keyboardDown ? Appearance.colors.colSecondaryContainerActive :
        button.focus ? Appearance.colors.colPrimary :
        Appearance.colors.colLayer2
    colBackgroundHover: Appearance.colors.colPrimary
    colRipple: Appearance.colors.colPrimaryActive
    property color colText: (button.down || button.keyboardDown || button.focus || button.hovered) ?
        Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0

    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    background.implicitHeight: size
    background.implicitWidth: size

    Behavior on buttonRadius {
        NumberAnimation {
            duration: 100
            easing.type: Easing.OutQuad
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            keyboardDown = true;
            button.clicked();
            event.accepted = true;
        }
    }

    Keys.onReleased: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            keyboardDown = false;
            event.accepted = true;
        }
    }

    contentItem: Item {
        anchors.fill: parent

        // Use CustomIcon if buttonIconSource is set, otherwise MaterialSymbol
        Loader {
            anchors.centerIn: parent
            active: button.buttonIconSource !== ""
            sourceComponent: CustomIcon {
                width: 40
                height: 40
                source: button.buttonIconSource
                colorize: true
                color: button.colText
            }
        }

        Loader {
            anchors.centerIn: parent
            active: button.buttonIconSource === ""
            sourceComponent: MaterialSymbol {
                color: button.colText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                iconSize: 40
                text: button.buttonIcon
            }
        }
    }

    // Tooltip on hover (positioned above to avoid sibling overlap)
    Rectangle {
        id: tooltip
        visible: button.hovered && !button.focus
        z: 100
        anchors.bottom: parent.top
        anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        width: tooltipText.implicitWidth + 16
        height: tooltipText.implicitHeight + 8
        color: Appearance.colors.colTooltip
        radius: 6

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: buttonText
            color: Appearance.colors.colOnTooltip
            font.pixelSize: 12
        }
    }
}
