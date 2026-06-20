pragma Singleton

// import qs
import Quickshell
import Quickshell.Services.UPower
import QtQuick
import Quickshell.Io

Singleton {
    property bool available: UPower.displayDevice.isLaptopBattery
    property var chargeState: UPower.displayDevice.state
    property bool isCharging: chargeState == UPowerDeviceState.Charging
    property bool isPluggedIn: isCharging || chargeState == UPowerDeviceState.PendingCharge
    property real percentage: UPower.displayDevice?.percentage ?? 1
    readonly property bool allowAutomaticSuspend: true

    property bool isLow: available && (percentage <= 0.5)
    property bool isCritical: available && (percentage <= 0.2)
    property bool isSuspending: available && (percentage <= 0.1)

    property bool isLowAndNotCharging: isLow && !isCharging
    property bool isCriticalAndNotCharging: isCritical && !isCharging
    property bool isSuspendingAndNotCharging: allowAutomaticSuspend && isSuspending && !isCharging

    property real energyRate: UPower.displayDevice.changeRate
    property real timeToEmpty: UPower.displayDevice.timeToEmpty
    property real timeToFull: UPower.displayDevice.timeToFull

    // Battery health from UPower devices (returns 0 if not supported)
    property real health: {
        for (let i = 0; i < UPower.devices.values.length; i++) {
            let device = UPower.devices.values[i];
            if (device.isLaptopBattery && device.healthSupported) {
                let hp = device.healthPercentage;
                // Normalize: if < 1, it's a fraction (0-1); multiply by 100
                // If 0, return small value to indicate unknown but supported
                if (hp <= 0) return 0;
                return hp < 1 ? hp * 100 : hp;
            }
        }
        return 0; // No health-supported battery found
    }

    onIsLowAndNotChargingChanged: {
        if (available && isLowAndNotCharging)
            Quickshell.execDetached(["notify-send", "Low battery", "Consider plugging in your device", "-u", "critical", "-a", "Shell"]);
    }

    onIsCriticalAndNotChargingChanged: {
        if (available && isCriticalAndNotCharging)
            Quickshell.execDetached(["notify-send", "Critical low battery", "Plug in your device immediately.\nAutomatic suspend at 10%", "-u", "critical", "-a", "Shell"]);
    }

    onIsSuspendingAndNotChargingChanged: {
        if (available && isSuspendingAndNotCharging) {
            Quickshell.execDetached(["bash", "-c", `systemctl suspend || loginctl suspend`]);
        }
    }
}
