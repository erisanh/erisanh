import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

RippleButton {
    id: root

    horizontalPadding: 20
    verticalPadding: 12
    clip: true
    required property var device
    property bool expanded: false
    pointingHandCursor: !expanded
    implicitWidth: contentItem.implicitWidth + horizontalPadding * 2
    implicitHeight: contentItem.implicitHeight + verticalPadding * 2

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 500
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.38, 1.21, 0.22, 1.00, 1, 1]
        }
    }
    colBackground: Appearance.m3colors.m3background
    colBackgroundHover: Appearance.colors.colLayer2Hover
    colRipple: Appearance.m3colors.m3primary
    buttonRadius: 0

    onClicked: expanded = !expanded
    altAction: () => expanded = !expanded

    component ActionButton: RippleButton {
        id: actionButton

        implicitHeight: 36
        implicitWidth: 80
        padding: 14
        buttonRadius: 9999
        property color colText: actionButton.enabled ? Appearance.colors.colOnLayer0 : Appearance.m3colors.m3background

        contentItem: Text {
            anchors.fill: parent
            anchors.leftMargin: actionButton.padding
            anchors.rightMargin: actionButton.padding
            text: actionButton.buttonText
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 12
            color: actionButton.colText
        }
    }

    contentItem: ColumnLayout {
        anchors {
            fill: parent
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }
        spacing: 0

        RowLayout {
            // Name
            spacing: 10

            CustomIcon {
                property string symbol: {
                    const name = root.device?.icon ?? "";
                    if (name.includes("headset"))
                        return "audio-headset-symbolic";
                    if (name.includes("headphones"))
                        return "audio-headphones-symbolic";
                    if (name.includes("audio"))
                        return "audio-speakers-symbolic";
                    if (name.includes("phone"))
                        return "phone-apple-iphone-symbolic";
                    if (name.includes("mouse"))
                        return "input-mouse-symbolic";
                    if (name.includes("keyboard"))
                        return "input-keyboard-symbolic";
                    return "bluetooth-active-symbolic";
                }

                source: symbol
                width: 20
                height: 20
                colorize: true
                color: Appearance.colors.colOnLayer0
            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    color: Appearance.colors.colOnLayer0
                    elide: Text.ElideRight
                    text: root.device?.name || "Unknown device"
                }
                Text {
                    visible: (root.device?.connected || root.device?.paired) ?? false
                    Layout.fillWidth: true
                    font.pixelSize: 12
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                    text: {
                        if (!root.device?.paired)
                            return "";
                        let statusText = root.device?.connected ? "Connected" : "Paired";
                        if (!root.device?.batteryAvailable)
                            return statusText;
                        statusText += ` • ${Math.round(root.device?.battery * 100)}%`;
                        return statusText;
                    }
                }
            }

            CustomIcon {
                source: "go-down-symbolic"
                width: 15
                height: 15
                colorize: true
                color: Appearance.colors.colOnLayer0
                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.34, 0.80, 0.34, 1.00, 1, 1]
                    }
                }
            }
        }

        RowLayout {
            visible: root.expanded
            Layout.topMargin: 8
            Item {
                Layout.fillWidth: true
            }
            ActionButton {
                // Show Pair button for unpaired devices
                visible: !(root.device?.paired ?? false)
                buttonText: root.device?.pairing ? "Pairing..." : "Pair"
                enabled: !(root.device?.pairing ?? false)
                colBackground: Appearance.m3colors.m3secondaryContainer
                colBackgroundHover: ColorUtils.transparentize(colBackground, 0.2)
                colText: Appearance.m3colors.m3onSecondaryContainer

                onClicked: {
                    // Ensure adapter is pairable (some systems have this off by default)
                    if (Bluetooth.defaultAdapter && !Bluetooth.defaultAdapter.pairable) {
                        Bluetooth.defaultAdapter.pairable = true;
                    }
                    // Set trusted before pairing so the device is remembered
                    root.device.trusted = true;
                    root.device.pair();
                }
            }
            ActionButton {
                buttonText: root.device?.connected ? "Disconnect" : "Connect"
                colBackground: Appearance.m3colors.m3primary
                colBackgroundHover: ColorUtils.transparentize(colBackground, 0.2)
                colText: Appearance.m3colors.m3onPrimary

                onClicked: {
                    if (root.device?.connected) {
                        root.device.disconnect();
                    } else {
                        root.device.connect();
                    }
                }
            }
            ActionButton {
                visible: root.device?.paired ?? false
                colBackground: Appearance.colors.colError
                colBackgroundHover: ColorUtils.transparentize(colBackground, 0.2)
                colRipple: Appearance.m3colors.m3onError
                colText: Appearance.m3colors.m3onError

                buttonText: "Forget"
                onClicked: {
                    root.device?.forget();
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
