import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components as PlasmaComponents3

// inspired by https://stackoverflow.com/a/49031115/2568933
Item {
    id: root

    enum OverflowBehaviour {
        AlwaysScroll,
        ScrollOnMouseOver,
        StopScrollOnMouseOver
    }

    property int overflowBehaviour: ScrollingText.OverflowBehaviour.AlwaysScroll
    property color textColor: "#A8FFFFFF"  // Add property for text color


    property string text: ""
    readonly property string spacing: "     "
    readonly property string textAndSpacing: text + spacing

    property int maxWidth: 200 * units.devicePixelRatio
    readonly property bool overflow: maxWidth <= textMetrics.width
    property int speed: 5;
    readonly property int duration: (25 * (11 - speed) + 25)* textAndSpacing.length;

    // Align the text in the center
    property int horizontalAlignment: Text.AlignLeft

    readonly property bool pauseScrolling: {
        if (overflowBehaviour === ScrollingText.OverflowBehaviour.AlwaysScroll) {
            return false;
        } else if (overflowBehaviour === ScrollingText.OverflowBehaviour.ScrollOnMouseOver) {
            return !mouse.hovered;
        } else if (overflowBehaviour === ScrollingText.OverflowBehaviour.StopScrollOnMouseOver) {
            return mouse.hovered;
        }
    }

    property alias font: label.font

    width: overflow ? maxWidth : textMetrics.width + 10
    clip: true

    Layout.preferredHeight: label.implicitHeight
    Layout.preferredWidth: width
    Layout.alignment: Qt.AlignHCenter

    HoverHandler {
        id: mouse
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

        onHoveredChanged: {
            if (!hovered && root.overflow) {
                label.x = 0
            }
        }
    }

    TextMetrics {
        id: textMetrics
        font: label.font
        text: root.text
    }

    // Add smooth color transition
    Behavior on textColor {
        ColorAnimation { duration: 300 }
    }

    // PlasmaComponents3.Label {
    //     id: label
    //     text: overflow ? root.textAndSpacing : root.text
    //     horizontalAlignment: root.horizontalAlignment
    //     width: parent.width // Ensure the label takes full width of its parent

    //     NumberAnimation on x {
    //         running: root.overflow
    //         paused: root.pauseScrolling
    //         from: root.horizontalAlignment === Text.AlignHCenter ? (root.width - label.implicitWidth) / 2 : 0
    //         to: -label.implicitWidth
    //         duration: root.duration
    //         loops: Animation.Infinite

    //         function reset() {
    //             label.x = root.horizontalAlignment === Text.AlignHCenter ? (root.width - label.implicitWidth) / 2 : 0;
    //             if (running) {
    //                 restart()
    //             }
    //             if (root.pauseScrolling) {
    //                 pause()
    //             }
    //         }

    //         onRunningChanged: () => {
    //             // When `running` becomes true the animation start regardless of the `pauseScrolling` value.
    //             // Manually pause the animation if the `pauseScrolling` value is true.
    //             if (running && root.pauseScrolling) {
    //                 pause()
    //             }
    //         }
    //         onToChanged: () => reset()
    //         onDurationChanged: () =>  reset()
    //     }

    //     PlasmaComponents3.Label {
    //         visible: overflow
    //         anchors.left: parent.right
    //         horizontalAlignment: root.horizontalAlignment
    //         width: parent.width

    //         font: label.font
    //         text: label.text
    //     }
    // }

    readonly property bool shouldScroll: textMetrics.width > width

    Item {
        id: textContainer
        width: shouldScroll ? label.width * 2 + root.spacing.length * label.font.pixelSize : label.width
        height: label.height

        Layout.alignment: Qt.AlignHCenter


        PlasmaComponents3.Label {
            id: label
            text: root.text
            // horizontalAlignment: root.horizontalAlignment
            width: Math.max(implicitWidth, root.width)
            elide: Text.ElideNone
            color: root.textColor  // Apply the text color
        }

        PlasmaComponents3.Label {
            id: repeatLabel
            visible: shouldScroll
            anchors.left: label.right
            // horizontalAlignment: root.horizontalAlignment
            width: label.width
            height: label.height
            text: root.spacing + root.text
            font: label.font
            color: root.textColor  // Apply the text color to the repeat label as well
        }
    }

    NumberAnimation {
        id: scrollAnimation
        target: textContainer
        property: "x"
        from: 0
        to: -label.width - root.spacing.length * label.font.pixelSize
        duration: root.duration
        loops: Animation.Infinite
        running: false  // We'll control this manually

        onRunningChanged: {
            if (running) {
                from = 0;
                to = -label.width - root.spacing.length * label.font.pixelSize;
                restart();
            }
        }
    }

    onWidthChanged: Qt.callLater(updateScroll)
    onTextChanged: Qt.callLater(updateScroll)
    onPauseScrollingChanged: Qt.callLater(updateScroll)
    Component.onCompleted: Qt.callLater(updateScroll)

    function updateScroll() {
        scrollAnimation.stop();
        if (shouldScroll) {
            textContainer.x = 0;
            if (!root.pauseScrolling) {
                scrollAnimation.start();
            }
        } else {
            textContainer.x = (root.width - textContainer.width) / 2;
        }
    }

    // Make the function callable from outside
    function forceUpdateScroll() {
        Qt.callLater(updateScroll);
    }

    Behavior on width {
        NumberAnimation {
            duration: 100
        }
    }
}
