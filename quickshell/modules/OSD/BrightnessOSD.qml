import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services

BaseOSD {
    id: brightnessOsd

    WlrLayershell.namespace: "quickshell:osd:brightness"

    sliderIcon: "display-brightness-symbolic"
    sliderFrom: 0.0
    sliderTo: 1.0

    property var focusedMonitor: {
        const focusedName = Hyprland.focusedMonitor?.name;
        const focusedScreen = Quickshell.screens.find(s => s.name === focusedName);
        return Brightness.getMonitorForScreen(focusedScreen);
    }

    sliderValue: focusedMonitor?.brightness ?? 0.0

    onSliderMoved: value => {
        if (focusedMonitor) {
            focusedMonitor.setBrightness(value);
        }
    }

    Connections {
        target: Brightness
        function onBrightnessChanged() {
            brightnessOsd.show();
        }
    }
}
