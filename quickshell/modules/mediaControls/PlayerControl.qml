import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: playerController
    required property MprisPlayer player

    property var artUrl: player?.trackArtUrl
    property string artDownloadLocation: Directories.coverArt
    // Use MD5 hash as base filename - extension determined after download based on actual file content
    property string artFileBase: Qt.md5(artUrl || "")
    property string artFilePath: ""  // Set dynamically after download when extension is known
    property color artDominantColor: ColorUtils.mix((colorQuantizer?.colors[0] ?? basePrimary), baseSecondaryContainer, 0.8) || baseSecondaryContainer
    property bool downloaded: false
    property real radius: 12
    property real contentPadding
    property real artRounding
    property int progressBarHeight: 24

    property color basePrimary: Appearance.m3colors.m3primary
    property color baseSecondaryContainer: Appearance.m3colors.m3secondaryContainer

    component TrackChangeButton: RippleButton {
        implicitWidth: 32
        implicitHeight: 32
        buttonRadius: 16

        required property var iconName
        colBackground: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 1)
        colBackgroundHover: blendedColors.colSecondaryContainerHover
        colRipple: blendedColors.colSecondaryContainerActive

        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            iconSize: 24
            fill: 1
            color: blendedColors.colOnSecondaryContainer
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: iconName

            Behavior on color {
                ColorAnimation {
                    duration: 200
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.34, 0.80, 0.34, 1.00, 1, 1]
                }
            }
        }
    }

    // timer to debounce art url changes and solve the property binding race condition
    // this ensures that when we create the download command, all dependent properties
    // like artFilePath have been updated to their new values
    Timer {
        id: artUrlDebouncer
        interval: 200 // delay to prevent duplicate downloads during rapid track changes
        repeat: false
        onTriggered: {
            const rawUrl = playerController.artUrl;
            if (rawUrl.length === 0) {
                playerController.artDominantColor = "#3d3d3d";
                return;
            }

            // console.log("PlayerControl: Debounced art URL is", rawUrl);
            // Download to temp file, detect MIME type, convert WebP to JPEG if needed
            const baseFile = `${artDownloadLocation}/${artFileBase}`;
            const commandString = `
                # Check if file with any valid extension already exists
                for ext in jpg jpeg png gif; do
                    [ -f '${baseFile}'."$ext" ] && echo '${baseFile}'."$ext" && exit 0
                done
                # Download to temp file
                tmpfile='${baseFile}.tmp'
                curl -sSLf --max-time 10 -A "Mozilla/5.0" --create-dirs '${rawUrl}' -o "$tmpfile" || { rm -f "$tmpfile"; exit 1; }
                # Detect MIME type from file content
                mime=$(file -b --mime-type "$tmpfile" 2>/dev/null)
                case "$mime" in
                    image/webp)
                        # Convert WebP to JPEG since Quickshell doesn't support WebP
                        if command -v magick >/dev/null 2>&1; then
                            magick "$tmpfile" '${baseFile}.jpg' && rm -f "$tmpfile"
                            echo '${baseFile}.jpg'
                        else
                            # Fallback: rename as jpg and hope for the best
                            mv "$tmpfile" '${baseFile}.jpg'
                            echo '${baseFile}.jpg'
                        fi
                        ;;
                    image/png)
                        mv "$tmpfile" '${baseFile}.png'
                        echo '${baseFile}.png'
                        ;;
                    image/gif)
                        mv "$tmpfile" '${baseFile}.gif'
                        echo '${baseFile}.gif'
                        ;;
                    *)
                        mv "$tmpfile" '${baseFile}.jpg'
                        echo '${baseFile}.jpg'
                        ;;
                esac
            `;

            coverArtDownloader.command = ["bash", "-c", commandString];
            // console.log("Download cmd:", commandString);

            coverArtDownloader.running = true;
        }
    }

    // download album art when URL changes
    onArtUrlChanged: {
        // console.log("PlayerControl: Art URL signal received. New URL:", playerController.artUrl);

        // immediately reset the downloaded state and file path
        // this will clear the old album art from the ui and prevent "Cannot open" errors
        playerController.downloaded = false;
        playerController.artFilePath = "";

        // restart the timer
        artUrlDebouncer.restart();
    }

    Process {
        id: coverArtDownloader

        stdout: SplitParser {
            onRead: data => {
                const path = data.trim();
                if (path.length > 0) {
                    playerController.artFilePath = path;
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            // Only set downloaded to true if the process succeeded and we have a valid path
            if (exitCode === 0 && playerController.artFilePath.length > 0) {
                playerController.downloaded = true;
            } else {
                console.warn("PlayerControl: Art download failed with exit code", exitCode);
            }
        }
    }

    // extract dominant color from album art
    ColorQuantizer {
        id: colorQuantizer
        source: playerController.downloaded ? Qt.resolvedUrl(artFilePath) : ""
        depth: 0 // Single dominant color
        rescaleSize: 1
    }

    // create adapted color scheme
    AdaptedMaterialScheme {
        id: blendedColors
        sourceColor: artDominantColor
    }

    // update position timer
    Timer {
        running: playerController.player?.playbackState == MprisPlaybackState.Playing
        interval: 1000
        repeat: true
        onTriggered: playerController.player.positionChanged()
    }

    // format seconds to time string
    function formatTime(seconds) {
        if (!seconds || isNaN(seconds))
            return "0:00";
        let minutes = Math.floor(seconds / 60);
        let secs = Math.floor(seconds % 60);
        return `${minutes}:${secs.toString().padStart(2, '0')}`;
    }

    // clean title (remove prefixes in brackets/parentheses)
    function cleanTitle(title) {
        if (!title)
            return "Unknown Title";
        let cleaned = title.replace(/^\s*\(.+?\)\s*/, '');
        cleaned = cleaned.replace(/^\s*\[.+?\]\s*/, '');
        return cleaned.trim() || title;
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: blendedColors.colLayer0
        radius: playerController.radius

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: background.width
                height: background.height
                radius: background.radius
            }
        }

        // blurred album art background
        Image {
            id: blurredArt
            anchors.fill: parent
            source: playerController.downloaded ? Qt.resolvedUrl(artFilePath) : ""
            sourceSize.width: background.width
            sourceSize.height: background.height
            fillMode: Image.PreserveAspectCrop
            cache: true
            antialiasing: true
            asynchronous: true

            layer.enabled: true
            layer.effect: MultiEffect {
                source: blurredArt
                blurEnabled: true
                blur: 0.5
                blurMax: 100
                saturation: 0.2
            }

            Rectangle {
                anchors.fill: parent
                color: ColorUtils.transparentize(blendedColors.colLayer0, 0.3)
                radius: playerController.radius
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: playerController.contentPadding
            spacing: 15

            // album art
            Rectangle {
                id: artBackground
                Layout.fillHeight: true
                implicitWidth: height
                radius: playerController.artRounding
                clip: true
                color: "transparent"

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: artBackground.width
                        height: artBackground.height
                        radius: artBackground.radius
                    }
                }

                StyledImage {
                    id: mediaArt
                    anchors.fill: parent
                    property int size: parent.height
                    source: playerController.downloaded ? Qt.resolvedUrl(artFilePath) : ""
                    fillMode: Image.PreserveAspectCrop
                    cache: true
                    antialiasing: true

                    width: size
                    height: size
                    sourceSize.width: size
                    sourceSize.height: size
                }
            }

            // info & controls
            ColumnLayout {
                Layout.fillHeight: true
                spacing: 2

                // track title
                Text {
                    id: trackTitle
                    Layout.fillWidth: true
                    font.pixelSize: 16
                    font.weight: Font.Medium
                    color: blendedColors.colOnLayer0
                    elide: Text.ElideRight
                    text: cleanTitle(playerController.player?.trackTitle) || "Untitled"
                }

                // track artist
                Text {
                    id: trackArtist
                    Layout.fillWidth: true
                    font.pixelSize: 13
                    color: blendedColors.colSubtext
                    elide: Text.ElideRight
                    text: playerController.player?.trackArtist || "Unknown Artist"
                }

                Item {
                    Layout.fillHeight: true
                }

                // controls section
                Item {
                    Layout.fillWidth: true
                    implicitHeight: trackTime.implicitHeight + sliderRow.implicitHeight

                    // time display
                    Text {
                        id: trackTime
                        anchors.bottom: sliderRow.top
                        anchors.bottomMargin: 5
                        anchors.left: parent.left
                        font.pixelSize: 13
                        color: blendedColors.colSubtext
                        text: `${formatTime(playerController.player?.position)} / ${formatTime(playerController.player?.length)}`
                        elide: Text.ElideRight
                    }

                    // play/pause button
                    RippleButton {
                        id: playPauseButton
                        anchors.right: parent.right
                        anchors.bottom: sliderRow.top
                        anchors.bottomMargin: 5
                        property real size: 44
                        implicitWidth: size
                        implicitHeight: size
                        downAction: () => playerController.player.togglePlaying()

                        buttonRadius: playerController.player?.isPlaying ? 16 : size / 2
                        colBackground: playerController.player?.isPlaying ? blendedColors.colPrimary : blendedColors.colSecondaryContainer
                        colBackgroundHover: playerController.player?.isPlaying ? blendedColors.colPrimaryHover : blendedColors.colSecondaryContainerHover
                        colRipple: playerController.player?.isPlaying ? blendedColors.colPrimaryActive : blendedColors.colSecondaryContainerActive

                        contentItem: MaterialSymbol {
                            iconSize: 28
                            fill: 1
                            color: playerController.player?.isPlaying ? blendedColors.colOnPrimary : blendedColors.colOnSecondaryContainer
                            text: playerController.player?.isPlaying ? "pause" : "play_arrow"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: [0.34, 0.80, 0.34, 1.00, 1, 1]
                                }
                            }
                        }
                    }

                    // slider row with prev/next buttons
                    RowLayout {
                        id: sliderRow
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                        }
                        // spacing: 2

                        TrackChangeButton {
                            iconName: "skip_previous"
                            onClicked: playerController.player?.previous()
                        }

                        // progress slider or bar
                        Item {
                            id: progressBarContainer
                            Layout.fillWidth: true
                            implicitHeight: {
                                const baseHeight = Math.max(sliderLoader.implicitHeight, progressBarLoader.implicitHeight);
                                if (sliderLoader.active && playerController.player?.isPlaying) {
                                    return baseHeight * 4;
                                }
                                return baseHeight;
                            }

                            Loader {
                                id: sliderLoader
                                anchors.fill: parent
                                active: playerController.player?.canSeek ?? false
                                sourceComponent: StyledSlider {
                                    showTooltip: false
                                    configuration: StyledSlider.Configuration.Wavy
                                    highlightColor: blendedColors.colPrimary
                                    trackColor: blendedColors.colSecondaryContainer
                                    handleColor: blendedColors.colPrimary
                                    dotColor: blendedColors.colOnSecondaryContainer
                                    dotColorHighlighted: blendedColors.colOnPrimary
                                    wavy: playerController.player?.isPlaying ?? false
                                    value: playerController.player?.position / playerController.player?.length
                                    onMoved: {
                                        playerController.player.position = value * playerController.player.length;
                                    }
                                }
                            }

                            Loader {
                                id: progressBarLoader
                                anchors {
                                    verticalCenter: parent.verticalCenter
                                    left: parent.left
                                    right: parent.right
                                }
                                active: !(playerController.player?.canSeek ?? false)
                                sourceComponent: StyledProgressBar {
                                    implicitHeight: valueBarHeight
                                    wavy: playerController.player?.isPlaying// ?? false
                                    highlightColor: blendedColors.colPrimary
                                    trackColor: blendedColors.colSecondaryContainer
                                    value: playerController.player?.position / playerController.player?.length
                                }
                            }
                        }

                        TrackChangeButton {
                            iconName: "skip_next"
                            onClicked: playerController.player?.next()
                        }
                    }
                }
            }
        }
    }
}
