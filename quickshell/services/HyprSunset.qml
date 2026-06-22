pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// HyprSunset — manual color temperature toggle
// Cycles: auto (hyprsunset manages) → warm (4000K) → cool (6500K, daylight)
// Calls `hyprsunset -t <temp>` or kills hyprsunset to restore auto mode.
Singleton {
    id: root

    // 0 = auto (hyprsunset daemon running), 1 = warm, 2 = cool/white
    property int mode: 0

    readonly property var modes: [
        { label: "Auto",  temp: -1,    icon: "night-light-symbolic",         tooltip: "Color temp: auto (schedule)" },
        { label: "Warm",  temp: 3200,  icon: "night-light-symbolic",         tooltip: "Color temp: warm (3200K)" },
        { label: "Cool",  temp: 6500,  icon: "night-light-disabled-symbolic", tooltip: "Color temp: cool white (6500K)" },
    ]

    readonly property string icon:    modes[mode].icon
    readonly property string tooltip: modes[mode].tooltip

    function cycle() {
        mode = (mode + 1) % modes.length;
        apply();
    }

    function apply() {
        const m = modes[mode];
        if (m.temp === -1) {
            // Restore auto: kill any manual override, restart hyprsunset daemon
            killer.command = ["bash", "-c", "pkill -x hyprsunset; sleep 0.3; hyprsunset &"];
        } else {
            // Manual override: kill daemon, apply fixed temperature
            killer.command = ["bash", "-c",
                `pkill -x hyprsunset; sleep 0.1; hyprsunset -t ${m.temp} &`];
        }
        killer.running = true;
    }

    Process {
        id: killer
        command: []
    }

    IpcHandler {
        target: "sunset"

        function cycle(): void {
            root.cycle();
        }

        function setWarm(): void {
            root.mode = 1;
            root.apply();
        }

        function setCool(): void {
            root.mode = 2;
            root.apply();
        }

        function setAuto(): void {
            root.mode = 0;
            root.apply();
        }
    }
}
