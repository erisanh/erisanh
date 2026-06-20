pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: service

    // Expose the current profile from the built-in singleton
    readonly property int profile: PowerProfiles.profile
    readonly property bool hasPerformanceProfile: PowerProfiles.hasPerformanceProfile

    // Cycle through available power profiles
    function cycleProfile(): void {
        switch (PowerProfiles.profile) {
        case PowerProfile.PowerSaver:
            PowerProfiles.profile = PowerProfile.Balanced;
            break;
        case PowerProfile.Balanced:
            if (PowerProfiles.hasPerformanceProfile) {
                PowerProfiles.profile = PowerProfile.Performance;
            } else {
                PowerProfiles.profile = PowerProfile.PowerSaver;
            }
            break;
        case PowerProfile.Performance:
            PowerProfiles.profile = PowerProfile.PowerSaver;
            break;
        }
    }

    // Set a specific profile
    function setProfile(profileName: string): bool {
        switch (profileName.toLowerCase()) {
        case "powersaver":
        case "power-saver":
        case "power_saver":
            PowerProfiles.profile = PowerProfile.PowerSaver;
            return true;
        case "balanced":
            PowerProfiles.profile = PowerProfile.Balanced;
            return true;
        case "performance":
            if (PowerProfiles.hasPerformanceProfile) {
                PowerProfiles.profile = PowerProfile.Performance;
                return true;
            }
            return false;
        default:
            return false;
        }
    }

    // Get the current profile as a string
    function getProfile(): string {
        switch (PowerProfiles.profile) {
        case PowerProfile.PowerSaver:
            return "PowerSaver";
        case PowerProfile.Balanced:
            return "Balanced";
        case PowerProfile.Performance:
            return "Performance";
        default:
            return "Unknown";
        }
    }

    // IPC Handler for external access
    IpcHandler {
        target: "powerProfile"

        function cycle(): void {
            service.cycleProfile();
        }

        function set(profileName: string): bool {
            return service.setProfile(profileName);
        }

        function get(): string {
            return service.getProfile();
        }

        function hasPerformance(): bool {
            return service.hasPerformanceProfile;
        }
    }
}
