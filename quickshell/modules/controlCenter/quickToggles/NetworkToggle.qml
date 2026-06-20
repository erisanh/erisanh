import qs.modules.common
import qs.modules.common.widgets
import Quickshell
import Quickshell.Io
import qs.services

BigToggleButton {
    id: root

    signal openWifiPanel

    icon: Network.symbol
    toggled: Network.wifiStatus !== "disabled"
    title: toggled ? (Network.wifiStatus === "connected" ? "Connected" : (Network.wifiStatus === "connecting" ? "Connecting..." : "Disconnected")) : "Disable"

    subtitle: {
        if (!toggled)
            return "Disable";
        if (Network.wifiStatus === "disconnected")
            return "No connected device";
        if (Network.connectivity === "full")
            return Network.networkName;
        if (Network.connectivity === "limited")
            return Network.networkName + " (No internet)";
        if (Network.connectivity === "portal")
            return Network.networkName + " (Captive portal)";
        return Network.networkName;
    }

    onLeftClicked: {
        Network.toggleWifi();
    }

    onRightClicked: {
        root.openWifiPanel();
    }
}
