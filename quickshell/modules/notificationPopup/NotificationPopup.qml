import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root

    required property var notif

    width: 400
    implicitHeight: mainLayout.implicitHeight + 10 // 5px padding on top/bottom
    radius: 15
    color: Appearance.m3colors.m3background
    border.width: 1
    border.color: Appearance.m3colors.m3outlineVariant

    // Helper: Determine if image value is a real image (not an icon name/file)
    function isRealImage(imageValue: string): bool {
        if (!imageValue) return false;
        // SVG files in icon directories are icons, not real images - should show in header
        if (imageValue.endsWith(".svg") && imageValue.includes("/icons/")) return false;
        if (imageValue.startsWith("image://qsimage/")) return true;
        if (imageValue.startsWith("file://")) return true;
        if (imageValue.startsWith("http://") || imageValue.startsWith("https://")) return true;
        if (imageValue.includes("/")) return true;
        return false;
    }

    // // DEBUG: Log notification data on load
    // Component.onCompleted: {
    //     if (root.notif) {
    //         console.log("DEBUG NotificationPopup - appName:", root.notif.appName,
    //                     "| appIcon:", root.notif.appIcon,
    //                     "| image:", root.notif.image,
    //                     "| isRealImage:", root.isRealImage(root.notif.image ?? ""));
    //     }
    // }

    HoverHandler {
        id: hoverHandler
        onHoveredChanged: {
            if (root.notif) {
                if (hovered) {
                    root.notif.timeLeft = root.notif.timeout
                    root.notif.setPaused(true);
                } else {
                    root.notif.setPaused(false);
                }
            }
        }
    }

    // pause timeout on hover
    MouseArea {
        anchors.fill: parent

        onClicked: {
            Notifications.hideNotificationPopup(root.notif.notificationId);
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 5
        spacing: 0

        // header Section
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            Layout.bottomMargin: 4

            Item {
                id: iconContainer
                implicitWidth: 20
                implicitHeight: 20

                // Show app icon if available and loads successfully
                IconImage {
                    id: appIconImage
                    anchors.fill: parent
                    source: {
                        if (!root.notif) return "";
                        // Priority 1: appIcon from notification
                        if (root.notif.appIcon) {
                            let resolved = Quickshell.iconPath(root.notif.appIcon, true);
                            if (resolved) return resolved;
                        }
                        // Priority 2: icon/svg in image field (not a real image like screenshot)
                        if (root.notif.image && !root.isRealImage(root.notif.image)) {
                            let imagePath = root.notif.image;
                            // Handle SVG file paths directly
                            if (imagePath.endsWith(".svg") && imagePath.includes("/")) {
                                if (imagePath.startsWith("/")) {
                                    return "file://" + imagePath;
                                }
                                return imagePath;
                            }
                            // Try icon name resolution
                            let resolved = Quickshell.iconPath(imagePath, true);
                            if (resolved) return resolved;
                        }
                        // Priority 3: use AppSearch.guessIcon for robust resolution
                        if (root.notif.appName) {
                            let guessed = AppSearch.guessIcon(root.notif.appName);
                            // Reject generic fallback icons - we prefer our own fallback
                            if (guessed && guessed !== "image-missing" && guessed !== "application-x-executable") {
                                return Quickshell.iconPath(guessed, true);
                            }
                        }
                        return "";
                    }
                    implicitSize: 20
                    visible: status === Image.Ready
                }

                // Show fallback icon if app icon not provided or failed to load
                CustomIcon {
                    id: fallbackIcon
                    anchors.fill: parent
                    source: "software-update-urgent-symbolic.svg"
                    width: 20
                    height: 20
                    visible: appIconImage.status !== Image.Ready
                }
            }

            Text {
                text: root.notif ? root.notif.appName : ""
                Layout.leftMargin: 8
                opacity: 0.8
                color: Appearance.colors.colOnLayer0
                font.pointSize: 10
            }

            Item {
                Layout.fillWidth: true
            } // spacer

            Text {
                id: timeDisplay
                opacity: 0.7
                color: Appearance.colors.colOnLayer0
                font.pointSize: 9
                Component.onCompleted: {
                    timeDisplay.text = Time.hoursMinutes;
                }
            }

            Item {
                id: closeButtonContainer
                property real iconSize: 15
                implicitWidth: iconSize
                implicitHeight: iconSize
                CustomIcon {
                    id: closeIcon
                    source: "window-close-symbolic"
                    anchors.centerIn: parent
                    width: closeButtonContainer.iconSize
                    height: closeButtonContainer.iconSize
                    colorize: true
                    color: Appearance.colors.colPowerButton
                }
            }
        }

        // separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Appearance.colors.colOnLayer0
            opacity: 0.2
        }

        // time out progress bar
        Rectangle {
            id: progressBar
            width: parent.width * (root.notif.timeLeft > 0 && root.notif.timeout > 0 ? notif.timeLeft / notif.timeout : 0)
            Layout.bottomMargin: 5
            height: 3
            radius: 3
            color: Appearance.colors.colPrimary

            Behavior on width {
                NumberAnimation {
                    duration: 50
                    easing.type: Easing.Linear
                }
            }
        }

        // content section
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            Layout.leftMargin: 5
            Layout.rightMargin: 5
            spacing: 10

            ClippingWrapperRectangle {
                radius: 8
                antialiasing: true
                visible: root.isRealImage(root.notif?.image ?? "") && notificationImage.status === Image.Ready
                Item {
                    id: notificationImageContainer
                    implicitWidth: 86
                    implicitHeight: 86
                    anchors.centerIn: parent

                    Image {
                        id: notificationImage
                        anchors.fill: parent
                        source: {
                            if (root.notif && root.notif.image) {
                                let imagePath = root.notif.image;

                                // Handle image://qsimage/ URLs (actual notification images from D-Bus)
                                if (imagePath.startsWith("image://qsimage/")) {
                                    return imagePath;
                                }

                                // Handle image://icon/ prefix (some apps use this format)
                                if (imagePath.startsWith("image://icon/")) {
                                    const stripped = imagePath.replace("image://icon/", "");
                                    // Check if stripped value is an icon name (no path separator)
                                    if (!stripped.includes("/")) {
                                        return Quickshell.iconPath(stripped, "");
                                    }
                                    // It's a file path, convert to file:// URL
                                    if (stripped.startsWith("~/"))
                                        return "file://" + stripped.replace("~", Quickshell.homePath);
                                    return "file://" + stripped;
                                }

                                // Detect if image is actually an icon name (no path separators or schemes)
                                // Some apps (SafeEyes, fish) put icon names in the image field
                                if (!imagePath.includes("/") && !imagePath.includes("://")) {
                                    // It's likely an icon name, resolve it via Quickshell.iconPath()
                                    return Quickshell.iconPath(imagePath, "");
                                }

                                // handle normal "~/" paths
                                if (imagePath.startsWith("~/"))
                                    return "file://" + imagePath.replace("~", Quickshell.homePath);

                                // handle already-valid file URLs
                                if (imagePath.startsWith("file://"))
                                    return imagePath;

                                // default case (could be a direct path)
                                return imagePath;
                            }
                            return "";
                        }
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        antialiasing: true
                        asynchronous: true
                        visible: source !== ""

                        // Component.onCompleted: {
                        //     console.log("Notification image source:", notificationImage.source);
                        // }
                    }
                }
            }

            // right column: summary & body
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    text: root.notif ? root.notif.summary : ""
                    font.bold: true
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    color: Appearance.colors.colOnLayer0
                    Layout.fillWidth: true
                }

                Text {
                    text: root.notif ? root.notif.body : ""
                    wrapMode: Text.WordWrap
                    textFormat: Text.AutoText // to handle markup if any
                    color: Appearance.colors.colOnLayer0
                    Layout.fillWidth: true
                    maximumLineCount: 20
                    elide: Text.ElideRight
                }
            }
        }

        // actions
        RowLayout {
            id: actionsRow
            Layout.fillWidth: true
            Layout.topMargin: 6
            Layout.leftMargin: 5
            Layout.rightMargin: 5
            spacing: 6
            visible: root.notif && root.notif.actions && root.notif.actions.length > 0

            Repeater {
                model: root.notif ? root.notif.actions : []
                delegate: RippleButton {
                    buttonText: modelData.text
                    buttonRadius: 8
                    colBackground: Appearance.colors.colLayer1
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    colRipple: Appearance.colors.colPrimary
                    implicitHeight: 32
                    padding: 12

                    contentItem: Text {
                        text: modelData.text
                        color: Appearance.colors.colOnLayer0
                        font.pixelSize: Appearance.font.pixelSize.small
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: Notifications.attemptInvokeAction(root.notif.notificationId, modelData.identifier)
                }
            }
        }

        // inline reply
        Loader {
            id: inlineReplyLoader
            Layout.fillWidth: true
            Layout.topMargin: 4
            active: false
            sourceComponent: RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 5
                Layout.rightMargin: 5
                spacing: 6
                TextField {
                    id: replyField
                    Layout.fillWidth: true
                    placeholderText: "Reply…"
                    selectByMouse: true
                }
                RippleButton {
                    buttonText: "Send"
                    buttonRadius: 8
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    colRipple: Appearance.colors.colLayer0
                    implicitHeight: 32
                    padding: 12
                    enabled: replyField.text.length > 0

                    contentItem: Text {
                        text: "Send"
                        color: Appearance.colors.colOnPrimary
                        font.pixelSize: Appearance.font.pixelSize.small
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        root.notif.notification.sendInlineReply(replyField.text);
                        if (!root.notif.notification.resident) {
                            Notifications.discardNotification(root.notif.notificationId);
                        }
                    }
                }
            }
        }
    }
}
