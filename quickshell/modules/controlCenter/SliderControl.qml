import QtQuick
import QtQuick.Layouts
import qs.modules.common.widgets
import qs.modules.common

Item {
    id: root
    Layout.fillWidth: true
    implicitHeight: slider.implicitHeight

    // public API for this component
    property alias icon: slider.insetIconSource
    property alias value: slider.value
    property alias from: slider.from
    property alias to: slider.to

    signal moved(real value)

    StyledSlider {
        id: slider
        anchors.fill: parent
        configuration: StyledSlider.Configuration.M

        highlightColor: Appearance.colors.colPrimary
        trackColor: Appearance.colors.colLayer3
        handleColor: Appearance.colors.colPrimary
        dotColor: Appearance.colors.colLayer3
        dotColorHighlighted: Appearance.colors.colLayer3
        handleMargins: 6

        // inset icon setup for M+ sizes
        insetIconColorActive: Appearance.m3colors.m3onPrimaryFixed
        insetIconColorInactive: Appearance.colors.colOnLayer0
        enableInsetIcon: true

        // when the slider value change, emit the moved signal
        // only fires when user drag it
        onValueChanged: {
            if (pressed) {
                root.moved(value);
            }
        }
    }
}
