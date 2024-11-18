import QtQuick 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import 'code/color-thief.min.js' as ColorThief

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
    }

    Mpris.Mpris2Model {
        id: mpris2Source
        readonly property string sourceName: mpris2Source.currentPlayer.identity.toLowerCase()
    }

    QtObject {
        id: iconSources
        readonly property string shuffleOn:  Qt.resolvedUrl("icons/shuffle_on.svg")
        readonly property string shuffleOff: Qt.resolvedUrl("icons/shuffle_off.svg")
        readonly property string repeatTrack:Qt.resolvedUrl("icons/repeat_track.svg")
        readonly property string repeatAll:  Qt.resolvedUrl("icons/repeat_all.svg")
        readonly property string repeatOff:  Qt.resolvedUrl("icons/repeat_off.svg")
        readonly property string play:       Qt.resolvedUrl("icons/play.svg")
        readonly property string pause:      Qt.resolvedUrl("icons/pause.svg")
        readonly property string prev:       Qt.resolvedUrl("icons/prev_track.svg")
        readonly property string next:       Qt.resolvedUrl("icons/next_track.svg")
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
        return Qt.font({
            family: 'Hubot Sans Condensed ExtraBold',
            pixelSize: 28
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
            family: 'Hubot Sans Condensed ExtraBold',
            weight: Font.Black,
            capitalization: Font.AllUppercase,
            pixelSize: 19
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
            id: mouseArea
            anchors.fill: parent
            onClicked: {
                widget.expanded = !widget.expanded;
            }
        }

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
                    icon.name: "arrow-left"
                    implicitWidth: compact.controlsSize
                    implicitHeight: compact.controlsSize
                    onClicked: player.previous()
                }

                PlasmaComponents3.ToolButton {
                    visible: plasmoid.configuration.commandsInPanel
                    enabled: player.playbackStatus === Mpris.PlaybackStatus.Playing ? player.canPause : player.canPlay
                    implicitWidth: compact.controlsSize
                    implicitHeight: compact.controlsSize
                    icon.name: player.playbackStatus === Mpris.PlaybackStatus.Playing ? "currenttrack_pause" : "media-playback-start-symbolic"
                    onClicked: player.playPause()
                }

                PlasmaComponents3.ToolButton {
                    visible: plasmoid.configuration.commandsInPanel
                    enabled: player.canGoNext
                    implicitWidth: compact.controlsSize
                    implicitHeight: compact.controlsSize
                    icon.name: "arrow-right"
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

    // Get the most dominant color from image data
    function getDominantColor(imageData) {
        const colorMap = new Map(); // Store color frequencies
        const data = imageData.data;

        for (let i = 0; i < data.length; i += 4) {
            if (data[i + 3] < 125) continue; // Skip transparent pixels

            // Quantize colors to reduce the number of unique colors
            const r = Math.round(data[i] / 8) * 8;
            const g = Math.round(data[i + 1] / 8) * 8;
            const b = Math.round(data[i + 2] / 8) * 8;

            const key = `${r},${g},${b}`;
            colorMap.set(key, (colorMap.get(key) || 0) + 1);
        }

        // Find the most frequent color
        let maxCount = 0;
        let dominantColor = null;

        for (const [color, count] of colorMap) {
            if (count > maxCount) {
                maxCount = count;
                dominantColor = color.split(',').map(Number);
            }
        }

        return dominantColor; // Returns [r, g, b]
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
                }
            }
        }

        onPaint: {
            if (hiddenImage.status === Image.Ready) {
                var ctx = getContext('2d');
                ctx.drawImage(hiddenImage, 0, 0, width, height);

                // Get image data
                var imageData = ctx.getImageData(0, 0, width, height);

                // Calculate average color first
                var r = 0, g = 0, b = 0;
                var count = 0;
                var data = imageData.data;

                for(var i = 0; i < data.length; i += 4) {
                    if (data[i + 3] >= 125) {
                        r += data[i];
                        g += data[i + 1];
                        b += data[i + 2];
                        count++;
                    }
                }

                if (count > 0) {
                    r = Math.round(r / count);
                    g = Math.round(g / count);
                    b = Math.round(b / count);

                    var avgOklch = rgbToOKLCH(r, g, b);

                    // Decision tree based on average color's chroma
                    if (avgOklch.c > 0.09) { // More than 30% chroma
                        // Use OKLCH chroma technique
                        var adjustedRgb = oklchToRGB(
                            0.75,           // 75% lightness
                            Math.min(0.3, avgOklch.c * 1.2), // Boost chroma but cap it
                            avgOklch.h      // Keep original hue
                        );
                    }
                    else if (avgOklch.c > 0.06) { // 30-49% chroma
                        if (isImageMostlyGray(imageData)) {
                            // Use 60% white
                            widget.dominantColor = Qt.rgba(0.6, 0.6, 0.6, 1.0);
                            return;
                        }
                        // Get and enhance dominant color
                        var dominantRgb = getDominantColor(imageData);
                        var dominantOklch = rgbToOKLCH(dominantRgb[0], dominantRgb[1], dominantRgb[2]);

                        adjustedRgb = oklchToRGB(
                            0.75,          // 75% lightness
                            0.225,         // 75% saturation (0.3 * 0.75)
                            dominantOklch.h // Keep dominant color's hue
                        );
                    }
                    else {
                        // Use average color and saturate
                        adjustedRgb = oklchToRGB(
                            0.75,          // 75% lightness
                            0.225,         // 75% saturation
                            avgOklch.h     // Keep average color's hue
                        );
                    }

                    widget.dominantColor = Qt.rgba(
                        adjustedRgb[0]/255,
                        adjustedRgb[1]/255,
                        adjustedRgb[2]/255,
                        1.0
                    );

                    console.log("Average OKLCH:", avgOklch.l, avgOklch.c, avgOklch.h);
                    console.log("Final color:", adjustedRgb);
                }
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
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(fullRep.width - 10, fullRep.height - 160)
                Layout.preferredHeight: Layout.preferredWidth
                Layout.topMargin: 4
                Layout.bottomMargin: 10
                color: "transparent"

                // Add radius to the Rectangle
                radius: 3  // Adjust this value to control corner roundness

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
                    visible: player.artUrl
                    source: player.artUrl
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
                // font: Qt.font({
                //     // family: widget.boldTextFont.family,
                //     // family: 'Hubot Sans Expanded ExtraBold',
                //     family: 'Hubot Sans Condensed ExtraBold',
                //     // weight: Font.Black,
                //     pixelSize: 28
                // })
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

                // Top margin to add some space between the title and the artist
                Layout.topMargin: -5
                Layout.bottomMargin:3
            }

            ScrollingText {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(imageContainer.width, maxWidth)

                speed: plasmoid.configuration.textScrollingSpeed
                // font: Qt.font({
                //     // family: 'Hubot Sans Condensed',
                //     family: 'Hubot Sans Condensed ExtraBold',
                //     weight: Font.Black,
                //     capitalization: Font.AllUppercase,
                //     pixelSize: 19,
                //     // letterSpacing: 0.5
                // })
                font: widget.fullPlayerArtistNameFont
                maxWidth: imageContainer.width
                text: player.artists
                opacity: 0.8

                /*
                * If accented artist name is enabled
                *   if custom color is enabled, use the custom color
                *   else use the dominant color
                * else use the default color
                */
                textColor: plasmoid.configuration.accentedArtistName ? (plasmoid.configuration.useCustomColor ? plasmoid.configuration.accentColor : widget.dominantColor) : '#A8FFFFFF'

                Layout.topMargin: -10
                Layout.bottomMargin: -3

                Connections {
                    target: widget
                    function onDominantColorChanged() {
                        console.log("Dominant color updated in ScrollingText:", widget.dominantColor);
                    }
                }
            }


            TrackPositionSlider {
                // Layout.leftMargin: 6
                // Layout.rightMargin: 6
                Layout.preferredWidth: imageContainer.width
                Layout.alignment: Qt.AlignHCenter

                // Customize appearance
                trackColor: "#30FFFFFF"
                handleColor: "#FFFFFF"
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
                id: playerControlsContainer

                // Set a fixed width instead of relative width
                Layout.preferredWidth: Kirigami.Units.gridUnit * 16 // Adjust this value as needed
                Layout.preferredHeight: playerControls.implicitHeight
                Layout.topMargin: 10
                Layout.bottomMargin: 25
                Layout.alignment: Qt.AlignHCenter


                RowLayout {
                    id: playerControls
                    spacing: 27

                    // Center the row within the container
                    anchors.centerIn: parent
                    // Don't fill the width to keep buttons centered
                    width: implicitWidth

                    CommandIcon {
                        enabled: player.canChangeShuffle
                        Layout.alignment: Qt.AlignHCenter
                        size: Kirigami.Units.iconSizes.medium - 12
                        source: player.shuffle === Mpris.ShuffleStatus.On ? iconSources.shuffleOn : iconSources.shuffleOff
                        onClicked: player.setShuffle(player.shuffle === Mpris.ShuffleStatus.Off ? Mpris.ShuffleStatus.On : Mpris.ShuffleStatus.Off)
                        active: player.shuffle === Mpris.ShuffleStatus.On
                        // iconColor: player.shuffle === Mpris.ShuffleStatus.On ? widget.dominantColor : Kirigami.Theme.textColor

                        /*
                        * If accented buttons is enabled
                        *   if custom color is enabled, use the custom color
                        *   else use the dominant color
                        * else use the default color
                        */
                        iconColor: player.shuffle === Mpris.ShuffleStatus.On ?
                        (plasmoid.configuration.accentedButtons && !plasmoid.configuration.useCustomColor ? widget.dominantColor : plasmoid.configuration.accentColor) : defaultForegroundColor
                    }

                    CommandIcon {
                        enabled: player.canGoPrevious
                        Layout.alignment: Qt.AlignHCenter
                        size: Kirigami.Units.iconSizes.medium - 6
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
                        size: Kirigami.Units.iconSizes.large
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
                        size: Kirigami.Units.iconSizes.medium - 6
                        // source: "player_next"
                        source: iconSources.next
                        onClicked: {
                            player.next()
                            // Call forceUpdateScroll() from the ScrollingText.qml
                            titleText.forceUpdateScroll()
                            artistText.forceUpdateScroll()
                        }
                    }

                    CommandIcon {
                        id: repeatButton
                        enabled: player.canChangeLoopStatus
                        Layout.alignment: Qt.AlignHCenter
                        size: Kirigami.Units.iconSizes.medium - 12

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

                        // Use the base opacity unless hovered
                        // opacity: hovered ? 1.0 : 0.7

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
