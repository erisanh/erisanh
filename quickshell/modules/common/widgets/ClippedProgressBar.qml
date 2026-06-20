import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property bool vertical: false
    property real valueBarWidth: 28
    property real valueBarHeight: 16
    property color highlightColor: "#FFFFFF"
    property color trackColor: "#F1D3F9"
    property real radius: 5
    property string text
    property real value: 0
    property bool showNob: false
    property bool nobFilled: false
    property real gap: 1 // gap between bar and nob
    property real nobWidth: 2

    property font font: Qt.font({
        pixelSize: 15,
        weight: Font.DemiBold
    })

    default property Item textMask: Item {
        width: valueBarWidth
        height: valueBarHeight
        Text {
            anchors.centerIn: parent
            text: root.text
            color: "white"
            font: root.font
        }
    }

    implicitWidth: valueBarWidth + (showNob ? 5 : 0)
    implicitHeight: valueBarHeight

    // battery body
    Item {
        id: batteryBody
        width: valueBarWidth
        height: valueBarHeight

        Rectangle {
            id: contentItem
            anchors.fill: parent
            radius: root.radius
            color: root.trackColor
            visible: false

            Rectangle {
                id: progressFill
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                }
                width: parent.width * root.value
                height: parent.height
                color: root.highlightColor
                radius: 0
            }
        }

        // first mask: clip fill into rounded body
        OpacityMask {
            id: roundingMask
            anchors.fill: parent
            source: contentItem
            maskSource: Rectangle {
                width: contentItem.width
                height: contentItem.height
                radius: root.radius
            }
            visible: false
        }

        // second mask: text cut-out overlay
        OpacityMask {
            anchors.fill: parent
            source: roundingMask
            invert: true
            maskSource: root.textMask
        }
    }

    // nob
    Rectangle {
        id: batteryNob
        visible: showNob
        anchors {
            left: batteryBody.right
            leftMargin: root.gap
            verticalCenter: batteryBody.verticalCenter
        }
        width: root.nobWidth
        height: batteryBody.height * 0.5
        radius: 1
        color: nobFilled ? root.highlightColor : root.trackColor
    }
}
