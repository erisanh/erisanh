pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common.widgets

Slider {
    id: root

    property list<real> stopIndicatorValues: [1]
    enum Configuration {
        Wavy = 4,
        XS = 12,
        S = 18,
        M = 30,
        L = 42,
        XL = 62
    }

    property var configuration: StyledSlider.Configuration.S

    property real handleDefaultWidth: 3
    property real handlePressedWidth: 1.5
    property color highlightColor: "#685496"
    property color trackColor: "#F1D3F9"
    property color handleColor: "#685496"
    property color dotColor: "#4A4A4A"
    property color dotColorHighlighted: "#FFFFFF"
    property real unsharpenRadius: 2
    property real trackWidth: configuration
    property real trackRadius: trackWidth >= StyledSlider.Configuration.XL ? 16 : trackWidth >= StyledSlider.Configuration.L ? 12 : trackWidth >= StyledSlider.Configuration.M ? 9 : trackWidth >= StyledSlider.Configuration.S ? 6 : height / 2
    property real handleHeight: (configuration === StyledSlider.Configuration.Wavy) ? 24 : Math.max(33, trackWidth + 9)
    property real handleWidth: root.pressed ? handlePressedWidth : handleDefaultWidth
    property real handleMargins: 4
    property real trackDotSize: 4
    property string tooltipContent: `${Math.round(value * 100)}%`
    property bool showTooltip: true
    property bool wavy: configuration === StyledSlider.Configuration.Wavy
    property bool animateWave: true
    property real waveAmplitudeMultiplier: wavy ? 0.5 : 0
    property real waveFrequency: 6
    property real waveFps: 60

    // Inset icon API
    property string insetIconSource: ""
    // default single-color for backward compat; override Active/Inactive to customize
    property color insetIconColor: handleColor
    property color insetIconColorActive: insetIconColor
    property color insetIconColorInactive: insetIconColor
    property real insetIconSize: Math.min(24, trackWidth - 12)
    property bool enableInsetIcon: true
    property real insetIconPadding: 6
    readonly property bool insetIconVisible: enableInsetIcon && insetIconSource !== "" && configuration >= StyledSlider.Configuration.M

    leftPadding: handleMargins
    rightPadding: handleMargins
    property real effectiveDraggingWidth: width - leftPadding - rightPadding

    Layout.fillWidth: true
    from: 0
    to: 1

    Behavior on value {
        SmoothedAnimation {
            velocity: 2
        }
    }

    Behavior on handleMargins {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutQuad
        }
    }

    component TrackDot: Rectangle {
        required property real value
        anchors.verticalCenter: parent.verticalCenter
        x: root.handleMargins + (value * root.effectiveDraggingWidth) - (root.trackDotSize / 2)
        width: root.trackDotSize
        height: root.trackDotSize
        radius: width / 2
        color: value > root.visualPosition ? root.dotColor : root.dotColorHighlighted

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.OutQuad
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: mouse => mouse.accepted = false
        cursorShape: root.pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
    }

    background: Item {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        implicitHeight: trackWidth

        // Fill left
        Loader {
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
            }
            width: root.handleMargins + (root.visualPosition * root.effectiveDraggingWidth) - (root.handleWidth / 2 + root.handleMargins)
            height: root.trackWidth
            active: !root.wavy
            sourceComponent: Rectangle {
                color: root.highlightColor
                topLeftRadius: root.trackRadius
                bottomLeftRadius: root.trackRadius
                topRightRadius: root.unsharpenRadius
                bottomRightRadius: root.unsharpenRadius
            }
        }

        Loader {
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
            }
            width: root.handleMargins + (root.visualPosition * root.effectiveDraggingWidth) - (root.handleWidth / 2 + root.handleMargins)
            height: root.height
            active: root.wavy
            sourceComponent: WavyLine {
                id: wavyFill
                frequency: root.waveFrequency
                fullLength: root.width
                color: root.highlightColor
                amplitudeMultiplier: root.wavy ? 0.5 : 0
                width: root.handleMargins + (root.visualPosition * root.effectiveDraggingWidth) - (root.handleWidth / 2 + root.handleMargins)
                height: root.trackWidth * 6
                Connections {
                    target: root
                    function onValueChanged() {
                        wavyFill.requestPaint();
                    }
                    function onHighlightColorChanged() {
                        wavyFill.requestPaint();
                    }
                }
                FrameAnimation {
                    running: root.animateWave
                    onTriggered: {
                        wavyFill.requestPaint();
                    }
                }
            }
        }

        // Fill right
        Rectangle {
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
            }
            width: root.handleMargins + ((1 - root.visualPosition) * root.effectiveDraggingWidth) - (root.handleWidth / 2 + root.handleMargins)
            height: trackWidth
            color: root.trackColor
            topRightRadius: root.trackRadius
            bottomRightRadius: root.trackRadius
            topLeftRadius: root.unsharpenRadius
            bottomLeftRadius: root.unsharpenRadius
        }

        // Inset icon inside the track
        Loader {
            id: insetIconLoader
            anchors.fill: parent
            active: root.insetIconVisible

            sourceComponent: Item {
                id: insetIconContainer
                anchors.fill: parent

                readonly property real leftWidth: root.handleMargins + (root.visualPosition * root.effectiveDraggingWidth) - (root.handleWidth / 2 + root.handleMargins)
                readonly property real rightWidth: root.handleMargins + ((1 - root.visualPosition) * root.effectiveDraggingWidth) - (root.handleWidth / 2 + root.handleMargins)
                readonly property real requiredWidth: root.insetIconSize + 2 * root.insetIconPadding
                readonly property bool placeOnLeft: leftWidth >= requiredWidth || rightWidth < requiredWidth
                visible: leftWidth >= requiredWidth || rightWidth >= requiredWidth

                CustomIcon {
                    id: insetIcon
                    width: root.insetIconSize
                    height: width
                    colorize: true
                    color: insetIconContainer.placeOnLeft ? root.insetIconColorActive : root.insetIconColorInactive
                    source: root.insetIconSource
                    anchors.verticalCenter: parent.verticalCenter
                    // Place at the start of the respective segment
                    x: insetIconContainer.placeOnLeft ? (root.insetIconPadding) : ((parent.width - insetIconContainer.rightWidth) + root.insetIconPadding)
                }
            }
        }

        // Stop indicators
        Repeater {
            model: root.stopIndicatorValues
            TrackDot {
                required property real modelData
                value: modelData
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    handle: Rectangle {
        id: handle

        implicitWidth: root.handleWidth
        implicitHeight: root.handleHeight
        x: root.handleMargins + (root.visualPosition * root.effectiveDraggingWidth) - (root.handleWidth / 2)
        anchors.verticalCenter: parent.verticalCenter
        radius: width / 2
        color: root.handleColor

        // property bool hovered: handleMouseArea.containsMouse

        MouseArea {
            id: handleMouseArea
            anchors.fill: parent
            anchors.margins: -10
            hoverEnabled: true
            onPressed: mouse => mouse.accepted = false
        }

        ToolTip {
            id: tooltip
            visible: root.showTooltip && root.pressed //&& handle.hovered
            text: root.tooltipContent
            delay: 0
            timeout: -1
            y: -tooltip.height - 5
            x: -tooltip.width / 2 + handle.width / 2
        }

        Behavior on implicitWidth {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuad
            }
        }
    }
}
