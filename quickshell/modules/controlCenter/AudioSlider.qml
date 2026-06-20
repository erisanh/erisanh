import qs.services
import QtQuick

SliderControl {
    id: root
    icon: Audio.symbol

    from: 0.0
    to: 1.0
    value: Audio.ready ? Audio.sink.audio.volume : 0.0

    onMoved: value => {
        if (Audio.ready) {
            Audio.sink.audio.volume = value;
        }
    }
}
