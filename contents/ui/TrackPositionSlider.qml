import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components as PlasmaComponents3
import org.kde.coreaddons 1.0 as KCoreAddons

Item {
    id: container

    // Original properties
    property bool disableUpdatePosition: false
    property double songPosition: 0
    property double songLength: 0
    property bool playing: false
    property alias enableChangePosition: customSlider.enabled
    property alias refreshInterval: timer.interval

    // Custom properties
    property color trackColor: "#30FFFFFF"
    property color progressColor: "#FFFFFF"
    property color progressColorOnHover: progressColor  // New property for hover state
    property color handleColor: progressColor          // Handle color follows progress color
    property color defaultForegroundColor: "#FFFFFF"   // Default color when no accent
    property real trackThickness: 4
    property real handleSize: 15
    property real handleRadius: handleSize / 2
    property bool showHandleOnHover: true
    property int sliderPadding: 10

    property double lastSongLength: 0

    // Helper functions for color determination
    function getCurrentProgressColor() {
        if (!plasmoid.configuration.accentedProgressBar) {
            return defaultForegroundColor
        }

        if (plasmoid.configuration.progressBarAccentOnHover) {
            return customSlider.hovered ?
                   (plasmoid.configuration.useCustomColor ? plasmoid.configuration.accentColor : progressColorOnHover) :
                   defaultForegroundColor
        }

        return plasmoid.configuration.useCustomColor ? plasmoid.configuration.accentColor : progressColor
    }

    // Signals
    signal requireChangePosition(position: double)
    signal requireUpdatePosition()

    Layout.preferredHeight: column.implicitHeight
    Layout.fillWidth: true

    onSongLengthChanged: {
        if (lastSongLength !== songLength) {
            lastSongLength = songLength
        }
    }

    onSongPositionChanged: {
        if (!customSlider.pressed && !customSlider.changingPosition) {
            customSlider.value = songPosition / Math.max(1, songLength)
        }
    }

    Timer {
        id: timer
        interval: 200
        running: container.playing && !customSlider.pressed && !customSlider.changingPosition
        repeat: true
        onTriggered: container.requireUpdatePosition()
    }

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 0

        Item {
            id: customSlider
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(container.handleSize * 1.5, container.trackThickness) + container.sliderPadding

            property real value: 0
            property bool pressed: mouseArea.pressed
            property bool changingPosition: false
            property bool enabled: true
            property bool hovered: mouseArea.containsMouse || handleMouseArea.containsMouse
            property bool handleHovered: handleMouseArea.containsMouse

            Rectangle {
                id: track
                anchors.centerIn: parent
                width: parent.width - container.handleSize
                height: container.trackThickness
                radius: height / 2
                color: container.trackColor
                antialiasing: true
                x: container.handleSize / 2

                Rectangle {
                    id: progress
                    width: Math.max(0, Math.min(parent.width, parent.width * customSlider.value))
                    height: parent.height
                    radius: height / 2
                    color: getCurrentProgressColor()
                    antialiasing: true
                    clip: true

                    Behavior on width {
                        SmoothedAnimation {
                            duration: 50
                            velocity: -1
                        }
                    }

                    // Add color transition
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Rectangle {
                    id: handle
                    width: container.handleSize
                    height: container.handleSize
                    radius: container.handleRadius
                    color: getCurrentProgressColor()  // Handle color matches progress
                    antialiasing: true

                    x: progress.width - (width / 2)
                    y: -height/2 + parent.height/2

                    transformOrigin: Item.Center

                    scale: {
                        if (customSlider.handleHovered) return 2
                        if (customSlider.hovered) return 1
                        if (container.showHandleOnHover) return 0.6
                        return 1
                    }

                    opacity: (!container.showHandleOnHover || customSlider.hovered) ? 1 : 0

                    layer.enabled: true
                    layer.smooth: true

                    Behavior on scale {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on x {
                        SmoothedAnimation {
                            duration: 50
                            velocity: -1
                        }
                    }
                    // Add color transition
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }

                    MouseArea {
                        id: handleMouseArea
                        anchors.fill: parent
                        anchors.margins: -5
                        hoverEnabled: true

                        onPressed: (mouse) => {
                            mouse.accepted = false
                        }
                        onReleased: (mouse) => {
                            mouse.accepted = false
                        }
                        onPositionChanged: (mouse) => {
                            mouse.accepted = false
                        }
                    }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                enabled: customSlider.enabled

                onPressed: (mouse) => {
                    if (!customSlider.enabled) return
                    updatePosition(mouse)
                }

                onPositionChanged: (mouse) => {
                    if (!pressed) return
                    updatePosition(mouse)
                }

                onReleased: {
                    if (!customSlider.enabled) return
                    customSlider.changingPosition = true
                    const targetPosition = customSlider.value * container.songLength
                    if (targetPosition !== container.songPosition) {
                        container.requireChangePosition(targetPosition)
                    }
                    customSlider.changingPosition = false
                }

                function updatePosition(mouse) {
                    const adjustedWidth = width - container.handleSize
                    const adjustedX = mouse.x - (container.handleSize / 2)
                    const newValue = Math.max(0, Math.min(1, adjustedX / adjustedWidth))
                    customSlider.value = newValue
                }
            }
        }

        RowLayout {
            Layout.preferredWidth: parent.width
            Layout.topMargin: -6
            Layout.fillWidth: true
            Layout.leftMargin: 7
            Layout.rightMargin: 7
            id: timeLabels

            function formatDuration(duration) {
                const hideHours = container.songLength < 3600000000
                const durationFormatOption = hideHours ? KCoreAddons.FormatTypes.FoldHours : KCoreAddons.FormatTypes.DefaultDuration
                return KCoreAddons.Format.formatDuration(duration / 1000, durationFormatOption)
            }

            PlasmaComponents3.Label {
                Layout.alignment: Qt.AlignLeft
                text: timeLabels.formatDuration(container.songPosition)
                // font: Qt.font({
                //     pointSize: 10.5,
                //     features: { "tnum": 1 }
                // })
                font: Qt.font({
                    pointSize: timeFont.pointSize,
                    features: { "tnum": 1 },
                    family: timeFont.family,
                    letterSpacing: timeFont.letterSpacing
                })
                opacity: 1
            }

            PlasmaComponents3.Label {
                Layout.alignment: Qt.AlignRight
                text: timeLabels.formatDuration(container.songLength - container.songPosition)
                // font: Qt.font({
                //     pointSize: 10.5,
                //     features: { "tnum": 1 }
                // })
                font: Qt.font({
                    pointSize: timeFont.pointSize,
                    features: { "tnum": 1 },
                    family: timeFont.family,
                    letterSpacing: timeFont.letterSpacing
                })
                opacity: 0.7
            }
        }
    }
}