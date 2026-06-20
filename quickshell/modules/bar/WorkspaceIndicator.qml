import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.modules.common

Item {
    id: workspaceIndicatorRoot

    readonly property int defaultWorkspaceCount: 5
    readonly property int horizontalPadding: 8
    readonly property int pillSpacing: 5

    readonly property int activeSize: 20
    readonly property int hasWindowsSize: 12
    readonly property int emptySize: 8
    readonly property real itemContainerWidth: activeSize * 1.2

    readonly property real activeWidthMultiplier: 1.2
    readonly property real activeIndicatorWidth: itemContainerWidth * activeWidthMultiplier

    readonly property int targetIndex: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id - 1 : 0

    readonly property string mainColor: Appearance.colors.colPrimary

    readonly property real targetX: {
        if (dotsRepeater.count === 0 || targetIndex < 0 || targetIndex >= dotsRepeater.count) {
            return 0 - (activeIndicatorWidth / 2);
        }

        var targetItem = dotsRepeater.itemAt(targetIndex);
        if (targetItem) {
            var centerPointInRoot = targetItem.mapToItem(workspaceIndicatorRoot, targetItem.width / 2, 0);
            return centerPointInRoot.x - (activeIndicatorWidth / 2);
        }

        return 0 - (activeIndicatorWidth / 2);
    }

    property bool isInitialized: false

    Component.onCompleted: {
        Qt.callLater(() => {
            isInitialized = true;
        });
    }

    readonly property int maxWorkspaceId: {
        if (Hyprland.workspaces?.values?.length > 0) {
            let ids = Hyprland.workspaces.values.map(ws => ws.id);
            // ensure have enough items for the target index
            var count = Math.max(defaultWorkspaceCount, Math.max(...ids));
            // if focused workspace is outside current max, expand to fill it
            if (Hyprland.focusedWorkspace) {
                count = Math.max(count, Hyprland.focusedWorkspace.id);
            }
            return count;
        }
        return Math.max(defaultWorkspaceCount, Hyprland.focusedWorkspace?.id || 0);
    }

    // the component's implicit size is calculated based on its contents
    implicitHeight: activeSize + 10 // WrapperRectangle's margin * 2
    implicitWidth: {
        const repeaterWidth = (itemContainerWidth * maxWorkspaceId) + (pillSpacing * (maxWorkspaceId - 1));
        return repeaterWidth + (horizontalPadding * 2) + 10; // WrapperRectangle's margin * 2
    }

    WrapperRectangle {
        id: background
        anchors.fill: parent
        color: Appearance.colors.colLayer1
        radius: 20
        margin: 5
    }

    RowLayout {
        id: dotsLayout
        anchors.centerIn: parent
        spacing: pillSpacing

        Item {
            Layout.preferredWidth: horizontalPadding
        }

        Repeater {
            id: dotsRepeater
            model: maxWorkspaceId

            delegate: Item {

                Layout.preferredWidth: itemContainerWidth
                Layout.preferredHeight: activeSize

                readonly property int workspaceId: index + 1
                readonly property var actualWorkspace: Hyprland.workspaces?.values?.find(w => w.id === workspaceId) || null

                Rectangle {
                    anchors.centerIn: parent

                    height: actualWorkspace && actualWorkspace.toplevels?.values?.length > 0 ? hasWindowsSize : emptySize
                    width: height
                    radius: height / 2

                    color: {
                        if (workspaceMouseArea.containsMouse)
                            return mainColor;
                        return actualWorkspace && actualWorkspace.toplevels?.values?.length > 0 ? Appearance.colors.colOnLayer0 : Appearance.colors.colEmptyWorkspace;
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }

                MouseArea {
                    id: workspaceMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Hyprland.dispatch(`workspace ${workspaceId}`)
                }
            }
        }

        Item {
            Layout.preferredWidth: horizontalPadding
        }
    }

    // move the animation outside the behavior so that it can be referenced
    NumberAnimation {
        id: pillMoveAnimation
        duration: 150
        easing.type: Easing.InOutCubic
    }

    Rectangle {
        z: 1 // make sure it's drawn on top of the dots
        anchors.verticalCenter: parent.verticalCenter
        height: activeSize
        width: activeIndicatorWidth
        radius: height / 2
        color: mainColor
        enabled: false

        x: targetX

        // condition behavior
        Behavior on x {
            animation: workspaceIndicatorRoot.isInitialized ? pillMoveAnimation : null
        }
    }
}
