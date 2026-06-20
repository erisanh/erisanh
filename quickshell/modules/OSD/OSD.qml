import QtQuick
import Quickshell

Scope {
    id: root

    property var activeOsd: null

    VolumeOSD {
        id: volumeOsd
        visible: false

        onVisibleChanged: {
            if (visible && root.activeOsd !== volumeOsd) {
                if (root.activeOsd) {
                    root.activeOsd.visible = false;
                }
                root.activeOsd = volumeOsd;
            }
        }
    }

    BrightnessOSD {
        id: brightnessOsd
        visible: false

        onVisibleChanged: {
            if (visible && root.activeOsd !== brightnessOsd) {
                if (root.activeOsd) {
                    root.activeOsd.visible = false;
                }
                root.activeOsd = brightnessOsd;
            }
        }
    }
}
