import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import qs.modules.common.widgets

Scope {
    id: root

    property bool isOpen: false
    property Item anchorItem: null
    property real popupWidth: 440
    property real popupHeight: 160
    property real contentPadding: 13
    property real popupRounding: 12
    property real artRounding: 8

    readonly property var filteredPlayers: Mpris.players.values.filter(player => isRealPlayer(player))

    function isRealPlayer(player) {
        return (
            // filter out native browser buses as plasma-integration is installed
            !player.dbusName.startsWith('org.mpris.MediaPlayer2.firefox') && !player.dbusName.startsWith('org.mpris.MediaPlayer2.chromium') &&
            // filter out playerctld duplicates
            !player.dbusName?.startsWith('org.mpris.MediaPlayer2.playerctld') &&
            // filter out non-instance mpd bus
            !(player.dbusName?.endsWith('.mpd') && !player.dbusName.endsWith('MediaPlayer2.mpd')));
    }

    Loader {
        id: mediaControlsLoader
        active: root.isOpen

        sourceComponent: PopupWindow {
            id: popup
            visible: true
            color: "transparent"

            implicitWidth: root.popupWidth
            implicitHeight: playerColumn.implicitHeight

            anchor {
                window: root.anchorItem?.QsWindow?.window
                item: root.anchorItem
                edges: Edges.Bottom
                gravity: Edges.Bottom
                margins.top: 40
            }

            mask: Region {
                item: playerColumn
            }

            // close popup when clicking outside
            HyprlandFocusGrab {
                windows: [popup]
                active: mediaControlsLoader.active
                onCleared: () => {
                    if (!active) {
                        root.isOpen = false;
                    }
                }
            }

            ColumnLayout {
                id: playerColumn
                anchors.fill: parent
                spacing: 10

                Repeater {
                    model: ScriptModel {
                        values: root.filteredPlayers
                    }

                    delegate: PlayerControl {
                        required property MprisPlayer modelData
                        player: modelData
                        implicitWidth: root.popupWidth
                        implicitHeight: root.popupHeight
                        radius: root.popupRounding
                        contentPadding: root.contentPadding
                        artRounding: root.artRounding
                    }
                }

                // no players placeholder
                Rectangle {
                    visible: root.filteredPlayers.length === 0
                    Layout.fillWidth: true
                    implicitHeight: 100
                    color: "#2d2d2d"
                    radius: 12

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "No active player"
                            color: "#ffffff"
                            font.pixelSize: 16
                            font.weight: Font.Medium
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "Start playing media to see controls"
                            color: "#aaaaaa"
                            font.pixelSize: 12
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }
    }
}
