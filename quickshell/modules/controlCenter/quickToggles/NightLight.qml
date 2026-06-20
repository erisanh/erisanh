import qs.modules.common
import qs.modules.common.widgets
import Quickshell
import Quickshell.Io

QuickToggleButton {
    id: root
    buttonIcon: "night_sight_auto"
    toggled: toggled

    onClicked: {
        root.toggled = !root.toggled;
    }
}
