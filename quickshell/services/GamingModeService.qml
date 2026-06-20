pragma Singleton
import Quickshell
import Quickshell.Io

Singleton {
    id: service

    property bool isActive: false

    function toggle(): void {
        service.isActive = !service.isActive;

        if (service.isActive) {
            Quickshell.execDetached(["bash", "-c", `hyprctl --batch "keyword animations:enabled 0; keyword decoration:shadow:enabled 0; keyword decoration:blur:enabled 0; keyword general:gaps_in 0; keyword general:gaps_out 0; keyword general:border_size 1; keyword decoration:rounding 0; keyword general:allow_tearing 1"`]);
        } else {
            Quickshell.execDetached(["hyprctl", "reload"]);
        }
    }

    Process {
        id: fetchActiveState
        running: true
        command: ["bash", "-c", `test "$(hyprctl getoption decoration:blur:enabled | awk 'NR==1{print$2}')" -ne 0`]
        onExited: (exitCode, exitStatus) => {
            service.isActive = exitCode !== 0;
        }
    }

    IpcHandler {
        target: "gamingMode"

        function toggle(): void {
            service.toggle();
        }

        function getState(): bool {
            return service.isActive;
        }
    }
}
