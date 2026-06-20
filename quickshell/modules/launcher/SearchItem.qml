import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

/**
 * SearchItem - A selectable result item in the launcher
 */
RippleButton {
    id: root

    property LauncherSearchResult entry
    property string query
    property bool entryShown: entry?.shown ?? true
    property string itemType: entry?.type ?? "App"
    property string itemName: entry?.name ?? ""
    property var iconType: entry?.iconType
    property string iconName: entry?.iconName ?? ""
    property var itemExecute: entry?.execute
    property var fontType: switch (entry?.fontType) {
    case LauncherSearchResult.FontType.Monospace:
        return "monospace";
    case LauncherSearchResult.FontType.Normal:
        return "main";
    default:
        return "main";
    }
    property string itemClickActionName: entry?.verb ?? "Open"
    property string bigText: entry?.iconType === LauncherSearchResult.IconType.Text ? entry?.iconName ?? "" : ""
    property string materialSymbol: entry?.iconType === LauncherSearchResult.IconType.Material ? entry?.iconName ?? "" : ""
    property string cliphistRawString: entry?.rawValue ?? ""
    property bool isClipboardImage: cliphistRawString && Cliphist.entryIsImage(cliphistRawString)

    signal close

    visible: root.entryShown
    property int horizontalMargin: 10
    property int buttonHorizontalPadding: 10
    property int buttonVerticalPadding: 6
    property bool keyboardDown: false

    implicitHeight: rowLayout.implicitHeight + root.buttonVerticalPadding * 2
    implicitWidth: rowLayout.implicitWidth + root.buttonHorizontalPadding * 2
    buttonRadius: Appearance.rounding.normal
    colBackground: (root.down || root.keyboardDown) ? Appearance.colors.colPrimaryContainerActive : ((root.hovered || root.focus) ? Appearance.colors.colPrimaryContainer : ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 1))
    colBackgroundHover: Appearance.colors.colPrimaryContainer
    colRipple: Appearance.colors.colPrimaryContainerActive

    property string highlightPrefix: `<u><font color="${Appearance.colors.colPrimary}">`
    property string highlightSuffix: `</font></u>`

    function highlightContent(content, query) {
        if (!query || query.length === 0 || content === query || fontType === "monospace")
            return StringUtils.escapeHtml(content);

        let contentLower = content.toLowerCase();
        let queryLower = query.toLowerCase();

        let result = "";
        let lastIndex = 0;
        let qIndex = 0;

        for (let i = 0; i < content.length && qIndex < query.length; i++) {
            if (contentLower[i] === queryLower[qIndex]) {
                if (i > lastIndex)
                    result += StringUtils.escapeHtml(content.slice(lastIndex, i));
                result += root.highlightPrefix + StringUtils.escapeHtml(content[i]) + root.highlightSuffix;
                lastIndex = i + 1;
                qIndex++;
            }
        }
        if (lastIndex < content.length)
            result += StringUtils.escapeHtml(content.slice(lastIndex));

        return result;
    }

    property string displayContent: highlightContent(root.itemName, root.query)

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.NoButton
    }

    background {
        anchors.fill: root
        anchors.leftMargin: root.horizontalMargin
        anchors.rightMargin: root.horizontalMargin
    }

    onClicked: {
        root.close();
        root.itemExecute();
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Delete && event.modifiers === Qt.ShiftModifier) {
            const deleteAction = root.entry?.actions?.find(action => action.name === "Delete");
            if (deleteAction) {
                deleteAction.execute();
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.keyboardDown = true;
            root.clicked();
            event.accepted = true;
        }
    }

    Keys.onReleased: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.keyboardDown = false;
            event.accepted = true;
        }
    }

    RowLayout {
        id: rowLayout
        spacing: iconLoader.sourceComponent === null ? 0 : 10
        anchors.fill: parent
        anchors.leftMargin: root.horizontalMargin + root.buttonHorizontalPadding
        anchors.rightMargin: root.horizontalMargin + root.buttonHorizontalPadding

        // Icon
        Loader {
            id: iconLoader
            active: true
            sourceComponent: switch (root.iconType) {
            case LauncherSearchResult.IconType.Asset:
                return assetIconComponent;
            case LauncherSearchResult.IconType.Material:
                return materialSymbolComponent;
            case LauncherSearchResult.IconType.Text:
                return bigTextComponent;
            case LauncherSearchResult.IconType.System:
                return iconImageComponent;
            case LauncherSearchResult.IconType.None:
                return null;
            default:
                return null;
            }
        }

        Component {
            id: iconImageComponent
            IconImage {
                source: Quickshell.iconPath(root.iconName, "image-missing")
                width: 35
                height: 35
            }
        }

        Component {
            id: assetIconComponent
            CustomIcon {
                source: root.iconName
                width: 30
                height: 30
                colorize: true
                color: Appearance.m3colors.m3onSurface
            }
        }

        Component {
            id: materialSymbolComponent
            MaterialSymbol {
                text: root.materialSymbol
                iconSize: 30
                color: Appearance.m3colors.m3onSurface
            }
        }

        Component {
            id: bigTextComponent
            Text {
                text: root.bigText
                font.pixelSize: Appearance.font.pixelSize.larger
                color: Appearance.m3colors.m3onSurface
            }
        }

        // Main text
        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            Text {
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                visible: root.itemType && root.itemType !== "App"
                text: root.itemType
            }

            RowLayout {
                Loader {
                    visible: itemName === Quickshell.clipboardText && root.cliphistRawString
                    active: itemName === Quickshell.clipboardText && root.cliphistRawString
                    sourceComponent: Rectangle {
                        implicitWidth: activeText.implicitHeight
                        implicitHeight: activeText.implicitHeight
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colPrimary
                        MaterialSymbol {
                            id: activeText
                            anchors.centerIn: parent
                            text: "check"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.m3colors.m3onPrimary
                        }
                    }
                }

                Text {
                    id: nameText
                    Layout.fillWidth: true
                    textFormat: Text.StyledText
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.family: Appearance.font.family[root.fontType]
                    color: Appearance.m3colors.m3onSurface
                    horizontalAlignment: Text.AlignLeft
                    elide: Text.ElideRight
                    text: root.isClipboardImage ? "[Image]" : root.displayContent
                }
            }
            
            // Clipboard image preview
            Loader {
                active: root.isClipboardImage
                visible: root.isClipboardImage
                Layout.fillWidth: true
                Layout.topMargin: 4
                
                sourceComponent: CliphistImage {
                    entry: root.cliphistRawString
                    maxWidth: contentColumn.width
                    maxHeight: 140
                    blur: false
                }
            }
        }

        // Action text
        Text {
            Layout.fillWidth: false
            visible: root.hovered || root.focus
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOnPrimaryContainer
            horizontalAlignment: Text.AlignRight
            text: root.itemClickActionName
        }

        // Action buttons
        RowLayout {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: root.buttonVerticalPadding
            Layout.bottomMargin: -root.buttonVerticalPadding
            spacing: 4

            Repeater {
                id: actionsRepeater
                model: (root.entry?.actions ?? []).slice(0, 4)
                delegate: RippleButton {
                    id: actionButton
                    required property var modelData
                    property var actionIconType: modelData.iconType
                    property string actionIconName: modelData.iconName ?? ""
                    property string actionName: modelData.name ?? ""
                    implicitHeight: 34
                    implicitWidth: 34

                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                    colRipple: Appearance.colors.colSecondaryContainerActive

                    contentItem: Item {
                        anchors.centerIn: parent
                        // CustomIcon for Asset icons (SVG from assets/icons)
                        Loader {
                            anchors.centerIn: parent
                            active: actionButton.actionIconType === LauncherSearchResult.IconType.Asset
                            sourceComponent: CustomIcon {
                                source: actionButton.actionIconName
                                width: 20
                                height: 20
                                colorize: true
                                // Use powerButton color for Delete action, same as notification clear button
                                color: actionButton.actionName === "Delete" ? Appearance.colors.colPowerButton : Appearance.m3colors.m3onSurface
                            }
                        }
                        // MaterialSymbol for Material icons
                        Loader {
                            anchors.centerIn: parent
                            active: actionButton.actionIconType === LauncherSearchResult.IconType.Material || actionButton.actionIconName === ""
                            sourceComponent: MaterialSymbol {
                                text: actionButton.actionIconName || "video_settings"
                                font.pixelSize: Appearance.font.pixelSize.hugeass
                                color: Appearance.m3colors.m3onSurface
                            }
                        }
                        // IconImage for System icons
                        Loader {
                            anchors.centerIn: parent
                            active: actionButton.actionIconType === LauncherSearchResult.IconType.System && actionButton.actionIconName !== ""
                            sourceComponent: IconImage {
                                source: Quickshell.iconPath(actionButton.actionIconName)
                                implicitSize: 20
                            }
                        }
                    }

                    onClicked: modelData.execute()

                    ToolTip {
                        visible: actionButton.hovered
                        text: modelData.name
                    }
                }
            }
        }
    }
}
