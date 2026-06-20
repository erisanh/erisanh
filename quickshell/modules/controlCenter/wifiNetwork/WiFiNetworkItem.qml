import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import QtQuick
import QtQuick.Layouts

RippleButton {
    id: root

    horizontalPadding: 20
    verticalPadding: 12
    clip: true
    required property WifiAccessPoint wifiNetwork
    property bool active: (wifiNetwork?.askingPassword || wifiNetwork?.active) ?? false
    pointingHandCursor: !active
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
    colBackgroundHover: active ? colBackground : Appearance.colors.colLayer2Hover
    colRipple: Appearance.m3colors.m3primary
    buttonRadius: 0

    onClicked: {
        Network.connectToWifiNetwork(wifiNetwork);
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
                property int strength: root.wifiNetwork?.strength ?? 0
                source: {
                    if (strength > 66)
                        return "network-wireless-signal-good-symbolic";
                    if (strength > 33)
                        return "network-wireless-signal-ok-symbolic";
                    return "network-wireless-signal-weak-symbolic";
                }
                width: 20
                height: 20
                colorize: true
                color: Appearance.colors.colOnLayer0
            }

            Text {
                Layout.fillWidth: true
                color: Appearance.colors.colOnLayer0
                elide: Text.ElideRight
                text: root.wifiNetwork?.ssid ?? "Unknown"
            }

            CustomIcon {
                visible: (root.wifiNetwork?.isSecure || root.wifiNetwork?.active) ?? false
                source: root.wifiNetwork?.active ? "object-select-symbolic" : Network.wifiConnectTarget === root.wifiNetwork ? "content-loading-symbolic" : "channel-secure-symbolic"
                width: 20
                height: 20
                colorize: true
                color: Appearance.colors.colOnLayer0
            }
        }

        ColumnLayout { // Password
            id: passwordPrompt
            Layout.topMargin: 8
            visible: root.wifiNetwork?.askingPassword ?? false

            MaterialTextField {
                id: passwordField
                Layout.fillWidth: true
                placeholderText: "Password"

                // Password
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData

                onAccepted: {
                    Network.changePassword(root.wifiNetwork, passwordField.text);
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                RippleButton {
                    id: cancelButton
                    implicitHeight: 36
                    implicitWidth: 80
                    padding: 14
                    colBackground: ColorUtils.transparentize(Appearance.m3colors.m3background)
                    buttonRadius: 9999

                    contentItem: Text {
                        anchors.fill: parent
                        anchors.leftMargin: cancelButton.padding
                        anchors.rightMargin: cancelButton.padding
                        text: "Cancel"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 12
                        color: cancelButton.enabled ? Appearance.colors.colOnLayer0 : Appearance.m3colors.m3background
                    }

                    onClicked: {
                        root.wifiNetwork.askingPassword = false;
                    }
                }

                RippleButton {
                    id: connectButton
                    implicitHeight: 36
                    implicitWidth: 80
                    padding: 14
                    colBackground: ColorUtils.transparentize(Appearance.m3colors.m3background)
                    buttonRadius: 9999

                    contentItem: Text {
                        anchors.fill: parent
                        anchors.leftMargin: connectButton.padding
                        anchors.rightMargin: connectButton.padding
                        text: "Connect"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 12
                        color: connectButton.enabled ? Appearance.colors.colOnLayer0 : Appearance.m3colors.m3background
                    }

                    onClicked: {
                        Network.changePassword(root.wifiNetwork, passwordField.text);
                    }
                }
            }
        }

        ColumnLayout { // Public wifi login page
            id: publicWifiPortal
            Layout.topMargin: 8
            visible: (root.wifiNetwork?.active && (root.wifiNetwork?.security ?? "").trim().length === 0) ?? false

            RowLayout {
                RippleButton {
                    id: networkPortalButton
                    Layout.fillWidth: true
                    implicitHeight: 36
                    implicitWidth: networkPortalText.implicitWidth + padding * 2
                    padding: 14

                    contentItem: Text {
                        id: networkPortalText
                        anchors.fill: parent
                        anchors.leftMargin: networkPortalButton.padding
                        anchors.rightMargin: networkPortalButton.padding
                        text: "Open network portal"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 15
                        color: cancelButton.enabled ? Appearance.colors.colOnLayer0 : Appearance.m3colors.m3background
                    }

                    onClicked: {
                        Network.openPublicWifiPortal();
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
