pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property bool enabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property BluetoothDevice firstActiveDevice: Bluetooth.defaultAdapter?.devices.values.find(device => device.connected) ?? null
    readonly property int activeDeviceCount: Bluetooth.defaultAdapter?.devices.values.filter(device => device.connected).length ?? 0
    readonly property bool connected: Bluetooth.devices.values.some(d => d.connected)

    readonly property bool isTransitioning: {
        const adapter = Bluetooth.defaultAdapter;
        if (!adapter)
            return false;

        // check if adapter is transitioning
        if (adapter.state === BluetoothAdapterState.Enabling || adapter.state === BluetoothAdapterState.Disabling) {
            return true;
        }

        // check if any device is transitioning
        return adapter.devices.values.some(device => device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting);
    }

    readonly property string symbol: {
        const adapter = Bluetooth.defaultAdapter;

        // if no adapter exists, show disabled
        if (!adapter) {
            return "bluetooth-disabled-symbolic";
        }

        // check adapter state first
        if (adapter.state === BluetoothAdapterState.Disabled || adapter.state === BluetoothAdapterState.Blocked) {
            return "bluetooth-disabled-symbolic";
        }

        // If adapter is transitioning, show acquiring
        if (adapter.state === BluetoothAdapterState.Enabling || adapter.state === BluetoothAdapterState.Disabling) {
            return "bluetooth-acquiring-symbolic";
        }

        // adapter is enabled, check device states
        const devices = adapter.devices.values;

        // check if any device is connecting or disconnecting (most active state)
        const hasTransitioningDevice = devices.some(device => device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting);

        if (hasTransitioningDevice) {
            return "bluetooth-acquiring-symbolic";
        }

        // check if any device is connected
        const hasConnectedDevice = devices.some(device => device.state === BluetoothDeviceState.Connected);

        if (hasConnectedDevice) {
            return "bluetooth-active-symbolic";
        }

        // adapter is enabled but no devices connected
        return "bluetooth-disconnected-symbolic";
    }
}
