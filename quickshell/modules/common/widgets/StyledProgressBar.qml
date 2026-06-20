pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

ProgressBar {
    id: root
    property real valueBarWidth: 120
    property real valueBarHeight: 4
    property real valueBarGap: 4
    property color highlightColor: "#685496"
    property color trackColor: "#F1D3F9"
    property bool wavy: false
    property bool animateWave: true
    property real waveAmplitudeMultiplier: wavy ? 0.5 : 0
    property real waveFrequency: 6
    property real waveFps: 60

    Behavior on waveAmplitudeMultiplier {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutQuad
        }
    }

    Behavior on value {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutQuad
        }
    }

    background: Item {
        implicitHeight: valueBarHeight
        implicitWidth: valueBarWidth
    }

    contentItem: Item {
        id: contentItem
        anchors.fill: parent

        Loader {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            active: root.wavy
            sourceComponent: WavyLine {
                id: wavyFill
                frequency: root.waveFrequency
                color: root.highlightColor
                amplitudeMultiplier: root.wavy ? 0.5 : 0
                height: contentItem.height * 6
                width: contentItem.width * root.visualPosition
                lineWidth: contentItem.height
                fullLength: root.width
                Connections {
                    target: root
                    function onValueChanged() {
                        wavyFill.requestPaint();
                    }
                    function onHighlightColorChanged() {
                        wavyFill.requestPaint();
                    }
                }
                FrameAnimation {
                    running: root.animateWave
                    onTriggered: {
                        wavyFill.requestPaint();
                    }
                }
            }
        }

        Loader {
            active: !root.wavy
            sourceComponent: Rectangle {
                anchors.left: parent.left
                width: contentItem.width * root.visualPosition
                height: contentItem.height
                radius: height / 2
                color: root.highlightColor
            }
        }

        Rectangle {
            anchors.right: parent.right
            width: (1 - root.visualPosition) * parent.width - valueBarGap
            height: parent.height
            radius: height / 2
            color: root.trackColor
        }

        Rectangle {
            anchors.right: parent.right
            width: valueBarGap
            height: valueBarGap
            radius: height / 2
            color: root.highlightColor
        }
    }
}
