import QtQuick 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects
import QtWebSockets
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

Item {
    id: root

    property bool isPlaying: false
    property color accentColor: "#1d99f3"
    property bool showPeaks: true
    property int barCount: 32
    property real intensity: 1.0

    // Live audio data (Zune-style bell spectrum from the backend)
    property int backendPort: 13769
    property var liveHeights: []
    property double lastDataTime: 0
    // Fall back to the procedural animation when no fresh backend data
    readonly property bool liveData: socket.status === WebSocket.Open
                                     && liveHeights.length === barCount

    property var barHeights: new Array(barCount).fill(0)
    property var peakHeights: new Array(barCount).fill(0)
    property var targetHeights: new Array(barCount).fill(0)
    property real time: 0

    readonly property real smoothing: 0.85
    readonly property real peakFallSpeed: 0.02
    readonly property real minHeight: 0.05
    readonly property real barSpacing: 2
    readonly property real stopAnimationDuration: 1000 // Duration for the stopping animation in ms

    // Track if we're in the stopping animation
    property bool isStopping: false
    property real stopProgress: 0

    // Generate harmonious secondary color
    readonly property color secondaryColor: {
        const hue = accentColor.hsvHue
        const sat = accentColor.hsvSaturation
        const val = accentColor.hsvValue

        return Qt.hsva(
            (hue + 0.15) % 1.0,  // +54 degrees
            sat * 1.1,
            val * 0.95,
            1.0
        )
    }

    // Spawns the python backend (idempotent: it exits if the port is taken)
    P5Support.DataSource {
        id: backendLauncher
        engine: "executable"
        onNewData: (sourceName) => disconnectSource(sourceName)

        function launch() {
            const script = Qt.resolvedUrl("../scripts/visualizer_backend.py")
                             .toString().replace(/^file:\/\//, "")
            connectSource("setsid python3 '" + script + "' --port " + root.backendPort
                          + " --bars " + root.barCount + " >/dev/null 2>&1 &")
        }
    }

    WebSocket {
        id: socket
        url: "ws://127.0.0.1:" + root.backendPort
        active: root.isPlaying || root.isStopping

        onTextMessageReceived: (message) => {
            root.liveHeights = JSON.parse(message)
            root.lastDataTime = Date.now()
        }
    }

    // While playing without a connection: (re)spawn backend and retry
    Timer {
        interval: 3000
        repeat: true
        running: root.isPlaying && socket.status !== WebSocket.Open
        triggeredOnStart: true
        onTriggered: {
            backendLauncher.launch()
            socket.active = false
            socket.active = Qt.binding(() => root.isPlaying || root.isStopping)
        }
    }

    // Handle stopping animation
    NumberAnimation {
        id: stopAnimation
        target: root
        property: "stopProgress"
        from: 0
        to: 1
        duration: stopAnimationDuration
        easing.type: Easing.OutCubic
        running: false

        onFinished: {
            isStopping = false
            stopProgress = 0
        }
    }

    // Monitor isPlaying changes
    onIsPlayingChanged: {
        if (!isPlaying) {
            isStopping = true
            stopAnimation.start()
        } else {
            time = 0
            stopAnimation.stop()
            isStopping = false
            stopProgress = 0
        }
    }

    Item {
        id: paddedContainer
        anchors.fill: parent
        anchors.margins: -130

        Item {
            id: visualizerContainer
            anchors.fill: parent
            anchors.margins: 32

            Canvas {
                id: canvas
                anchors.fill: parent
                renderStrategy: Canvas.Cooperative
                visible: false

                Timer {
                    id: animTimer
                    interval: 16
                    repeat: true
                    running: root.isPlaying || root.isStopping
                    onTriggered: {
                        if (root.isPlaying) {
                            time += interval / 1000
                        }
                        updateBars()
                        canvas.requestPaint()
                    }
                }

                onPaint: {
                    var ctx = getContext("2d")
                    var w = width
                    var h = height

                    ctx.clearRect(0, 0, w, h)

                    var barWidth = (w - (barSpacing * (barCount - 1))) / barCount

                    // Modified gradient with dominant accent color and subtle secondary color
                    var gradient = ctx.createLinearGradient(0, h, 0, h * 1)

                    // Start with very subtle secondary color (15% mix)
                    gradient.addColorStop(1, Qt.rgba(
                        accentColor.r * 0.85 + secondaryColor.r * 0.45,
                        accentColor.g * 0.85 + secondaryColor.g * 0.45,
                        accentColor.b * 0.85 + secondaryColor.b * 0.45,
                        0.6
                    ))

                    // Transition quickly to accent-dominant color
                    gradient.addColorStop(0.8, Qt.rgba(
                        accentColor.r * 0.95 + secondaryColor.r * 0.25,
                        accentColor.g * 0.95 + secondaryColor.g * 0.25,
                        accentColor.b * 0.95 + secondaryColor.b * 0.25,
                        1
                    ))

                    // Pure accent color at the peak
                    gradient.addColorStop(0, Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.8))

                    // Draw bars
                    for (var i = 0; i < barCount; i++) {
                        var x = i * (barWidth + barSpacing)
                        var barHeight = barHeights[i] * h

                        // Draw overlapping rectangles with the gradient
                        for (var j = 0; j < 3; j++) {
                            ctx.fillStyle = gradient
                            var expandedWidth = barWidth * (1.8 + j * 0.4)
                            ctx.fillRect(x - expandedWidth/3, h - barHeight, expandedWidth, barHeight)
                        }
                    }
                }
            }

            GaussianBlur {
                anchors.fill: canvas
                source: canvas
                radius: 120
                samples: 120
                cached: true
                opacity: 1
            }
        }
    }

    function updateBars() {
        // Stale guard: backend connected but audio routed elsewhere / stream gap
        var fresh = liveData && (Date.now() - lastDataTime) < 500

        for (var i = 0; i < barCount; i++) {
            if (isPlaying && fresh) {
                targetHeights[i] = minHeight + liveHeights[i] * 1.3 * intensity
            } else if (isPlaying) {
                var phase = (i / barCount) * Math.PI * 2
                var wave = (Math.sin(time * 2.5 + phase) + 1) / 2
                var wave2 = (Math.sin(time * 1.7 + phase * 2) + 1) / 2
                var wave3 = (Math.sin(time * 1.2 + phase * 3) + 1) / 2

                targetHeights[i] = minHeight + (wave * 0.3 + wave2 * 0.2 + wave3 * 0.15) * intensity
            } else if (isStopping) {
                // When stopping, gradually lower the bars based on stopProgress
                targetHeights[i] = barHeights[i] * (1 - stopProgress)
            } else {
                targetHeights[i] = minHeight
            }

            // Apply smoothing to the height transitions
            barHeights[i] = barHeights[i] * smoothing + targetHeights[i] * (1 - smoothing)
        }
    }

    // Smooth color transition when accent color changes
    Behavior on accentColor {
        ColorAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
}