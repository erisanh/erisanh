//@ pragma UseQApplication
import Quickshell
import qs.modules.bar
import qs.modules.launcher
import qs.modules.notificationPopup
import qs.modules.OSD
import qs.modules.sessionScreen
import qs.services

ShellRoot {
    property var brightness: Brightness
    property var gameMode: GamingModeService
    property var screenZoom: ScreenZoom
    property var powerProfile: PowerProfileService
    property var session: Session

    // Initialize launcher services
    property var _appSearch: AppSearch
    property var _cliphist: Cliphist
    property var _emojis: Emojis
    property var _launcherSearch: LauncherSearch

    property bool enableNotificationPopup: true
    property bool enableOSD: true

    Bar {}

    Launcher {}

    SessionScreen {}

    LazyLoader {
        active: enableNotificationPopup
        Popups {}
    }

    LazyLoader {
        active: enableOSD
        OSD {}
    }
}
