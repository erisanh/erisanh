pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * ResourceUsage - Singleton service for system resource monitoring
 * Polls /proc/meminfo and /proc/stat to provide CPU, RAM, and Swap usage.
 * Adapted from dots-hyprland.
 */
Singleton {
    id: root

    // Memory properties (in KB)
    property real memoryTotal: 1
    property real memoryFree: 0
    property real memoryUsed: memoryTotal - memoryFree
    property real memoryUsedPercentage: memoryUsed / memoryTotal

    // Swap properties (in KB)
    property real swapTotal: 1
    property real swapFree: 0
    property real swapUsed: swapTotal - swapFree
    property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0

    // CPU properties
    property real cpuUsage: 0
    property var previousCpuStats: null

    // Formatted strings for display
    property string memoryTotalString: kbToGbString(memoryTotal)
    property string memoryUsedString: kbToGbString(memoryUsed)
    property string swapTotalString: kbToGbString(swapTotal)
    property string swapUsedString: kbToGbString(swapUsed)

    // Configuration
    property int updateInterval: 3000  // ms between updates

    function kbToGbString(kb: real): string {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    Timer {
        id: pollTimer
        interval: 1  // Start immediately, then use configured interval
        running: true
        repeat: true
        onTriggered: {
            // Reload files
            fileMeminfo.reload();
            fileStat.reload();

            // Parse memory and swap usage from /proc/meminfo
            const textMeminfo = fileMeminfo.text();
            root.memoryTotal = Number(textMeminfo.match(/MemTotal: *(\d+)/)?.[1] ?? 1);
            root.memoryFree = Number(textMeminfo.match(/MemAvailable: *(\d+)/)?.[1] ?? 0);
            root.swapTotal = Number(textMeminfo.match(/SwapTotal: *(\d+)/)?.[1] ?? 1);
            root.swapFree = Number(textMeminfo.match(/SwapFree: *(\d+)/)?.[1] ?? 0);

            // Parse CPU usage from /proc/stat
            const textStat = fileStat.text();
            const cpuLine = textStat.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
            if (cpuLine) {
                const stats = cpuLine.slice(1).map(Number);
                const total = stats.reduce((a, b) => a + b, 0);
                const idle = stats[3];

                if (root.previousCpuStats) {
                    const totalDiff = total - root.previousCpuStats.total;
                    const idleDiff = idle - root.previousCpuStats.idle;
                    root.cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0;
                }

                root.previousCpuStats = {
                    total,
                    idle
                };
            }

            // Switch to configured interval after first run
            pollTimer.interval = root.updateInterval;
        }
    }

    FileView {
        id: fileMeminfo
        path: "/proc/meminfo"
    }

    FileView {
        id: fileStat
        path: "/proc/stat"
    }
}
