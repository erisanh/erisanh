import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.functions

/**
 * ClippedFilledCircularProgress - A filled pie-chart style circular progress indicator
 * Adapted from dots-hyprland for use in media widgets and other progress displays.
 * Uses OpacityMask to cut out centered content (like an icon).
 */
Item {
    id: root

    property int implicitSize: 20
    property int lineWidth: 2
    property real value: 0
    property color colPrimary: Appearance.colors.colOnLayer0
    property color colSecondary: ColorUtils.transparentize(colPrimary, 0.5)
    property bool enableAnimation: false
    property int animationDuration: 800
    property var easingType: Easing.OutCubic
    property bool accountForLightBleeding: true

    // Default content mask - can be overridden with custom content
    default property Item textMask: Item {
        width: implicitSize
        height: implicitSize
    }

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    // Convert value (0-1) to degrees (0-360)
    property real degree: value * 360
    property real centerX: root.width / 2
    property real centerY: root.height / 2
    property real arcRadius: root.implicitSize / 2 - root.lineWidth / 2 - (0.5 * root.accountForLightBleeding)
    property real startAngle: -90  // Start at 12 o'clock position

    Behavior on degree {
        enabled: root.enableAnimation
        NumberAnimation {
            duration: root.animationDuration
            easing.type: root.easingType
        }
    }

    Behavior on colPrimary {
        ColorAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    Rectangle {
        id: contentItem
        anchors.fill: parent
        radius: implicitSize / 2
        color: root.colSecondary
        visible: false
        layer.enabled: true
        layer.smooth: true

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                id: primaryPath
                pathHints: ShapePath.PathSolid & ShapePath.PathNonIntersecting
                strokeColor: root.colPrimary
                strokeWidth: root.lineWidth
                capStyle: ShapePath.RoundCap
                fillColor: root.colPrimary

                startX: root.centerX
                startY: root.centerY

                PathAngleArc {
                    moveToStart: false
                    centerX: root.centerX
                    centerY: root.centerY
                    radiusX: root.arcRadius
                    radiusY: root.arcRadius
                    startAngle: root.startAngle
                    sweepAngle: root.degree
                }

                PathLine {
                    x: primaryPath.startX
                    y: primaryPath.startY
                }
            }
        }
    }

    OpacityMask {
        anchors.fill: parent
        source: contentItem
        invert: true
        maskSource: root.textMask
    }
}
