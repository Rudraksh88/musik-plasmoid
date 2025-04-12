import QtQuick 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import QtWebEngine 1.15
import QtQuick.Effects
// import "./lib/audioMotion-analyzer.js" as AudioMotion

PlasmoidItem {
    id: widget

    Plasmoid.status: PlasmaCore.Types.HiddenStatus

    // property color dominantColor: "#A8FFFFFF"  // Default color
    property color dominantColor: plasmoid.configuration.useCustomColor ? plasmoid.configuration.accentColor : "#A8FFFFFF"
    property color defaultActiveColor: "white"
    property color defaultForegroundColor: Qt.rgba(1, 1, 1, 0.65)

    readonly property font textFont: {
        return plasmoid.configuration.useCustomFont ? plasmoid.configuration.customFont : Kirigami.Theme.defaultFont
    }
    readonly property font boldTextFont: Qt.font(Object.assign({}, textFont, {weight: Font.Bold}))

    Player {
        id: player
        sourceName: plasmoid.configuration.sources[plasmoid.configuration.sourceIndex]
        onReadyChanged: {
            Plasmoid.status = player.ready ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
            console.debug(`Player ready changed: ${player.ready} -> plasmoid status changed: ${Plasmoid.status}`)
        }

        // Add this property to track when configuration changes
        property bool updatingFromPlayer: false

        // Update your component to listen to source changes
        onSourceNameChanged: {
            if (!updatingFromPlayer) return;

            // Find the index of the new source in the configuration
            const sourceIndex = plasmoid.configuration.sources.indexOf(sourceName);
            if (sourceIndex >= 0) {
                console.log(`Updating configuration to source: ${sourceName} (index: ${sourceIndex})`);
                plasmoid.configuration.sourceIndex = sourceIndex;
            } else if (sourceName !== "any") {
                // If the source isn't in our configuration yet, add it
                console.log(`Adding new source to configuration: ${sourceName}`);
                let newSources = [...plasmoid.configuration.sources];
                newSources.push(sourceName);
                plasmoid.configuration.sources = newSources;
                plasmoid.configuration.sourceIndex = newSources.length - 1;
            }

            updatingFromPlayer = false;
        }
    }

    // To handle resuming from suspend, add this:
    Connections {
        target: QtQuick.Window.window
        function onVisibleChanged() {
            if (QtQuick.Window.window.visible) {
                console.log("Window became visible, checking for active sources");
                player.updatingFromPlayer = true;
                player.selectActiveSource();
            }
        }
    }

    // Add this to handle manual source selection from the configuration
    Connections {
        target: plasmoid.configuration
        function onSourceIndexChanged() {
            if (player.updatingFromPlayer) return;

            const newSource = plasmoid.configuration.sources[plasmoid.configuration.sourceIndex];
            console.log(`Configuration source changed to: ${newSource}`);
            player.sourceName = newSource;
        }
    }

    Mpris.Mpris2Model {
        id: mpris2Source
        readonly property string sourceName: mpris2Source.currentPlayer.identity.toLowerCase()
    }

    QtObject {
        id: iconSources
        readonly property string shuffleOn:    Qt.resolvedUrl("assets/shuffle_on.svg")
        readonly property string shuffleOff:   Qt.resolvedUrl("assets/shuffle_off.svg")
        readonly property string repeatTrack:  Qt.resolvedUrl("assets/repeat_track.svg")
        readonly property string repeatAll:    Qt.resolvedUrl("assets/repeat_all.svg")
        readonly property string repeatOff:    Qt.resolvedUrl("assets/repeat_off.svg")
        readonly property string play:         Qt.resolvedUrl("assets/play.svg")
        readonly property string pause:        Qt.resolvedUrl("assets/pause.svg")
        readonly property string prev:         Qt.resolvedUrl("assets/prev_track.svg")
        readonly property string next:         Qt.resolvedUrl("assets/next_track.svg")
        readonly property string compactPrev:  Qt.resolvedUrl("assets/compact_prev.svg")
        readonly property string compactNext:  Qt.resolvedUrl("assets/compact_next.svg")
        readonly property string compactPlay:  Qt.resolvedUrl("assets/compact_play.svg")
        readonly property string compactPause: Qt.resolvedUrl("assets/compact_pause.svg")
    }

    // Mini Player font properties
    readonly property font miniPlayerSongNameFont: {
        if (plasmoid.configuration.miniPlayerSongNameUseCustomFont) {
            let font = plasmoid.configuration.miniPlayerSongNameFont
            font.letterSpacing = plasmoid.configuration.miniPlayerSongNameSpacing
            font.capitalization = plasmoid.configuration.miniPlayerSongNameCapitalize ?
                                Font.AllUppercase : Font.MixedCase
            return font
        }
        return Kirigami.Theme.defaultFont
    }

    readonly property font miniPlayerArtistNameFont: {
        if (plasmoid.configuration.miniPlayerArtistNameUseCustomFont) {
            let font = plasmoid.configuration.miniPlayerArtistNameFont
            font.letterSpacing = plasmoid.configuration.miniPlayerArtistNameSpacing
            font.capitalization = plasmoid.configuration.miniPlayerArtistNameCapitalize ?
                                Font.AllUppercase : Font.MixedCase
            return font
        }
        return Kirigami.Theme.defaultFont
    }

    readonly property font fullPlayerSongNameFont: {
        if (plasmoid.configuration.fullPlayerSongNameUseCustomFont) {
            let font = plasmoid.configuration.fullPlayerSongNameFont
            font.letterSpacing = plasmoid.configuration.fullPlayerSongNameSpacing
            font.capitalization = plasmoid.configuration.fullPlayerSongNameCapitalize ?
                                Font.AllUppercase : Font.MixedCase
            return font
        }
        // return Kirigami.Theme.defaultFont
        return Qt.font({
            family: Kirigami.Theme.defaultFont.family,
            pointSize: 18,
            weight: Font.Bold
        })
    }

    readonly property font fullPlayerArtistNameFont: {
        if (plasmoid.configuration.fullPlayerArtistNameUseCustomFont) {
            let font = plasmoid.configuration.fullPlayerArtistNameFont
            font.letterSpacing = plasmoid.configuration.fullPlayerArtistNameSpacing
            font.capitalization = plasmoid.configuration.fullPlayerArtistNameCapitalize ?
                                Font.AllUppercase : Font.MixedCase
            return font
        }

        return Qt.font({
            family: Kirigami.Theme.defaultFont.family,
            pointSize: 10,
            capitalization: Font.AllUppercase,
            letterSpacing: 1,
            weight: Font.Bold
        })
    }

    readonly property font timerFont: {
        if (plasmoid.configuration.timerUseCustomFont) {
            let font = plasmoid.configuration.timerFont
            font.letterSpacing = plasmoid.configuration.timerSpacing
            font.capitalization = plasmoid.configuration.timerCapitalize ?
                                Font.AllUppercase : Font.MixedCase
            return font
        }
        return Kirigami.Theme.defaultFont
    }

    compactRepresentation: Item {
        id: compact

        // Layout.preferredWidth: row.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: row.implicitWidth + Kirigami.Units.largeSpacing * 2
        Layout.fillHeight: true

        readonly property real controlsSize: Math.min(height, Kirigami.Units.iconSizes.medium)

        MouseArea {
            // Use this area for all mouse interactions
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                widget.expanded = !widget.expanded;
            }
        }

        Rectangle {
            id: hoverBackground
            color: '#08FFFFFF' // 3% alpha white // or dominantColor if specified in the config
            radius: 3
            anchors.fill: parent
            visible: plasmoid.configuration.showHoverBackground
            // anchors.topMargin: -2.3
            // anchors.bottomMargin: -2.3

            // Add negative margins to make the background slightly larger than the content (instead of using padding)
            // Use this as some percentage of the widget's height (so that it scales with the widget)
            anchors.topMargin: -widget.height * 0.12
            anchors.bottomMargin: -widget.height * 0.12

            opacity: mouseArea.containsMouse || widget.expanded ? 1.0 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                brightness: 0.8
                contrast: 1.6
                saturation: 1.0
            }

            /* Note
             * The color and fx values here are chosen out of experimentation with various combinations
             * And these values blend the background color nicely (taking a hint of the color while still being white),
             * with the surface underneath, without being very intrusive.

             * color: '#08FFFFFF' alpha based white (just for a subtle white overlay)
             * fx: brightness: 0.8, contrast: 1.6, saturation: 1.0 lower values for performance
             * opacity: 1.0 (hovered) so that it doesn't affect the fx values
            */
        }


        // Rectangle {
        //     id: hoverBackground
        //     color: '#4dFFFFFF' // 5% alpha white // or dominantColor if specified in the config
        //     radius: 3
        //     anchors.fill: parent
        //     // anchors.topMargin: -2.3
        //     // anchors.bottomMargin: -2.3

        //     // Add negative margins to make the background slightly larger than the content (instead of using padding)
        //     // Use this as some percentage of the widget's height (so that it scales with the widget)
        //     anchors.topMargin: -widget.height * 0.12
        //     anchors.bottomMargin: -widget.height * 0.12

        //     opacity: mouseArea.containsMouse || widget.expanded ? 0.3 : 0

        //     Behavior on opacity {
        //         NumberAnimation {
        //             duration: 200
        //         }
        //     }

        //     // layer.enabled: true
        //     // layer.effect: MultiEffect {
        //     //     brightness: 16.0
        //     //     contrast: 3.0
        //     //     saturation: 1.0
        //     // }

        //     /* Note
        //      * The values here are chosen out of experimentation with various combinations
        //      * And these values blend the background color nicely (taking a hint of the color while still being white),
        //      * with the surface underneath, without being very intrusive.
        //     */
        // }

        RowLayout {
            id: row
            spacing: 0
            implicitWidth: row.implicitWidth //+ Kirigami.Units.largeSpacing

            anchors.fill: parent

            PanelIcon {
                size: compact.controlsSize
                icon: plasmoid.configuration.panelIcon
                imageUrl: player.artUrl
                imageRadius: plasmoid.configuration.albumCoverRadius
                type: plasmoid.configuration.useAlbumCoverAsPanelIcon ? "image": "icon"
                Layout.leftMargin: Kirigami.Units.smallSpacing * 2
                Layout.rightMargin: 2
                hoveredOnPlasmoid: mouseArea.containsMouse
            }

            // Separate Title and Artist
            Item {
                visible: plasmoid.configuration.separateText
                Layout.preferredHeight: column.implicitHeight
                Layout.preferredWidth: column.implicitWidth

                // Add some spacing to the left
                Layout.leftMargin: Kirigami.Units.largeSpacing

                ColumnLayout {
                    id: column
                    spacing: 0
                    anchors.fill: parent

                    // Algin
                    Layout.alignment: Qt.AlignVCenter

                    ScrollingText {
                        overflowBehaviour: plasmoid.configuration.textScrollingBehaviour
                        // font: Qt.font({
                        //     family: widget.boldTextFont.family,
                        //     weight: Font.Bold,
                        //     pixelSize: 12
                        // })
                        font: widget.miniPlayerSongNameFont

                        speed: plasmoid.configuration.textScrollingSpeed
                        maxWidth: plasmoid.configuration.maxSongWidthInPanel
                        text: player.title

                        // Align to the left
                        Layout.alignment: Qt.AlignLeft
                    }
                    ScrollingText {
                        overflowBehaviour: plasmoid.configuration.textScrollingBehaviour
                        // font: Qt.font({
                        //     family: widget.textFont.family,
                        //     pixelSize: 7
                        // })
                        font: widget.miniPlayerArtistNameFont
                        speed: plasmoid.configuration.textScrollingSpeed
                        maxWidth: plasmoid.configuration.maxSongWidthInPanel
                        text: player.artists

                        // Align to the left
                        Layout.alignment: Qt.AlignLeft
                    }
                }
            }

            ScrollingText {
                visible: !plasmoid.configuration.separateText
                overflowBehaviour: plasmoid.configuration.textScrollingBehaviour
                speed: plasmoid.configuration.textScrollingSpeed
                maxWidth: plasmoid.configuration.maxSongWidthInPanel
                text: [player.artists, player.title].filter((x) => x).join(" - ")
                // font: widget.textFont
                font: widget.miniPlayerSongNameFont
                // Align to the left
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: 5 // Some spacing to the left of the text
                Layout.rightMargin: -5 // Some spacing to the right of the text
                hoveredOnPlasmoid: mouseArea.containsMouse
                fullRepresentation: false
            }


            // Move the tool buttons to a row grid layout
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                Layout.leftMargin: 6 // Space to the left of the buttons
                Layout.rightMargin: 0 // Space to the right of the buttons
                Layout.minimumWidth: controlsSize * 3
                Layout.maximumWidth: controlsSize * 3
                spacing: 0 // Space between the buttons

                PlasmaComponents3.ToolButton {
                    visible: plasmoid.configuration.commandsInPanel
                    enabled: player.canGoPrevious
                    icon.name: iconSources.compactPrev
                    implicitWidth: compact.controlsSize
                    implicitHeight: compact.controlsSize
                    onClicked: player.previous()
                }

                PlasmaComponents3.ToolButton {
                    visible: plasmoid.configuration.commandsInPanel
                    enabled: player.playbackStatus === Mpris.PlaybackStatus.Playing ? player.canPause : player.canPlay
                    implicitWidth: compact.controlsSize
                    implicitHeight: compact.controlsSize
                    icon.name: player.playbackStatus === Mpris.PlaybackStatus.Playing ? iconSources.compactPause : iconSources.compactPlay
                    onClicked: player.playPause()
                }

                PlasmaComponents3.ToolButton {
                    visible: plasmoid.configuration.commandsInPanel
                    enabled: player.canGoNext
                    implicitWidth: compact.controlsSize
                    implicitHeight: compact.controlsSize
                    icon.name: iconSources.compactNext
                    onClicked: player.next()
                }
            }
        }
    }


    // Linear sRGB to OKLCH conversion functions
    function linearize(value) {
        if (value <= 0.04045) {
            return value / 12.92;
        }
        return Math.pow((value + 0.055) / 1.055, 2.4);
    }

    function delinearize(value) {
        if (value <= 0.0031308) {
            return value * 12.92;
        }
        return 1.055 * Math.pow(value, 1/2.4) - 0.055;
    }

    function rgbToOKLCH(r, g, b) {
        // Convert to 0-1 range
        r /= 255;
        g /= 255;
        b /= 255;

        // Convert to linear RGB
        r = linearize(r);
        g = linearize(g);
        b = linearize(b);

        // Convert to OKLAB
        let l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b;
        let m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b;
        let s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b;

        l = Math.pow(l, 1/3);
        m = Math.pow(m, 1/3);
        s = Math.pow(s, 1/3);

        // Convert to OKLab
        let L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s;
        let a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s;
        let b_ = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s;

        // Convert to OKLCH
        let C = Math.sqrt(a * a + b_ * b_);
        let h = Math.atan2(b_, a) * 180 / Math.PI;
        if (h < 0) h += 360;

        return {
            l: L,        // Lightness (0 to 1)
            c: C,        // Chroma (0 to ~0.4)
            h: h         // Hue (0 to 360)
        };
    }

    function oklchToRGB(L, C, h) {
        // Convert hue to radians
        h = h * Math.PI / 180;

        // Convert OKLCH to OKLab
        let a = C * Math.cos(h);
        let b_ = C * Math.sin(h);

        // Convert to LMS
        let l = L + 0.3963377774 * a + 0.2158037573 * b_;
        let m = L - 0.1055613458 * a - 0.0638541728 * b_;
        let s = L - 0.0894841775 * a - 1.2914855480 * b_;

        l = l * l * l;
        m = m * m * m;
        s = s * s * s;

        // Convert to linear RGB
        let r = +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s;
        let g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s;
        let b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s;

        // Delinearize and convert to 0-255 range
        r = delinearize(r) * 255;
        g = delinearize(g) * 255;
        b = delinearize(b) * 255;

        // Clamp values
        r = Math.max(0, Math.min(255, Math.round(r)));
        g = Math.max(0, Math.min(255, Math.round(g)));
        b = Math.max(0, Math.min(255, Math.round(b)));

        return [r, g, b];
    }

    function isEffectivelyGray(oklch) {
        const chromaThreshold = 0.03;
        return oklch.c <= chromaThreshold;
    }

    function rgbToHsl(r, g, b) {
        r /= 255;
        g /= 255;
        b /= 255;

        const max = Math.max(r, g, b);
        const min = Math.min(r, g, b);
        const chroma = max - min;

        let h = 0;
        if (chroma !== 0) {
            if (max === r) {
                h = ((g - b) / chroma) % 6;
            } else if (max === g) {
                h = ((b - r) / chroma) + 2;
            } else {
                h = ((r - g) / chroma) + 4;
            }
        }

        h = Math.round(h * 60);
        if (h < 0) h += 360;

        const l = (max + min) / 2;
        const s = chroma === 0 ? 0 : chroma / (1 - Math.abs(2 * l - 1));

        return [h, s, l];
    }

    function hslToRgb(h, s, l) {
        const chroma = (1 - Math.abs(2 * l - 1)) * s;
        const h_ = h / 60;
        const x = chroma * (1 - Math.abs(h_ % 2 - 1));
        const m = l - chroma / 2;

        let r = 0, g = 0, b = 0;
        if (h_ >= 0 && h_ < 1) {
            r = chroma;
            g = x;
        } else if (h_ >= 1 && h_ < 2) {
            r = x;
            g = chroma;
        } else if (h_ >= 2 && h_ < 3) {
            g = chroma;
            b = x;
        } else if (h_ >= 3 && h_ < 4) {
            g = x;
            b = chroma;
        } else if (h_ >= 4 && h_ < 5) {
            r = x;
            b = chroma;
        } else {
            r = chroma;
            b = x;
        }

        r = (r + m) * 255;
        g = (g + m) * 255;
        b = (b + m) * 255;

        return [r, g, b];
    }

    // K-means implementation for color clustering
    function kMeansColors(pixels, k = 5, maxIterations = 10) {
        // Initialize centroids randomly from the pixel data
        let centroids = [];
        let pixelCount = pixels.length / 4;
        for (let i = 0; i < k; i++) {
            let randomIndex = Math.floor(Math.random() * pixelCount) * 4;
            centroids.push([
                pixels[randomIndex],
                pixels[randomIndex + 1],
                pixels[randomIndex + 2]
            ]);
        }

        // Main k-means loop
        let clusters = new Array(pixelCount);
        let iterations = 0;
        let changed = true;

        while (changed && iterations < maxIterations) {
            changed = false;
            // Assign pixels to nearest centroid
            for (let i = 0; i < pixelCount; i++) {
                if (pixels[i * 4 + 3] < 125) continue; // Skip transparent pixels

                let minDistance = Infinity;
                let clusterIndex = 0;

                for (let j = 0; j < k; j++) {
                    let distance = colorDistance(
                        [pixels[i * 4], pixels[i * 4 + 1], pixels[i * 4 + 2]],
                        centroids[j]
                    );
                    if (distance < minDistance) {
                        minDistance = distance;
                        clusterIndex = j;
                    }
                }

                if (clusters[i] !== clusterIndex) {
                    changed = true;
                    clusters[i] = clusterIndex;
                }
            }

            // Update centroids
            let sums = Array(k).fill().map(() => [0, 0, 0]);
            let counts = Array(k).fill(0);

            for (let i = 0; i < pixelCount; i++) {
                if (pixels[i * 4 + 3] < 125) continue;
                let cluster = clusters[i];
                sums[cluster][0] += pixels[i * 4];
                sums[cluster][1] += pixels[i * 4 + 1];
                sums[cluster][2] += pixels[i * 4 + 2];
                counts[cluster]++;
            }

            for (let i = 0; i < k; i++) {
                if (counts[i] > 0) {
                    centroids[i] = [
                        Math.round(sums[i][0] / counts[i]),
                        Math.round(sums[i][1] / counts[i]),
                        Math.round(sums[i][2] / counts[i])
                    ];
                }
            }

            iterations++;
        }

        // Return centroids and their counts
        let clusterSizes = Array(k).fill(0);
        for (let i = 0; i < pixelCount; i++) {
            if (clusters[i] !== undefined) {
                clusterSizes[clusters[i]]++;
            }
        }

        return {
            centroids: centroids,
            sizes: clusterSizes
        };
    }

    // Color distance function using weighted RGB
    function colorDistance(color1, color2) {
        const rWeight = 0.299;
        const gWeight = 0.587;
        const bWeight = 0.114;

        return Math.sqrt(
            rWeight * Math.pow(color1[0] - color2[0], 2) +
            gWeight * Math.pow(color1[1] - color2[1], 2) +
            bWeight * Math.pow(color1[2] - color2[2], 2)
        );
    }

    // Median cut implementation for color quantization
    function medianCut(pixels, depth = 2) {
        if (depth === 0 || pixels.length === 0) {
            let r = 0, g = 0, b = 0, count = 0;
            for (let i = 0; i < pixels.length; i += 4) {
                if (pixels[i + 3] < 125) continue;
                r += pixels[i];
                g += pixels[i + 1];
                b += pixels[i + 2];
                count++;
            }
            if (count === 0) return null;
            return {
                color: [
                    Math.round(r / count),
                    Math.round(g / count),
                    Math.round(b / count)
                ],
                count: count
            };
        }

        let rMin = 255, rMax = 0, gMin = 255, gMax = 0, bMin = 255, bMax = 0;
        for (let i = 0; i < pixels.length; i += 4) {
            if (pixels[i + 3] < 125) continue;
            rMin = Math.min(rMin, pixels[i]);
            rMax = Math.max(rMax, pixels[i]);
            gMin = Math.min(gMin, pixels[i + 1]);
            gMax = Math.max(gMax, pixels[i + 1]);
            bMin = Math.min(bMin, pixels[i + 2]);
            bMax = Math.max(bMax, pixels[i + 2]);
        }

        let rRange = rMax - rMin;
        let gRange = gMax - gMin;
        let bRange = bMax - bMin;

        let maxRange = Math.max(rRange, gRange, bRange);
        let channel = maxRange === rRange ? 0 : maxRange === gRange ? 1 : 2;

        let sortedPixels = [];
        for (let i = 0; i < pixels.length; i += 4) {
            if (pixels[i + 3] < 125) continue;
            sortedPixels.push([
                pixels[i],
                pixels[i + 1],
                pixels[i + 2],
                pixels[i + 3],
                pixels[i + channel]
            ]);
        }
        sortedPixels.sort((a, b) => a[4] - b[4]);

        let median = Math.floor(sortedPixels.length / 2);
        let left = new Uint8Array(median * 4);
        let right = new Uint8Array((sortedPixels.length - median) * 4);

        for (let i = 0; i < median; i++) {
            left[i * 4] = sortedPixels[i][0];
            left[i * 4 + 1] = sortedPixels[i][1];
            left[i * 4 + 2] = sortedPixels[i][2];
            left[i * 4 + 3] = sortedPixels[i][3];
        }

        for (let i = 0; i < sortedPixels.length - median; i++) {
            right[i * 4] = sortedPixels[i + median][0];
            right[i * 4 + 1] = sortedPixels[i + median][1];
            right[i * 4 + 2] = sortedPixels[i + median][2];
            right[i * 4 + 3] = sortedPixels[i + median][3];
        }

        return [
            medianCut(left, depth - 1),
            medianCut(right, depth - 1)
        ].filter(x => x !== null);
    }

    function getDominantColor(imageData) {
        const downsampleFactor = 4;
        const data = imageData.data;
        const sampledData = new Uint8Array(Math.ceil(data.length / downsampleFactor));

        for (let i = 0, j = 0; i < data.length; i += 4 * downsampleFactor, j += 4) {
            sampledData[j] = data[i];
            sampledData[j + 1] = data[i + 1];
            sampledData[j + 2] = data[i + 2];
            sampledData[j + 3] = data[i + 3];
        }

        const palette = medianCut(sampledData, 3);

        // Track both dominant and vibrant colors
        let bestColor = null;
        let bestScore = -1;
        let mostVibrantColor = null;
        let highestChroma = -1;

        function isColorTooHarsh(r, g, b) {
            // Check for extremely saturated reds
            if (r > 230 && g < 100 && b < 100) return true;

            const maxChannel = Math.max(r, g, b);
            const minChannel = Math.min(r, g, b);
            const midChannel = r + g + b - maxChannel - minChannel;

            // If the difference between max and mid channels is too high
            if (maxChannel - midChannel > 150) return true;

            // If one channel is extremely high and others are very low
            if (maxChannel > 240 && midChannel < 100) return true;

            return false;
        }

        function getColorScore(oklch, size) {
            const isRed = (oklch.h >= 20 && oklch.h <= 40);
            const maxChromaForHue = isRed ? 0.25 : 0.3;

            // Base score components
            const chromaScore = Math.pow(oklch.c / maxChromaForHue, 1.2);
            const lightnessScore = 1 - Math.abs(0.65 - oklch.l);
            const sizeScore = Math.log(size + 1) / Math.log(1000); // Logarithmic scaling for size

            // Bonus for colors that are saturated but not harsh
            const sweetSpotChroma = isRed ? 0.18 : 0.22;
            const chromaBonus = oklch.c >= sweetSpotChroma ? 1.32 : 1.0;

            return sizeScore * chromaScore * lightnessScore * chromaBonus;
        }

        const processPalette = (colors) => {
            if (!Array.isArray(colors)) {
                const color = colors.color;
                const size = colors.count;

                // Skip obviously harsh colors
                if (isColorTooHarsh(color[0], color[1], color[2])) return;

                const oklch = rgbToOKLCH(color[0], color[1], color[2]);

                // Basic viability checks
                if (oklch.l < 0.2 || oklch.l > 0.85) return;

                const isRed = (oklch.h >= 20 && oklch.h <= 40);
                const maxChromaForHue = isRed ? 0.25 : 0.3;

                // Track the most vibrant color that's not too harsh
                if (oklch.c > highestChroma && oklch.c <= maxChromaForHue) {
                    mostVibrantColor = {
                        color: color,
                        oklch: oklch,
                        size: size
                    };
                    highestChroma = oklch.c;
                }

                // Calculate score for dominant color selection
                const score = getColorScore(oklch, size);

                if (score > bestScore) {
                    bestScore = score;
                    bestColor = {
                        color: color,
                        oklch: oklch,
                        size: size
                    };
                }
            } else {
                colors.forEach(processPalette);
            }
        };

        processPalette(palette);

        if (!bestColor && !mostVibrantColor) {
            return [255, 255, 255];
        }

        // Smart color selection
        let finalColor;
        if (bestColor && mostVibrantColor) {
            // If the most vibrant color is significantly more vibrant and has decent presence
            if (mostVibrantColor.oklch.c > bestColor.oklch.c * 1.2 &&
                mostVibrantColor.size * 2 > bestColor.size * 0.3) {
                finalColor = mostVibrantColor;
            } else {
                finalColor = bestColor;
            }
        } else {
            finalColor = bestColor || mostVibrantColor;
        }

        // Enhance the selected color
        const isRed = (finalColor.oklch.h >= 20 && finalColor.oklch.h <= 40);
        const maxFinalChroma = isRed ? 0.25 : 0.3;

        // Smart enhancement based on current chroma
        let chromaMultiplier = 1.2;
        if (finalColor.oklch.c < 0.1) {
            chromaMultiplier = 1.8; // Boost more if current chroma is low
        } else if (finalColor.oklch.c > 0.2) {
            chromaMultiplier = 1.1; // Boost less if already quite saturated
        }

        const enhancedRgb = oklchToRGB(
            0.72,
            Math.min(maxFinalChroma, finalColor.oklch.c * chromaMultiplier),
            finalColor.oklch.h
        );

        // Final safety check
        if (isColorTooHarsh(enhancedRgb[0], enhancedRgb[1], enhancedRgb[2])) {
            return oklchToRGB(
                0.75,
                Math.min(0.2, finalColor.oklch.c),
                finalColor.oklch.h
            );
        }

        // If saturation is less than 0.2, boost it to 0.3
        // if (rgbToHsl(enhancedRgb[0], enhancedRgb[1], enhancedRgb[2])[1] < 0.2) {
        //     console.log("Boosting saturation",);
        //     let newhsl = rgbToHsl(enhancedRgb[0], enhancedRgb[1], enhancedRgb[2]);
        //     let newenhancedRgb = hslToRgb(newhsl[0], 0.3, newhsl[2]);

        //     return [newenhancedRgb[0], newenhancedRgb[1], newenhancedRgb[2]];
        // }

        return enhancedRgb;
    }

    // Check if image is predominantly gray
    function isImageMostlyGray(imageData) {
        const data = imageData.data;
        let grayCount = 0;
        let totalPixels = 0;

        for (let i = 0; i < data.length; i += 4) {
            if (data[i + 3] < 125) continue; // Skip transparent pixels

            const r = data[i];
            const g = data[i + 1];
            const b = data[i + 2];

            // Check if pixel is close to gray
            const max = Math.max(r, g, b);
            const min = Math.min(r, g, b);
            if ((max - min) <= 20) { // Tolerance for considering a pixel gray
                grayCount++;
            }
            totalPixels++;
        }

        return (grayCount / totalPixels) > 0.7; // Consider gray if 70% pixels are gray
    }

    function prettyPrintColor(color) {
        // Print color in a square in the terminal
        const size = 10;
        const colorStr = `\x1b[48;2;${color[0]};${color[1]};${color[2]}m${' '.repeat(size)}\x1b[0m`;
        console.log(colorStr);
    }

    Canvas {
        id: hiddenCanvas
        visible: false
        width: 300
        height: 300

        Image {
            id: hiddenImage
            visible: false
            width: parent.width
            height: parent.height

            onStatusChanged: {
                if (status === Image.Ready) {
                    hiddenCanvas.requestPaint();
                } else {
                    console.error("Image not ready, no color extracted");

                    // Return to default color
                    widget.dominantColor = plasmoid.configuration.useCustomColor ? plasmoid.configuration.accentColor : Qt.rgba(1, 1, 1, 0.45);
                }
            }
        }

        onPaint: {
            if (hiddenImage.status === Image.Ready) {
                var ctx = getContext('2d');
                ctx.drawImage(hiddenImage, 0, 0, width, height);
                var imageData = ctx.getImageData(0, 0, width, height);

                // Get dominant color using k-means
                var dominantRgb = getDominantColor(imageData);

                // Convert to OKLCH for adjustment
                var dominantOklch = rgbToOKLCH(dominantRgb[0], dominantRgb[1], dominantRgb[2]);

                // Adjust the color for UI use
                var adjustedRgb = oklchToRGB(
                    0.75,                         // Fixed lightness for UI
                    Math.min(0.3, dominantOklch.c * 1.2), // Boost chroma but cap it
                    dominantOklch.h              // Keep original hue
                );

                widget.dominantColor = Qt.rgba(
                    adjustedRgb[0]/255,
                    adjustedRgb[1]/255,
                    adjustedRgb[2]/255,
                    1.0
                );

                // Debug print the dominant color
                console.log("Dominant color:");
                prettyPrintColor(dominantRgb);


                console.log("Adjusted color:");
                prettyPrintColor(adjustedRgb);

            }
        }
    }

    fullRepresentation: Item {
        id: fullRep
        Layout.preferredWidth: Math.max(330, imageContainer.width + 10)  // Minimum width of 300
        Layout.preferredHeight: Math.max(330, imageContainer.height + 10)  // Minimum height of 300
        Layout.minimumWidth: 330
        // Set minimum height to the content height
        Layout.minimumHeight: column.implicitHeight

        Layout.maximumWidth: 500

        ColumnLayout {
            id: column

            // spacing: 0
            anchors.fill: parent
            spacing: Kirigami.Units.largeSpacing

            // Debug MPRIS source
            // Text {
            //     id: sourceNameText
            //     // text: "MPRIS Source: " + mpris2Source.currentPlayer.identity.toLowerCase()
            //     text: "MPRIS Source: " + mpris2Source.sourceName
            //     color: Kirigami.Theme.textColor
            //     font.pixelSize: 12
            //     anchors.horizontalCenter: parent.horizontalCenter
            //     // Add bottom padding
            //     Layout.bottomMargin: 20
            // }


            Rectangle {
                id: imageContainer
                // Layout.alignment: Qt.AlignHCenter
                // Align to <- Horizontal Center -> and ↑ Top
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop


                Layout.preferredWidth: Math.min(fullRep.width - 10, fullRep.height - 160)
                Layout.preferredHeight: Layout.preferredWidth
                Layout.topMargin: plasmoid.configuration.beforeAlbumCover
                // Layout.bottomMargin: 10
                color: "transparent"

                // Add radius to the Rectangle
                radius: plasmoid.configuration.albumCoverRadius  // Adjust this value to control corner roundness

                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 0
                    verticalOffset: 6
                    radius: 30
                    samples: 50
                    color: Qt.rgba(0, 0, 0, 0.35)  // Semi-transparent black
                    spread: 0.03
                    cached: true
                }

                Image {
                    id: albumArt
                    anchors.fill: parent
                    source: player.artUrl || Qt.resolvedUrl("assets/default_album_art.svg")
                    fillMode: Image.PreserveAspectFit

                    // onSourceChanged: {
                    //     // Extract dominant color when image source changes
                    //     widget.extractDominantColor(source);
                    // }

                    onSourceChanged: {
                        if (source) {
                            hiddenImage.source = source;
                        }
                    }

                    // Add layer to enable clipping with rounded corners
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: albumArt.width
                            height: albumArt.height
                            radius: imageContainer.radius
                        }
                    }
                }
            }

            ScrollingText {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(imageContainer.width, maxWidth)
                // horizontalAlignment: Text.AlignHCenter

                speed: plasmoid.configuration.textScrollingSpeed
                font: widget.fullPlayerSongNameFont
                maxWidth: imageContainer.width
                text: player.title

                /*
                * If accented song name is enabled
                *   if custom color is enabled, use the custom color
                *   else use the dominant color
                * else use the default color
                */
                textColor: plasmoid.configuration.accentedSongName ? (plasmoid.configuration.useCustomColor ? plasmoid.configuration.accentColor : widget.dominantColor) : '#A8FFFFFF'
                fullRepresentation: true

                // Add margin before song name
                Layout.topMargin: plasmoid.configuration.beforeSongName
                // Add margin after song name
                Layout.bottomMargin: plasmoid.configuration.afterSongName
            }

            ScrollingText {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(imageContainer.width, maxWidth)

                speed: plasmoid.configuration.textScrollingSpeed
                font: widget.fullPlayerArtistNameFont
                maxWidth: imageContainer.width
                text: player.artists
                opacity: 0.88

                /*
                * If accented artist name is enabled
                *   if custom color is enabled, use the custom color
                *   else use the dominant color
                * else use the default color
                */
                textColor: plasmoid.configuration.accentedArtistName ? (plasmoid.configuration.useCustomColor ? plasmoid.configuration.accentColor : widget.dominantColor) : '#A8FFFFFF'
                fullRepresentation: true

                Connections {
                    target: widget
                    function onDominantColorChanged() {
                        console.log("Dominant color updated in ScrollingText:", widget.dominantColor);
                    }
                }

                // Add margin after artist name
                Layout.bottomMargin: plasmoid.configuration.afterArtistName
            }


            TrackPositionSlider {
                Layout.preferredWidth: imageContainer.width
                Layout.alignment: Qt.AlignHCenter

                // Customize appearance
                trackColor: "#30FFFFFF"
                // handleColor: "#FFFFFF"
                trackThickness: 3
                handleSize: 15
                handleRadius: handleSize / 2  // Circle
                showHandleOnHover: true

                progressColor: widget.dominantColor
                progressColorOnHover: widget.dominantColor
                defaultForegroundColor: widget.defaultForegroundColor

                property font timeFont: widget.timerFont

                // Original properties
                songPosition: player.songPosition
                songLength: player.songLength
                playing: player.playbackStatus === Mpris.PlaybackStatus.Playing
                enableChangePosition: player.canSeek
                onRequireChangePosition: (position) => player.setPosition(position)
                onRequireUpdatePosition: () => player.updatePosition()
            }

            Item {
                id: controlsContainer
                Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                Layout.preferredHeight: playerControls.implicitHeight + 10//+ visualizer.height // 10% overlap
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: plasmoid.configuration.beforePlayerControls
                Layout.bottomMargin: plasmoid.configuration.afterPlayerControls

                // Add visualizer first (will be behind due to z-ordering)
                MusicVisualizer {
                    id: visualizer
                    // Anchor to the fullRep (main container) instead of controlsContainer
                    width: fullRep.width
                    height: 80
                    // Center horizontally relative to controlsContainer
                    x: (controlsContainer.width - width) / 2
                    anchors.bottom: parent.bottom
                    z: 0

                    isPlaying: player.playbackStatus === Mpris.PlaybackStatus.Playing
                    accentColor: widget.dominantColor
                    intensity: 0.5
                    visible: plasmoid.configuration.audioVisualization
                }

                // Move existing player controls here
                RowLayout {
                    id: playerControls
                    spacing: plasmoid.configuration.controlsRowSpacing

                    // Center the row within the container
                    anchors.centerIn: parent
                    // Don't fill the width to keep buttons centered
                    width: implicitWidth
                    z: 1

                    CommandIcon {
                        enabled: player.canChangeShuffle
                        Layout.alignment: Qt.AlignHCenter
                        size: Kirigami.Units.iconSizes.medium - 7
                        // property real iconScale: 0.65
                        source: iconSources.shuffleOn
                        onClicked: player.setShuffle(player.shuffle === Mpris.ShuffleStatus.Off ? Mpris.ShuffleStatus.On : Mpris.ShuffleStatus.Off)
                        active: player.shuffle === Mpris.ShuffleStatus.On
                        // iconColor: player.shuffle === Mpris.ShuffleStatus.On ? widget.dominantColor : Kirigami.Theme.textColor

                        opacity: player.shuffle === Mpris.ShuffleStatus.On ? 1.0 : 0.35
                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }

                        /*
                        * If accented buttons is enabled
                        *   if custom color is enabled, use the custom color
                        *   else use the dominant color
                        * else use the default color
                        */
                        iconColor: player.shuffle === Mpris.ShuffleStatus.On ?
                        (plasmoid.configuration.accentedButtons && !plasmoid.configuration.useCustomColor ? widget.dominantColor : plasmoid.configuration.accentColor) : defaultForegroundColor
                    }

                    RowLayout {
                        spacing: plasmoid.configuration.playerControlsSpacing

                        CommandIcon {
                            enabled: player.canGoPrevious
                            Layout.alignment: Qt.AlignHCenter
                            size: Kirigami.Units.iconSizes.medium - 7
                            // source: "player_prev"
                            source: iconSources.prev
                            onClicked: {
                                player.previous()
                                // Call forceUpdateScroll() from the ScrollingText.qml
                                titleText.forceUpdateScroll()
                                artistText.forceUpdateScroll()
                            }
                        }

                        CommandIcon {
                            enabled: player.playbackStatus === Mpris.PlaybackStatus.Playing ? player.canPause : player.canPlay
                            Layout.alignment: Qt.AlignHCenter
                            size: Kirigami.Units.iconSizes.large + 2
                            source: player.playbackStatus === Mpris.PlaybackStatus.Playing ? iconSources.pause : iconSources.play

                            onClicked: {
                                player.playPause()
                                titleText.forceUpdateScroll()
                                artistText.forceUpdateScroll()
                            }
                        }

                        CommandIcon {
                            enabled: player.canGoNext
                            Layout.alignment: Qt.AlignHCenter
                            size: Kirigami.Units.iconSizes.medium - 7
                            // source: "player_next"
                            source: iconSources.next
                            onClicked: {
                                player.next()
                                // Call forceUpdateScroll() from the ScrollingText.qml
                                titleText.forceUpdateScroll()
                                artistText.forceUpdateScroll()
                            }
                        }
                    }

                    CommandIcon {
                        id: repeatButton
                        enabled: player.canChangeLoopStatus
                        Layout.alignment: Qt.AlignHCenter
                        size: Kirigami.Units.iconSizes.medium - 7
                        // Scale down icon
                        // property real iconScale: 0.65

                        // Choose icon based on loop status
                        // source: player.loopStatus === Mpris.LoopStatus.Track ? iconSources.repeatTrack : player.loopStatus === Mpris.LoopStatus.None ? iconSources.repeatOff : iconSources.repeatAll

                        source: player.loopStatus === Mpris.LoopStatus.Track ? iconSources.repeatTrack : iconSources.repeatAll
                        // iconColor: player.loopStatus !== Mpris.LoopStatus.None ? widget.dominantColor : Kirigami.Theme.textColor

                        /*
                        * If accented buttons is enabled
                        *   if custom color is enabled, use the custom color
                        *   else use the dominant color
                        * else use the default color
                        */
                        iconColor: player.loopStatus !== Mpris.LoopStatus.None ?
                        (plasmoid.configuration.accentedButtons && !plasmoid.configuration.useCustomColor ? widget.dominantColor : plasmoid.configuration.accentColor) : defaultForegroundColor


                        // Default opacity is 0.4 for None, 0.8 for others
                        // property real baseOpacity: player.loopStatus === Mpris.LoopStatus.None ? 0.4 : 0.8

                        // Set opacity based on loop status
                        opacity: player.loopStatus === Mpris.LoopStatus.None ? 0.35 : 1

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }

                        onClicked: () => {
                            let status = Mpris.LoopStatus.None;
                            if (player.loopStatus === Mpris.LoopStatus.None)
                                status = Mpris.LoopStatus.Track;
                            else if (player.loopStatus === Mpris.LoopStatus.Track)
                                status = Mpris.LoopStatus.Playlist;
                            player.setLoopStatus(status);
                        }
                    }
                }
            }
        }
    }
}
