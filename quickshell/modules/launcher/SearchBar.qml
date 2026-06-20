import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

/**
 * SearchBar - Search input with dynamic prefix icon
 */
RowLayout {
    id: root
    spacing: 6

    property bool animateWidth: false
    property alias searchInput: searchInput
    property string searchingText

    function forceFocus() {
        searchInput.forceActiveFocus();
    }

    enum SearchPrefixType {
        Clipboard,
        Emojis,
        Math,
        DefaultSearch
    }

    property var searchPrefixType: {
        if (root.searchingText.startsWith(LauncherSearch.prefixClipboard))
            return SearchBar.SearchPrefixType.Clipboard;
        if (root.searchingText.startsWith(LauncherSearch.prefixEmojis))
            return SearchBar.SearchPrefixType.Emojis;
        if (root.searchingText.startsWith(LauncherSearch.prefixMath))
            return SearchBar.SearchPrefixType.Math;
        return SearchBar.SearchPrefixType.DefaultSearch;
    }

    // Search prefix icon: CustomIcon for DefaultSearch, Clipboard, Emojis; MaterialSymbol for Math
    Loader {
        id: searchIconLoader
        Layout.alignment: Qt.AlignVCenter
        active: true
        sourceComponent: root.searchPrefixType === SearchBar.SearchPrefixType.Math ? mathIconComponent : customIconComponent
    }

    Component {
        id: customIconComponent
        CustomIcon {
            source: switch (root.searchPrefixType) {
            case SearchBar.SearchPrefixType.Clipboard:
                return "edit-paste-symbolic.svg";
            case SearchBar.SearchPrefixType.Emojis:
                return "face-cool-symbolic.svg";
            case SearchBar.SearchPrefixType.DefaultSearch:
            default:
                return "system-search-symbolic.svg";
            }
            width: Appearance.font.pixelSize.huge
            height: Appearance.font.pixelSize.huge
            colorize: true
            color: Appearance.m3colors.m3onSurface
        }
    }

    Component {
        id: mathIconComponent
        MaterialSymbol {
            iconSize: Appearance.font.pixelSize.huge
            color: Appearance.m3colors.m3onSurface
            text: "calculate"
        }
    }

    // Borderless text field
    TextField {
        id: searchInput
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        Layout.fillWidth: true
        implicitHeight: 40
        font.pixelSize: Appearance.font.pixelSize.small
        font.family: Appearance.font.family.main
        placeholderText: "Search apps, = calc, ; clipboard, : emoji"
        placeholderTextColor: Appearance.colors.colSubtext
        color: Appearance.m3colors.m3onSurface
        implicitWidth: Appearance.sizes.searchWidth

        background: Rectangle {
            color: "transparent"
        }

        Behavior on implicitWidth {
            enabled: root.animateWidth
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuad
            }
        }

        onTextChanged: LauncherSearch.query = text

        onAccepted: {
            // Signal that user pressed Enter - handled by parent
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            hoverEnabled: true
            cursorShape: Qt.IBeamCursor
        }
    }
}
