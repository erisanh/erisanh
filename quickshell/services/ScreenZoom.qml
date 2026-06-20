pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root
    property real screenZoom: 1

    onScreenZoomChanged: {
        Quickshell.execDetached(["hyprctl", "keyword", "cursor:zoom_factor", root.screenZoom.toString()]);
    }

    Behavior on screenZoom {
        NumberAnimation {
            duration: 200
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.34, 0.80, 0.34, 1.00, 1, 1]
        }
    }

    IpcHandler {
        target: "zoom"

        function zoomIn() {
            screenZoom = Math.min(screenZoom + 0.4, 3.0);
        }

        function zoomOut() {
            screenZoom = Math.max(screenZoom - 0.4, 1);
        }
    }
}
