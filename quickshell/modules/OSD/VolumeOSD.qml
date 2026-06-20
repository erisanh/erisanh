import QtQuick
import qs.services
import Quickshell.Wayland

BaseOSD {
    id: volumeOsd

    WlrLayershell.namespace: "quickshell:osd:volume"

    sliderIcon: Audio.symbol
    sliderFrom: 0.0
    sliderTo: 1.0
    sliderValue: Audio.ready ? Audio.sink.audio.volume : 0.0

    onSliderMoved: value => {
        if (Audio.ready) {
            Audio.sink.audio.volume = value;
        }
    }

    Connections {
        target: Audio.sink?.audio ?? null
        function onVolumeChanged() {
            if (Audio.ready) {
                volumeOsd.show();
            }
        }
    }

    Connections {
        target: Audio.sink?.audio ?? null
        function onMutedChanged() {
            if (Audio.ready) {
                volumeOsd.show();
            }
        }
    }
}
