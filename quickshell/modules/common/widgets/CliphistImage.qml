import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import Qt5Compat.GraphicalEffects
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * CliphistImage - Displays a clipboard image entry from cliphist
 * Decodes the image to a temp file and displays it with optional blur
 */
Rectangle {
    id: root
    
    property string entry
    property real maxWidth: 200
    property real maxHeight: 140
    property bool blur: false
    property string blurText: "Image hidden"

    property string imageDecodePath: Directories.cliphistDecode
    property string imageDecodeFileName: `${entryNumber}`
    property string imageDecodeFilePath: `${imageDecodePath}/${imageDecodeFileName}`
    property string source: ""

    // Extract entry number from cliphist format: "123\t[[binary data...]]"
    property int entryNumber: {
        if (!root.entry)
            return 0;
        const match = root.entry.match(/^(\d+)\t/);
        return match ? parseInt(match[1]) : 0;
    }
    
    // Extract image dimensions from entry: "...WxH pixel...]"
    property int imageWidth: {
        if (!root.entry)
            return 0;
        const match = root.entry.match(/(\d+)x(\d+)/);
        return match ? parseInt(match[1]) : 0;
    }
    property int imageHeight: {
        if (!root.entry)
            return 0;
        const match = root.entry.match(/(\d+)x(\d+)/);
        return match ? parseInt(match[2]) : 0;
    }
    
    // Calculate scale to fit within max dimensions
    property real scale: {
        if (imageWidth === 0 || imageHeight === 0)
            return 1;
        return Math.min(root.maxWidth / imageWidth, root.maxHeight / imageHeight, 1);
    }

    color: Appearance.colors.colLayer1
    radius: Appearance.rounding.small
    implicitHeight: imageHeight > 0 ? imageHeight * scale : 60
    implicitWidth: imageWidth > 0 ? imageWidth * scale : 100

    Component.onCompleted: {
        if (root.entry && Cliphist.entryIsImage(root.entry)) {
            decodeImageProcess.running = true;
        }
    }

    Process {
        id: decodeImageProcess
        command: ["bash", "-c", `[ -f '${root.imageDecodeFilePath}' ] || echo '${StringUtils.shellSingleQuoteEscape(root.entry)}' | ${Cliphist.cliphistBinary} decode > '${root.imageDecodeFilePath}'`]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.source = root.imageDecodeFilePath;
            } else {
                console.error("[CliphistImage] Failed to decode image for entry:", root.entry);
                root.source = "";
            }
        }
    }

    // Cleanup on destruction
    Component.onDestruction: {
        if (root.imageDecodeFilePath) {
            Quickshell.execDetached(["bash", "-c", `[ -f '${root.imageDecodeFilePath}' ] && rm -f '${root.imageDecodeFilePath}'`]);
        }
    }

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: image.width
            height: image.height
            radius: root.radius
        }
    }

    Image {
        id: image
        anchors.fill: parent
        source: root.source ? Qt.resolvedUrl("file://" + root.source) : ""
        fillMode: Image.PreserveAspectFit
        antialiasing: true
        asynchronous: true
        visible: !root.blur && root.source !== ""
    }

    // Blur overlay for hidden images
    Loader {
        id: blurLoader
        active: root.blur && root.source !== ""
        anchors.fill: parent
        sourceComponent: Item {
            anchors.fill: parent
            
            Image {
                id: blurImage
                anchors.fill: parent
                source: root.source ? Qt.resolvedUrl("file://" + root.source) : ""
                fillMode: Image.PreserveAspectFit
                visible: false
            }
            
            GaussianBlur {
                anchors.fill: blurImage
                source: blurImage
                radius: 35
                samples: radius * 2 + 1
            }

            Rectangle {
                anchors.fill: parent
                color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.5)
                radius: root.radius

                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    
                    MaterialSymbol {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "visibility_off"
                        font.pixelSize: 28
                        color: Appearance.colors.colOnLayer0
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.blurText
                        color: Appearance.colors.colOnLayer0
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                }
            }
        }
    }
    
    // Loading indicator
    MaterialSymbol {
        anchors.centerIn: parent
        visible: root.source === "" && root.entry
        text: "hourglass_empty"
        font.pixelSize: 24
        color: Appearance.colors.colSubtext
    }
}
