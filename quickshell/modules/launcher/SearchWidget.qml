import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

/**
 * SearchWidget - Main search container with results list
 */
Item {
    id: root

    readonly property int typingResultLimit: 15
    property string searchingText: LauncherSearch.query
    property bool showResults: searchingText !== "" || LauncherSearch.results.length > 0

    signal close

    implicitWidth: searchWidgetContent.implicitWidth + Appearance.sizes.elevationMargin * 2
    implicitHeight: searchWidgetContent.implicitHeight + searchBar.verticalPadding * 2 + Appearance.sizes.elevationMargin * 2

    function focusFirstItem() {
        appResults.currentIndex = 0;
    }

    function focusSearchInput() {
        searchBar.forceFocus();
    }

    function disableExpandAnimation() {
        searchBar.animateWidth = false;
    }

    function cancelSearch() {
        searchBar.searchInput.selectAll();
        LauncherSearch.query = "";
        searchBar.searchInput.text = "";
        searchBar.animateWidth = true;
    }

    function setSearchingText(text) {
        searchBar.searchInput.text = text;
        LauncherSearch.query = text;
    }

    Keys.onPressed: event => {
        // Prevent Esc from registering here (handled by parent)
        if (event.key === Qt.Key_Escape)
            return;

        // Vim-style navigation: Ctrl+J = down, Ctrl+K = up
        if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_J) {
                // Move down in results
                if (appResults.currentIndex < appResults.count - 1) {
                    appResults.currentIndex++;
                    appResults.currentItem?.forceActiveFocus();
                }
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_K) {
                // Move up in results (or focus search bar if at top)
                if (appResults.currentIndex > 0) {
                    appResults.currentIndex--;
                    appResults.currentItem?.forceActiveFocus();
                } else {
                    searchBar.forceFocus();
                }
                event.accepted = true;
                return;
            }
        }

        // Arrow key navigation (keep for compatibility)
        if (event.key === Qt.Key_Down) {
            if (appResults.currentIndex < appResults.count - 1) {
                appResults.currentIndex++;
                appResults.currentItem?.forceActiveFocus();
            }
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Up) {
            if (appResults.currentIndex > 0) {
                appResults.currentIndex--;
                appResults.currentItem?.forceActiveFocus();
            } else {
                searchBar.forceFocus();
            }
            event.accepted = true;
            return;
        }

        // Handle Backspace: focus and delete character if not focused
        if (event.key === Qt.Key_Backspace) {
            if (!searchBar.searchInput.activeFocus) {
                root.focusSearchInput();
                if (event.modifiers & Qt.ControlModifier) {
                    let text = searchBar.searchInput.text;
                    let pos = searchBar.searchInput.cursorPosition;
                    if (pos > 0) {
                        let left = text.slice(0, pos);
                        let match = left.match(/(\s*\S+)\s*$/);
                        let deleteLen = match ? match[0].length : 1;
                        searchBar.searchInput.text = text.slice(0, pos - deleteLen) + text.slice(pos);
                        searchBar.searchInput.cursorPosition = pos - deleteLen;
                    }
                } else {
                    if (searchBar.searchInput.cursorPosition > 0) {
                        searchBar.searchInput.text = searchBar.searchInput.text.slice(0, searchBar.searchInput.cursorPosition - 1) + searchBar.searchInput.text.slice(searchBar.searchInput.cursorPosition);
                        searchBar.searchInput.cursorPosition -= 1;
                    }
                }
                searchBar.searchInput.cursorPosition = searchBar.searchInput.text.length;
                event.accepted = true;
            }
            return;
        }

        // Type-to-search: focus search bar on printable characters (but not Ctrl+key combos)
        if (event.text && event.text.length === 1 && !(event.modifiers & Qt.ControlModifier) && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Return && event.key !== Qt.Key_Delete && event.text.charCodeAt(0) >= 0x20) {
            if (!searchBar.searchInput.activeFocus) {
                root.focusSearchInput();
                searchBar.searchInput.text = searchBar.searchInput.text.slice(0, searchBar.searchInput.cursorPosition) + event.text + searchBar.searchInput.text.slice(searchBar.searchInput.cursorPosition);
                searchBar.searchInput.cursorPosition += 1;
                event.accepted = true;
                root.focusFirstItem();
            }
        }
    }

    // Shadow effect
    DropShadow {
        anchors.fill: searchWidgetContent
        source: searchWidgetContent
        horizontalOffset: 0
        verticalOffset: 4
        radius: 12
        samples: 25
        color: "#40000000"
    }

    Rectangle {
        id: searchWidgetContent
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: Appearance.sizes.elevationMargin
        }
        clip: true
        implicitWidth: columnLayout.implicitWidth
        implicitHeight: columnLayout.implicitHeight
        radius: searchBar.height / 2 + searchBar.verticalPadding
        color: Appearance.colors.colBackgroundSurfaceContainer

        Behavior on implicitHeight {
            enabled: root.showResults
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        ColumnLayout {
            id: columnLayout
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
            }
            spacing: 0

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: searchWidgetContent.width
                    height: searchWidgetContent.width
                    radius: searchWidgetContent.radius
                }
            }

            SearchBar {
                id: searchBar
                property real verticalPadding: 4
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.topMargin: verticalPadding
                Layout.bottomMargin: verticalPadding
                searchingText: root.searchingText

                searchInput.onAccepted: {
                    if (appResults.count > 0) {
                        let firstItem = appResults.itemAtIndex(0);
                        if (firstItem && firstItem.clicked) {
                            firstItem.clicked();
                        }
                    }
                }
            }

            Rectangle {
                visible: root.showResults
                Layout.fillWidth: true
                height: 1
                color: Appearance.colors.colOutlineVariant
            }

            ListView {
                id: appResults
                visible: root.showResults
                Layout.fillWidth: true
                implicitHeight: Math.min(500, appResults.contentHeight + topMargin + bottomMargin)
                clip: true
                topMargin: 10
                bottomMargin: 10
                spacing: 2
                KeyNavigation.up: searchBar
                highlightMoveDuration: 100
                
                // Enable mouse wheel scrolling and proper interaction
                interactive: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                
                // Handle mouse wheel explicitly for overlay windows
                WheelHandler {
                    onWheel: event => {
                        appResults.flick(0, event.angleDelta.y * 3)
                        event.accepted = true
                    }
                }
                
                // ScrollBar for visual feedback - only visible when scrolling
                ScrollBar.vertical: ScrollBar {
                    id: scrollBar
                    policy: ScrollBar.AsNeeded
                    active: appResults.moving || hovered || pressed
                    minimumSize: 0.1
                    width: 2
                    
                    background: Item {} // Remove the track/line indicator
                    
                    contentItem: Rectangle {
                        implicitWidth: 2
                        implicitHeight: scrollBar.visualSize
                        radius: 9999
                        color: Appearance.colors.colPrimary
                        opacity: scrollBar.active && scrollBar.size < 1.0 ? 0.8 : 0
                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
                    }
                }

                onFocusChanged: {
                    if (focus)
                        appResults.currentIndex = 0;
                }

                Connections {
                    target: root
                    function onSearchingTextChanged() {
                        if (appResults.count > 0)
                            appResults.currentIndex = 0;
                    }
                }

                model: LauncherSearch.results

                delegate: SearchItem {
                    required property var modelData
                    anchors.left: parent?.left
                    anchors.right: parent?.right
                    entry: modelData
                    query: StringUtils.cleanOnePrefix(root.searchingText, [LauncherSearch.prefixClipboard, LauncherSearch.prefixEmojis, LauncherSearch.prefixMath])
                    onClose: root.close()
                }
            }
        }
    }

    // Focus the search input when component is created
    Component.onCompleted: {
        focusSearchInput();
    }
}
