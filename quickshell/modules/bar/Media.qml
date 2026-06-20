import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.modules.mediaControls
import qs.modules.common
import qs.modules.common.widgets

MouseArea {
    id: root
    implicitWidth: backgroundRect.implicitWidth
    implicitHeight: 30
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton

    property var activePlayer: null

    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            mediaControls.isOpen = !mediaControls.isOpen;
        }
    }

    function updateActivePlayer() {
        const playingPlayer = Mpris.players.values.find(p => p.playbackState === MprisPlaybackState.Playing);
        if (playingPlayer) {
            root.activePlayer = playingPlayer;
            return;
        }

        // if not player is playing fall back to the first player in the list
        root.activePlayer = Mpris.players.values[0] || null;
    }

    function cleanTitle(title) {
        if (!title)
            return "Unknown Title";

        let cleaned = title.replace(/^\s*\(.+?\)\s*/, '');
        cleaned = cleaned.replace(/^\s*\[.+?\]\s*/, '');

        return cleaned.trim() || title;
    }

    // run once when the component is first created
    Component.onCompleted: updateActivePlayer()

    // run whenever the list of players changes
    Connections {
        target: Mpris.players
        function onObjectInsertedPost() {
            updateActivePlayer();
        }
        function onObjectRemovedPost() {
            updateActivePlayer();
        }
    }

    // create a listener for each player to react to its state changes
    Instantiator {
        model: Mpris.players

        Connections {
            target: modelData
            function onPlaybackStateChanged() {
                updateActivePlayer();
            }
            function onTrackChanged() {
                updateActivePlayer();
            }
        }
    }

    // Timer to update position while playing (Task 2)
    Timer {
        running: root.activePlayer?.playbackState === MprisPlaybackState.Playing
        interval: 1000
        repeat: true
        onTriggered: root.activePlayer?.positionChanged()
    }

    visible: !!activePlayer

    WrapperRectangle {
        id: backgroundRect
        implicitHeight: 30
        color: mediaControls.isOpen ? Appearance.colors.colPrimary : (root.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer1)
        radius: 15

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }

        leftMargin: 10
        rightMargin: 10

        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            // Circular progress with play/pause (Task 3-5)
            MouseArea {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: circularProgress.implicitSize
                implicitHeight: circularProgress.implicitSize
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    mouse.accepted = true;
                    if (root.activePlayer) {
                        root.activePlayer.togglePlaying();
                    }
                }

                ClippedFilledCircularProgress {
                    id: circularProgress
                    anchors.fill: parent
                    implicitSize: 20
                    lineWidth: 2
                    value: root.activePlayer ? (root.activePlayer.position / root.activePlayer.length) : 0
                    colPrimary: mediaControls.isOpen ? Appearance.m3colors.m3onPrimaryFixed : Appearance.colors.colOnLayer0
                    enableAnimation: false  // Disable animation for smooth 1-second updates

                    Item {
                        anchors.centerIn: parent
                        width: circularProgress.implicitSize
                        height: circularProgress.implicitSize

                        MaterialSymbol {
                            anchors.centerIn: parent
                            fill: 1
                            text: root.activePlayer?.isPlaying ? "pause" : "music_note"
                            iconSize: Appearance.font.pixelSize.normal
                            color: mediaControls.isOpen ? Appearance.m3colors.m3onPrimaryFixed : Appearance.colors.colOnLayer0

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                    }
                }
            }

            // track title
            Text {
                id: titleText
                text: activePlayer ? cleanTitle(activePlayer.trackTitle) : ""
                color: mediaControls.isOpen ? Appearance.m3colors.m3onPrimaryFixed : Appearance.colors.colOnLayer0
                font.pixelSize: 12

                elide: Text.ElideRight

                Layout.alignment: Qt.AlignVCenter

                Layout.maximumWidth: 200

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }
            }

            // separator
            Rectangle {
                width: 1
                implicitHeight: parent.height * 0.6
                color: mediaControls.isOpen ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0
                opacity: 0.5
                visible: titleText.text && artistText.text
                Layout.alignment: Qt.AlignVCenter

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }
            }

            // track artist
            Text {
                id: artistText
                text: activePlayer ? (activePlayer.trackArtist || "Unknown Artist") : ""
                color: mediaControls.isOpen ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0
                font.pixelSize: 12

                elide: Text.ElideRight

                Layout.alignment: Qt.AlignVCenter

                Layout.maximumWidth: 100

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }
    }

    // lazy loaded tooltip
    Timer {
        id: tooltipTimer
        interval: 500
        running: root.containsMouse && root.activePlayer
        onTriggered: tooltipLoader.active = true
    }

    Loader {
        id: tooltipLoader
        active: false
        sourceComponent: MediaTooltip {
            activePlayer: root.activePlayer
            anchorItem: root
            cleanTitleFunc: root.cleanTitle
        }
    }

    // reset tooltip when mouse leaves
    onContainsMouseChanged: {
        if (!containsMouse) {
            tooltipTimer.stop();
            tooltipLoader.active = false;
        }
    }

    // media controls popup
    MediaControls {
        id: mediaControls
        anchorItem: root
    }
}
