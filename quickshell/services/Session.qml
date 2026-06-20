pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    // Session screen state
    property bool sessionOpen: false

    function toggleSession() {
        sessionOpen = !sessionOpen;
    }

    function closeSession() {
        sessionOpen = false;
    }

    function lock() {
        sessionOpen = false;
        Quickshell.execDetached(["loginctl", "lock-session"]);
    }

    function suspend() {
        sessionOpen = false;
        Quickshell.execDetached(["bash", "-c", "systemctl suspend || loginctl suspend"]);
    }

    function logout() {
        sessionOpen = false;
        Quickshell.execDetached(["pkill", "-i", "Hyprland"]);
    }

    function hibernate() {
        sessionOpen = false;
        Quickshell.execDetached(["bash", "-c", "systemctl hibernate || loginctl hibernate"]);
    }

    function poweroff() {
        sessionOpen = false;
        Quickshell.execDetached(["bash", "-c", "systemctl poweroff || loginctl poweroff"]);
    }

    function reboot() {
        sessionOpen = false;
        Quickshell.execDetached(["bash", "-c", "reboot || loginctl reboot"]);
    }

    function rebootToFirmware() {
        sessionOpen = false;
        Quickshell.execDetached(["bash", "-c", "systemctl reboot --firmware-setup || loginctl reboot --firmware-setup"]);
    }
}
