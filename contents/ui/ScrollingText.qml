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
    property color textColor: "#A8FFFFFF" // Default color
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

    // Properties for smooth dampening
    property real scrollPixelsPerMs: shouldScroll ? (mainText.width + spacerText.width) / scrollDuration : 0
    property real lastPauseX: 0
    property real dampingDuration: 800 // ms to slow down after unhover

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

    readonly property bool shouldPauseScrolling: {
        if (!shouldScroll) return true
        if (overflowBehaviour === ScrollingText.OverflowBehaviour.AlwaysScroll) {
            return false
        } else if (overflowBehaviour === ScrollingText.OverflowBehaviour.ScrollOnMouseOver) {
            return !hoveredOnPlasmoid
        } else {
            return hoveredOnPlasmoid
        }
    }

    // Force a repositioning timer - helps with compositor restarts
    Timer {
        id: startupTimer
        interval: 100
        repeat: false
        running: true
        onTriggered: {
            // Initial positioning
            resetTextPosition()

            // Start animation if appropriate
            updateScrollingState()
        }
    }

    // Watch for changes to scrolling state
    onShouldPauseScrollingChanged: {
        updateScrollingState()
    }

    // Handle text changes
    onTextChanged: {
        // Reset position and update scrolling
        resetTextPosition()
        updateScrollingState()
    }

    // Track changes for fullRepresentation
    onFullRepresentationChanged: {
        // When switching between representations, reset state
        resetTextPosition()
        updateScrollingState()
    }

    // Fix for when the width changes
    onWidthChanged: {
        if (!shouldScroll) {
            resetTextPosition()
        }
    }

    // Parent visibility handler
    Connections {
        target: parent
        function onVisibleChanged() {
            if (parent && parent.visible) {
                // Small delay before fixing position
                shellRestartTimer.start()
            }
        }
    }

    // Timer to handle shell restarts
    Timer {
        id: shellRestartTimer
        interval: 50
        repeat: false
        onTriggered: {
            // Reposition text and restart animation
            resetTextPosition()
            updateScrollingState()
        }
    }

    // // Polling timer to detect stuck text
    // Timer {
    //     id: safetyCheckTimer
    //     interval: 2000
    //     repeat: true
    //     running: root.visible && shouldScroll
    //     onTriggered: {
    //         // If text is stuck off-screen, reset it
    //         if (scrollContainer.x < -mainText.width) {
    //             // Text is too far left, reset
    //             resetTextPosition()
    //             updateScrollingState()
    //         }
    //     }
    // }

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

        // Main scrolling animation
        NumberAnimation {
            id: normalScrollAnimation
            target: scrollContainer
            property: "x"
            from: 0
            to: -(mainText.width + spacerText.width)
            duration: root.scrollDuration
            loops: Animation.Infinite
            running: false
            easing.type: Easing.Linear

            onStopped: {
                if (root.visible && shouldScroll && !shouldPauseScrolling) {
                    // If animation should still be running,
                    // make sure it restarts from a valid position
                    if (scrollContainer.x <= -mainText.width) {
                        scrollContainer.x = 0
                    }
                    normalScrollAnimation.from = scrollContainer.x
                    normalScrollAnimation.start()
                }
            }
        }

        // Damping animation for smooth slowdown
        NumberAnimation {
            id: dampingAnimation
            target: scrollContainer
            property: "x"
            duration: root.dampingDuration
            easing.type: Easing.OutQuad
            running: false

            onFinished: {
                // If text is already scrolled past the beginning
                if (scrollContainer.x <= -mainText.width) {
                    // Reset to beginning
                    scrollContainer.x = 0
                }
            }
        }
    }

    // Reset text position based on alignment
    function resetTextPosition() {
        if (scrollContainer) {
            // Stop animations first
            normalScrollAnimation.stop()
            dampingAnimation.stop()

            // Reset to correct position
            scrollContainer.x = horizontalAlignment === Text.AlignHCenter ?
                Math.min(0, (root.width - textMetrics.width) / 2) : 0
        }
    }

    // Update animation state based on current conditions
    function updateScrollingState() {
        // Only apply damping in compact mode when unhovering
        if (!shouldScroll) {
            normalScrollAnimation.stop()
            dampingAnimation.stop()
            return
        }

        if (shouldPauseScrolling) {
            // We're pausing
            if (!fullRepresentation && !hoveredOnPlasmoid) {
                // Only apply damping in compact mode on unhover
                applyDamping()
            } else {
                // Just stop without damping
                normalScrollAnimation.stop()
            }
        } else {
            // We're starting or resuming scrolling
            startScrolling()
        }
    }

    // Apply damping animation
    function applyDamping() {
        normalScrollAnimation.stop()

        // Determine damping direction
        var fullCycleDistance = mainText.width + spacerText.width
        var distanceToBeginning = Math.abs(scrollContainer.x)
        var distanceToEnd = Math.abs(-fullCycleDistance - scrollContainer.x)

        // Choose nearest endpoint
        if (distanceToBeginning <= distanceToEnd) {
            dampingAnimation.to = 0
        } else {
            dampingAnimation.to = -fullCycleDistance
        }

        dampingAnimation.from = scrollContainer.x
        dampingAnimation.duration = Math.min(dampingDuration,
            Math.abs(dampingAnimation.to - dampingAnimation.from) / scrollPixelsPerMs * 1.5)

        dampingAnimation.start()
    }

    // Start scrolling animation
    function startScrolling() {
        dampingAnimation.stop()

        // Adjust position if needed
        if (scrollContainer.x <= -mainText.width) {
            scrollContainer.x = 0
        }

        normalScrollAnimation.from = scrollContainer.x
        normalScrollAnimation.duration = root.scrollDuration
        normalScrollAnimation.start()
    }

    // Public function to trigger reset (from outside)
    function forceUpdateScroll() {
        resetTextPosition()
        updateScrollingState()
    }
}