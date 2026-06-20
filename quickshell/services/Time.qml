pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string hoursMinutes: Qt.formatDateTime(clock.date, "hh:mm")
    readonly property string dayOfWeek: Qt.formatDateTime(clock.date, "ddd")
    readonly property string dateMonth: Qt.formatDateTime(clock.date, "dd/MM")
    readonly property var date: clock.date
    readonly property string uptime: uptimeText

    property string uptimeText: "0h 0m"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    function updateUptime() {
        uptimeFetcher.running = true;
    }

    function formatUptime(seconds) {
        const totalMinutes = Math.floor(seconds / 60);
        const days = Math.floor(totalMinutes / (60 * 24));
        const hours = Math.floor((totalMinutes % (60 * 24)) / 60);
        const minutes = totalMinutes % 60;

        if (days > 0) {
            return days + "d " + hours + "h";
        }
        return hours + "h " + minutes + "m";
    }

    Process {
        id: uptimeFetcher
        command: ["cat", "/proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parts = text.trim().split(" ");
                    const uptimeSeconds = parseFloat(parts[0]);
                    root.uptimeText = root.formatUptime(uptimeSeconds);
                } catch (e) {
                    root.uptimeText = "N/A";
                }
            }
        }
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.updateUptime()
    }
}
