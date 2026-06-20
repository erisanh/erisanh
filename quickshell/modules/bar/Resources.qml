import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

/**
 * Resources - Bar widget showing CPU, RAM, and Swap usage as circular progress indicators
 */
Item {
    id: root

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: 30

    // Warning thresholds (percentage 0-100)
    property int cpuWarningThreshold: 90
    property int memoryWarningThreshold: 90
    property int swapWarningThreshold: 80

    RowLayout {
        id: rowLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        // RAM
        ResourceCircle {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            warning: percentage * 100 >= root.memoryWarningThreshold
        }

        // Swap (only show if swap exists)
        ResourceCircle {
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            warning: percentage * 100 >= root.swapWarningThreshold
            visible: ResourceUsage.swapTotal > 1  // Hide if no swap configured
        }

        // CPU
        ResourceCircle {
            iconName: "speed"  // or "developer_board" or "memory_alt"
            percentage: ResourceUsage.cpuUsage
            warning: percentage * 100 >= root.cpuWarningThreshold
        }
    }

    // Resource circle component
    component ResourceCircle: Item {
        id: resourceItem
        required property string iconName
        required property real percentage
        property bool warning: false

        implicitWidth: circularProgress.implicitSize
        implicitHeight: circularProgress.implicitSize
        Layout.alignment: Qt.AlignVCenter

        ClippedFilledCircularProgress {
            id: circularProgress
            anchors.fill: parent
            implicitSize: 22
            lineWidth: 2
            value: resourceItem.percentage
            colPrimary: resourceItem.warning ? Appearance.colors.colError : Appearance.colors.colOnLayer0
            enableAnimation: false

            Item {
                anchors.centerIn: parent
                width: circularProgress.implicitSize
                height: circularProgress.implicitSize

                MaterialSymbol {
                    anchors.centerIn: parent
                    fill: 1
                    text: resourceItem.iconName
                    iconSize: Appearance.font.pixelSize.large
                    color: resourceItem.warning ? Appearance.colors.colError : Appearance.m3colors.m3onSecondaryContainer

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }
    }
}
