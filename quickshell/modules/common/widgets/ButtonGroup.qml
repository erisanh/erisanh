import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * A container that displays buttons with equal widths and bouncy interactions.
 */
Rectangle {
    id: root
    default property alias data: rowLayout.data
    property real spacing: 5
    property real padding: 0
    property int clickIndex: -1  // Index of currently pressed button

    property int visibleChildCount: {
        let count = 0;
        for (let i = 0; i < rowLayout.children.length; ++i) {
            if (rowLayout.children[i].visible)
                count++;
        }
        return count;
    }

    // Base equal width for each button when not pressed
    property real baseButtonWidth: {
        if (visibleChildCount === 0)
            return 0;
        const availableWidth = root.width - (padding * 2) - (spacing * (visibleChildCount - 1));
        return availableWidth / visibleChildCount;
    }

    topLeftRadius: 12
    bottomLeftRadius: 12
    topRightRadius: 12
    bottomRightRadius: 12

    color: "transparent"
    implicitHeight: 50 + padding * 2

    children: [
        RowLayout {
            id: rowLayout
            anchors.fill: parent
            anchors.margins: root.padding
            spacing: root.spacing

            // Set Layout.fillWidth based on proximity to clicked button
            onChildrenChanged: {
                updateChildrenLayout();
            }
        }
    ]

    onClickIndexChanged: {
        updateChildrenLayout();
    }

    function updateChildrenLayout() {
        for (let i = 0; i < rowLayout.children.length; ++i) {
            const child = rowLayout.children[i];
            if (!child.visible)
                continue;

            // Check if this child is the clicked one or adjacent to it
            const isClicked = (i === clickIndex);
            const isAdjacent = (i === clickIndex - 1 || i === clickIndex + 1);

            if (clickIndex === -1) {
                // No button pressed - all equal width
                child.Layout.fillWidth = true;
            } else if (isClicked || isAdjacent) {
                // Clicked button and adjacent buttons use fillWidth for animation
                child.Layout.fillWidth = true;
            } else {
                // Other buttons maintain their base width
                child.Layout.fillWidth = false;
                child.Layout.preferredWidth = baseButtonWidth;
            }
        }
    }
}
