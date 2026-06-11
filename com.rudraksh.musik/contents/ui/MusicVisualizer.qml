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

    // Tuning knobs (sent live to the backend, see ConfigGeneral)
    property real bellWidth: 0.45    // gaussian sigma / barCount; wider = flatter
    property real bellFloor: 0.3     // edge bars reactivity floor (0..1)
    property real reactivity: 0.65   // 0 floaty .. 1 snappy
    property real punch: 0.8         // gamma; <1 boosts quiet detail

    onBellWidthChanged: pushConfig()
    onBellFloorChanged: pushConfig()
    onReactivityChanged: pushConfig()
    onPunchChanged: pushConfig()

    function pushConfig() {
        if (socket.status === WebSocket.Open) {
            socket.sendTextMessage(JSON.stringify({
                bellWidth: bellWidth,
                bellFloor: bellFloor,
                reactivity: reactivity,
                gamma: punch
            }))
        }
    }

    property var barHeights: new Array(barCount).fill(0)
    property var peakHeights: new Array(barCount).fill(0)
    property var targetHeights: new Array(barCount).fill(0)
    property real time: 0

    // Client-side smoothing follows the reactivity knob (snappier = less lag)
    readonly property real smoothing: 0.85 - reactivity * 0.25
    readonly property real peakFallSpeed: 0.02
    readonly property real minHeight: 0.05
    readonly property real barSpacing: 2
    readonly property real stopAnimationDuration: 1000 // Duration for the stopping animation in ms

    // Track if we're in the stopping animation
    property bool isStopping: false
    property real stopProgress: 0

    // Zune-style snow cap: body keeps the album color untouched, only the
    // very peaks blend into a hotter bright variant. Grayscale album art
    // falls back to the classic Zune hot pink cap.
    readonly property bool achromatic: accentColor.hsvSaturation < 0.12
    readonly property color peakColor: achromatic ? "#FF2D78" : Qt.hsva(
        (accentColor.hsvHue + 1.0 - 0.05) % 1.0,
        Math.min(accentColor.hsvSaturation * 1.3 + 0.1, 1.0),
        Math.min(accentColor.hsvValue * 1.35 + 0.25, 1.0),
        1.0
    )

    // Effect knobs (bound to config in main.qml)
    property real glowRadius: 120
    property real trailLength: 70
    property bool motionTrail: false

    function mixColor(c1, c2, t) {
        return Qt.rgba(
            c1.r * (1 - t) + c2.r * t,
            c1.g * (1 - t) + c2.g * t,
            c1.b * (1 - t) + c2.b * t,
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

        onStatusChanged: {
            if (socket.status === WebSocket.Open) {
                root.pushConfig()
            }
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

                    // Snow-cap gradient, anchored in screen space but scaled
                    // to the tallest *reachable* bar height (depends on
                    // intensity) so the hot zone is actually hit by peaks.
                    var peak = root.peakColor
                    var base = root.accentColor
                    var mid = mixColor(base, peak, 0.45)
                    var maxReach = Math.min((minHeight + 1.3 * intensity) * h, h)
                    var gradient = ctx.createLinearGradient(0, h, 0, h - maxReach)
                    gradient.addColorStop(0.0, Qt.rgba(base.r, base.g, base.b, 0.85))
                    gradient.addColorStop(0.6, Qt.rgba(base.r, base.g, base.b, 1.0))
                    gradient.addColorStop(0.8, Qt.rgba(mid.r, mid.g, mid.b, 1.0))
                    gradient.addColorStop(0.92, Qt.rgba(peak.r, peak.g, peak.b, 1.0))
                    gradient.addColorStop(1.0, Qt.rgba(peak.r, peak.g, peak.b, 1.0))

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
                radius: root.glowRadius
                samples: 120
                cached: true
                opacity: root.motionTrail ? 0.85 : 1.0
            }

            // Optional vertical motion-blur streaks over the glow
            DirectionalBlur {
                anchors.fill: canvas
                source: canvas
                angle: 0            // 0 = vertical
                length: root.trailLength
                samples: 64
                cached: false
                visible: root.motionTrail && root.trailLength > 0
                opacity: 0.9
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