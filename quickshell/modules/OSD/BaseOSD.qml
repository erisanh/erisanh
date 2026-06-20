import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.modules.common.widgets
import qs.modules.common

PanelWindow {
    id: baseOsd

    property bool userInteracting: false
    property alias sliderValue: slider.value
    property alias sliderFrom: slider.from
    property alias sliderTo: slider.to
    property alias sliderIcon: slider.insetIconSource

    signal sliderMoved(real value)

    implicitWidth: 400
    implicitHeight: 150

    color: "transparent"
    aboveWindows: true

    WlrLayershell.layer: WlrLayer.Overlay

    exclusiveZone: 0

    anchors {
        bottom: true
    }

    // margins {
    //     bottom: 5
    // }

    Timer {
        id: hideTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (!baseOsd.userInteracting) {
                baseOsd.visible = false;
            }
        }
    }

    function show() {
        baseOsd.visible = true;
        hideTimer.restart();
    }

    mask: Region {
        item: background
    }

    Item {
        anchors.fill: parent

        Rectangle {
            id: background
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.margins: 15
            width: 260
            height: slider.handleHeight + slider.anchors.margins
            radius: 21
            color: Appearance.m3colors.m3background

            StyledSlider {
                id: slider
                anchors.fill: parent
                anchors.margins: 6

                configuration: StyledSlider.Configuration.XL

                highlightColor: Appearance.colors.colPrimary
                trackColor: Appearance.colors.colLayer3
                handleColor: Appearance.colors.colPrimary
                dotColor: Appearance.colors.colPrimary
                dotColorHighlighted: Appearance.colors.colPrimary
                handleMargins: 6

                insetIconColorActive: Appearance.m3colors.m3onPrimaryFixed
                insetIconColorInactive: Appearance.colors.colOnLayer0
                insetIconPadding: 10
                enableInsetIcon: true

                from: 0.0
                to: 1.0

                onPressedChanged: {
                    baseOsd.userInteracting = pressed;
                    if (pressed) {
                        hideTimer.stop();
                    } else {
                        hideTimer.restart();
                    }
                }

                onValueChanged: {
                    if (pressed) {
                        baseOsd.sliderMoved(value);
                    }
                }
            }
        }
    }
}
