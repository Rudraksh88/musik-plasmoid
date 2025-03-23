import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components as PlasmaComponents3
import QtQuick.Effects

Item {
    id: root

    enum OverflowBehaviour {
        AlwaysScroll,
        ScrollOnMouseOver,
        StopScrollOnMouseOver
    }

    property int overflowBehaviour: ScrollingText.OverflowBehaviour.AlwaysScroll
    // property color textColor: "#A8FFFFFF" // White with 65% opacity
    property color textColor: "#A8FFFFFF" // Use white, then apply opacity and MultiEffects locally
    property string text: ""
    property string spacing: "     "
    property int maxWidth: 200 * units.devicePixelRatio
    property int speed: 5
    property alias font: mainText.font
    property int horizontalAlignment: Text.AlignLeft
    property var hoveredOnPlasmoid: false
    property var fullRepresentation: false

    readonly property bool shouldScroll: textMetrics.width > width
    readonly property int scrollDuration: shouldScroll ? ((25 * (11 - speed) + 25) * text.length) : 0

    width: Math.min(maxWidth, textMetrics.width)
    height: mainText.height
    clip: true

    Layout.preferredHeight: height
    Layout.preferredWidth: width
    Layout.alignment: Qt.AlignHCenter

    TextMetrics {
        id: textMetrics
        font: mainText.font
        text: root.text
    }

    // HoverHandler {
    //     id: mouseArea
    //     acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    // }

    readonly property bool shouldPauseScrolling: {
        if (!shouldScroll) return true
        if (overflowBehaviour === ScrollingText.OverflowBehaviour.AlwaysScroll) {
            return false
        } else if (overflowBehaviour === ScrollingText.OverflowBehaviour.ScrollOnMouseOver) {
            // return !mouseArea.hovered // Old scoped mouseArea
            return !hoveredOnPlasmoid
        } else {
            // return mouseArea.hovered // Old scoped mouseArea
            return hoveredOnPlasmoid
        }
    }

    Item {
        id: scrollContainer
        width: childrenRect.width
        height: mainText.height
        x: 0

        Row {
            id: textRow
            spacing: 0

            PlasmaComponents3.Label {
                id: mainText
                text: root.text
                color: fullRepresentation ? root.textColor : 'white'
                opacity: fullRepresentation ? 1.0 : hoveredOnPlasmoid ? 0.45 : 0.35
                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }
                }

                layer.enabled: !fullRepresentation
                layer.effect: MultiEffect {
                    brightness: 0.8
                    contrast: 0.07
                    saturation: 1.0
                }
            }

            PlasmaComponents3.Label {
                id: spacerText
                text: root.spacing
                color: fullRepresentation ? root.textColor : 'white'
                font: mainText.font
                visible: root.shouldScroll
            }

            PlasmaComponents3.Label {
                id: duplicateText
                text: root.text
                color: fullRepresentation ? root.textColor : 'white'
                font: mainText.font
                visible: root.shouldScroll

                opacity: fullRepresentation ? 1.0 : hoveredOnPlasmoid ? 0.45 : 0.35
                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }
                }

                layer.enabled: !fullRepresentation
                layer.effect: MultiEffect {
                    brightness: 0.8
                    contrast: 0.07
                    saturation: 1.0
                }
            }
        }

        NumberAnimation {
            id: scrollAnimation
            target: scrollContainer
            property: "x"
            from: scrollAnimation.running ? scrollContainer.x : 0
            to: -(mainText.width + spacerText.width)
            duration: root.scrollDuration
            loops: Animation.Infinite
            running: root.shouldScroll && !root.shouldPauseScrolling
            easing.type: Easing.Linear

            onRunningChanged: {
                if (!running) {
                    scrollContainer.x = horizontalAlignment === Text.AlignHCenter ?
                        (root.width - mainText.width) / 2 : 0
                }
            }
        }

        Behavior on x {
            // enabled: !scrollAnimation.running
            NumberAnimation {
                // duration: 150

                // Duration should increase with x
                duration: 150 * -(scrollContainer.x * 0.2)
                easing.type: Easing.OutCubic
            }
        }
    }

    function forceUpdateScroll() {
        if (scrollAnimation.running) {
            scrollAnimation.restart()
        }
    }

    // Smooth color transitions
    // Behavior on textColor {
    //     ColorAnimation {
    //         duration: 150
    //         easing.type: Easing.OutCubic
    //     }
    // } // Not needed now since we're using MultiEffects
}
