import QtQuick
import qs.modules.common

Text {
    id: root
    property real iconSize: 24
    property real fill: 0
    property real truncatedFill: Math.round(fill * 100) / 100 // reduce memory consumption spikes from constant font remapping

    renderType: Text.NativeRendering
    antialiasing: true

    font {
        family: "Material Symbols Rounded"
        pixelSize: iconSize
        hintingPreference: Font.PreferFullHinting
        variableAxes: {
            "FILL": truncatedFill,
            "opsz": iconSize
        }
    }

    color: Appearance.colors.colOnLayer0
}
