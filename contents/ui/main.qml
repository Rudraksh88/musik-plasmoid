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

    property color dominantColor: "#A8FFFFFF"  // Default color

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
                        font: Qt.font({
                            family: widget.boldTextFont.family,
                            weight: Font.Bold,
                            pixelSize: 12
                        })
                        speed: plasmoid.configuration.textScrollingSpeed
                        maxWidth: plasmoid.configuration.maxSongWidthInPanel
                        text: player.title

                        // Align to the left
                        Layout.alignment: Qt.AlignLeft
                    }
                    ScrollingText {
                        overflowBehaviour: plasmoid.configuration.textScrollingBehaviour
                        font: Qt.font({
                            family: widget.textFont.family,
                            pixelSize: 7
                        })
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
                font: widget.textFont
                // Align to the left
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: 5 // Some spacing to the left of the text
                Layout.rightMargin: -5 // Some spacing to the right of the text
            }

            // PlasmaComponents3.ToolButton {
            //     visible: plasmoid.configuration.commandsInPanel
            //     enabled: player.canGoPrevious
            //     icon.name: "gtk-go-forward-rtl"
            //     implicitWidth: compact.controlsSize
            //     implicitHeight: compact.controlsSize
            //     onClicked: player.previous()
            // }

            // PlasmaComponents3.ToolButton {
            //     visible: plasmoid.configuration.commandsInPanel
            //     enabled: player.playbackStatus === Mpris.PlaybackStatus.Playing ? player.canPause : player.canPlay
            //     implicitWidth: compact.controlsSize
            //     implicitHeight: compact.controlsSize
            //     icon.name: player.playbackStatus === Mpris.PlaybackStatus.Playing ? "currenttrack_pause" : "media-playback-start-symbolic"
            //     onClicked: player.playPause()
            // }

            // PlasmaComponents3.ToolButton {
            //     visible: plasmoid.configuration.commandsInPanel
            //     enabled: player.canGoNext
            //     implicitWidth: compact.controlsSize
            //     implicitHeight: compact.controlsSize
            //     icon.name: "gtk-go-forward-ltr"
            //     onClicked: player.next()

            //     // Reduce left margin to make the button closer to the previous button
            //     // Layout.leftMargin: -2
            //     Layout.rightMargin: 4
            // }

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

    // // Create a hidden canvas for color extraction
    // Canvas {
    //     id: hiddenCanvas
    //     visible: false
    //     width: 1
    //     height: 1

    //     // Create a hidden image for loading
    //     Image {
    //         id: hiddenImage
    //         visible: false
    //         width: 1
    //         height: 1

    //         onStatusChanged: {
    //             if (status === Image.Ready) {
    //                 // Once image is loaded, draw it to canvas and extract color
    //                 hiddenCanvas.requestPaint();
    //             }
    //         }
    //     }

    //     onPaint: {
    //         if (hiddenImage.status === Image.Ready) {
    //             var ctx = getContext('2d');
    //             ctx.drawImage(hiddenImage, 0, 0);

    //             // Get image data and extract dominant color
    //             var imageData = ctx.getImageData(0, 0, 1, 1);
    //             var r = imageData.data[0];
    //             var g = imageData.data[1];
    //             var b = imageData.data[2];

    //             // Update dominant color
    //             widget.dominantColor = Qt.rgba(r/255, g/255, b/255, 1.0);
    //             console.log("Extracted color:", widget.dominantColor);
    //         }
    //     }
    // }

    // Add a function to extract dominant color
    function extractDominantColor(imageUrl) {
        if (!imageUrl) return;

        var img = new Image();
        img.crossOrigin = "Anonymous";

        img.onLoad = function() {
            var colorThief = new ColorThief.ColorThief();
            var color = colorThief.getColor(img);
            if (color) {
                // Convert RGB array to color string
                widget.dominantColor = Qt.rgba(color[0]/255, color[1]/255, color[2]/255, 1.0);
            }
        }

        img.source = imageUrl;
    }

    // Convert RGB to HSL
    function rgbToHsl(r, g, b) {
        r /= 255;
        g /= 255;
        b /= 255;

        var max = Math.max(r, g, b);
        var min = Math.min(r, g, b);
        var h, s, l = (max + min) / 2;

        if (max === min) {
            h = s = 0;
        } else {
            var d = max - min;
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min);

            switch (max) {
                case r: h = (g - b) / d + (g < b ? 6 : 0); break;
                case g: h = (b - r) / d + 2; break;
                case b: h = (r - g) / d + 4; break;
            }
            h /= 6;
        }

        return [h * 360, s * 100, l * 100];
    }

    // Convert HSL to RGB
    function hslToRgb(h, s, l) {
        h /= 360;
        s /= 100;
        l /= 100;

        var r, g, b;

        function hue2rgb(p, q, t) {
            if (t < 0) t += 1;
            if (t > 1) t -= 1;
            if (t < 1/6) return p + (q - p) * 6 * t;
            if (t < 1/2) return q;
            if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
            return p;
        }

        if (s === 0) {
            r = g = b = l;
        } else {
            var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
            var p = 2 * l - q;
            r = hue2rgb(p, q, h + 1/3);
            g = hue2rgb(p, q, h);
            b = hue2rgb(p, q, h - 1/3);
        }

        return [Math.round(r * 255), Math.round(g * 255), Math.round(b * 255)];
    }

    // Create a hidden canvas for color extraction
    Canvas {
        id: hiddenCanvas
        visible: false
        width: 50
        height: 50

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
                var data = imageData.data;

                // Calculate average color
                var r = 0, g = 0, b = 0;
                var count = 0;

                for(var i = 0; i < data.length; i += 4) {
                    var alpha = data[i + 3];
                    if (alpha >= 125) {  // Only consider non-transparent pixels
                        r += data[i];
                        g += data[i + 1];
                        b += data[i + 2];
                        count++;
                    }
                }

                if (count > 0) {
                    // Get average color
                    r = Math.round(r / count);
                    g = Math.round(g / count);
                    b = Math.round(b / count);

                    // Convert to HSL, adjust saturation and lightness, then back to RGB
                    var hsl = rgbToHsl(r, g, b);
                    var adjustedRgb = hslToRgb(
                        hsl[0],    // Keep original hue
                        80,       // Set saturation to exactly 100%
                        70         // Set lightness to exactly 60%
                    );

                    // Update the dominant color
                    widget.dominantColor = Qt.rgba(
                        adjustedRgb[0]/255,
                        adjustedRgb[1]/255,
                        adjustedRgb[2]/255,
                        1.0
                    );

                    console.log("Average color HSL:", hsl[0], 100, 60);
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

            // Rectangle {
            //     id: imageContainer
            //     Layout.alignment: Qt.AlignHCenter
            //     Layout.preferredWidth: Math.min(fullRep.width - 10, fullRep.height - 160)  // Subtract space for other elements
            //     Layout.preferredHeight: Layout.preferredWidth
            //     Layout.topMargin: 5
            //     color: "transparent"

            //     Image {
            //         anchors.fill: parent
            //         visible: player.artUrl
            //         source: player.artUrl
            //         fillMode: Image.PreserveAspectFit
            //     }

            //     Layout.bottomMargin: 12
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
                font: Qt.font({
                    // family: widget.boldTextFont.family,
                    family: 'Spotify Mix',
                    weight: Font.Bold,
                    pixelSize: 22
                })
                maxWidth: imageContainer.width
                text: player.title

                // Top margin to add some space between the title and the artist
                // Layout.topMargin: 7
            }

            ScrollingText {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(imageContainer.width, maxWidth)

                speed: plasmoid.configuration.textScrollingSpeed
                font: Qt.font({
                    family: 'Spotify Mix',
                    pixelSize: 16,
                })
                maxWidth: imageContainer.width
                text: player.artists
                opacity: 0.8
                textColor: widget.dominantColor  // Use the extracted color

                Layout.topMargin: -10
                Layout.bottomMargin: 12

                Connections {
                    target: widget
                    function onDominantColorChanged() {
                        console.log("Dominant color updated in ScrollingText:", widget.dominantColor);
                    }
                }
            }

            // VolumeBar {
            //     Layout.preferredWidth: imageContainer.width
            //     Layout.alignment: Qt.AlignHCenter

            //     Layout.leftMargin: 40
            //     Layout.rightMargin: 40
            //     Layout.topMargin: 20
            //     volume: player.volume
            //     onChangeVolume: (player_endvol) => {
            //         player.setVolume(vol)
            //     }
            // }

            TrackPositionSlider {
                Layout.leftMargin: 12
                Layout.rightMargin: 12

                Layout.preferredWidth: imageContainer.width
                Layout.alignment: Qt.AlignHCenter

                songPosition: player.songPosition
                songLength: player.songLength
                playing: player.playbackStatus === Mpris.PlaybackStatus.Playing
                enableChangePosition: player.canSeek
                onRequireChangePosition: (position) => {
                    player.setPosition(position)
                }
                onRequireUpdatePosition: () => {
                    player.updatePosition()
                }
            }

            Item {
                id: playerControlsContainer

                // Layout.preferredWidth: imageContainer.width * 0.5
                // Layout.preferredHeight: row.implicitHeight
                // Layout.topMargin: 10
                // // Layout.leftMargin: 30
                // // Layout.rightMargin: 30
                // Layout.bottomMargin: 70
                // Layout.alignment: Qt.AlignHCenter

                // Set a fixed width instead of relative width
                Layout.preferredWidth: Kirigami.Units.gridUnit * 16 // Adjust this value as needed
                Layout.preferredHeight: playerControls.implicitHeight
                Layout.topMargin: 10
                Layout.bottomMargin: 25
                Layout.alignment: Qt.AlignHCenter



                // RowLayout {
                //     id: row

                //     spacing: -300

                //     anchors.fill: parent

                //     CommandIcon {
                //         enabled: player.canChangeShuffle
                //         Layout.alignment: Qt.AlignHCenter
                //         size: Kirigami.Units.iconSizes.medium - 6
                //         source: "/home/rtx/.local/share/plasma/plasmoids/plasmusic-toolbar/contents/ui/shuffle.svg"
                //         onClicked: player.setShuffle(player.shuffle === Mpris.ShuffleStatus.Off ? Mpris.ShuffleStatus.On : Mpris.ShuffleStatus.Off)
                //         active: player.shuffle === Mpris.ShuffleStatus.On
                //     }

                //     RowLayout {
                //         id: playerControls
                //         spacing: 25
                //         Layout.alignment: Qt.AlignHCenter


                //         CommandIcon {
                //             enabled: player.canGoPrevious
                //             Layout.alignment: Qt.AlignHCenter
                //             size: Kirigami.Units.iconSizes.medium - 6
                //             source: "player_prev"
                //             onClicked: {
                //                 player.previous()
                //                 // Call forceUpdateScroll() from the ScrollingText.qml
                //                 titleText.forceUpdateScroll()
                //                 artistText.forceUpdateScroll()
                //             }
                //         }

                //         CommandIcon {
                //             enabled: player.playbackStatus === Mpris.PlaybackStatus.Playing ? player.canPause : player.canPlay
                //             Layout.alignment: Qt.AlignHCenter
                //             size: Kirigami.Units.iconSizes.large
                //             source: player.playbackStatus === Mpris.PlaybackStatus.Playing ? "/home/rtx/.local/share/plasma/plasmoids/plasmusic-toolbar/contents/ui/Pause.svg" : "/home/rtx/.local/share/plasma/plasmoids/plasmusic-toolbar/contents/ui/Play.svg"
                //             onClicked: {
                //                 player.playPause()
                //                 titleText.forceUpdateScroll()
                //                 artistText.forceUpdateScroll()
                //             }
                //         }

                //         CommandIcon {
                //             enabled: player.canGoNext
                //             Layout.alignment: Qt.AlignHCenter
                //             size: Kirigami.Units.iconSizes.medium - 6
                //             source: "player_next"
                //             onClicked: {
                //                 player.next()
                //                 // Call forceUpdateScroll() from the ScrollingText.qml
                //                 titleText.forceUpdateScroll()
                //                 artistText.forceUpdateScroll()
                //             }
                //         }
                //     }

                //     CommandIcon {
                //         enabled: player.canChangeLoopStatus
                //         Layout.alignment: Qt.AlignHCenter
                //         size: Kirigami.Units.iconSizes.medium - 6
                //         source: player.loopStatus === Mpris.LoopStatus.Track ? "media-playlist-repeat-song" : "media-playlist-repeat"
                //         active: player.loopStatus != Mpris.LoopStatus.None
                //         onClicked: () => {
                //             let status = Mpris.LoopStatus.None;
                //             if (player.loopStatus == Mpris.LoopStatus.None)
                //                 status = Mpris.LoopStatus.Track;
                //             else if (player.loopStatus === Mpris.LoopStatus.Track)
                //                 status = Mpris.LoopStatus.Playlist;
                //             player.setLoopStatus(status);
                //         }
                //     }

                // }

                RowLayout {
                    id: playerControls
                    spacing: 22

                    // Layout.alignment: Qt.AlignHCenter
                    // anchors.fill: parent
                    // Layout.fillWidth: false

                    // Center the row within the container
                    anchors.centerIn: parent
                    // Don't fill the width to keep buttons centered
                    width: implicitWidth




                    CommandIcon {
                        enabled: player.canChangeShuffle
                        Layout.alignment: Qt.AlignHCenter
                        size: Kirigami.Units.iconSizes.medium - 12
                        source: player.shuffle === Mpris.ShuffleStatus.On ? "/home/rtx/.local/share/plasma/plasmoids/plasmusic-toolbar/contents/ui/arrows-shuffle.svg" : "/home/rtx/.local/share/plasma/plasmoids/plasmusic-toolbar/contents/ui/arrows-right.svg"
                        onClicked: player.setShuffle(player.shuffle === Mpris.ShuffleStatus.Off ? Mpris.ShuffleStatus.On : Mpris.ShuffleStatus.Off)
                        active: player.shuffle === Mpris.ShuffleStatus.On
                    }

                    CommandIcon {
                        enabled: player.canGoPrevious
                        Layout.alignment: Qt.AlignHCenter
                        size: Kirigami.Units.iconSizes.medium - 6
                        // source: "player_prev"
                        source: "/home/rtx/.local/share/plasma/plasmoids/plasmusic-toolbar/contents/ui/player-track-prev.svg"
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
                        source: player.playbackStatus === Mpris.PlaybackStatus.Playing ? "/home/rtx/.local/share/plasma/plasmoids/plasmusic-toolbar/contents/ui/Pause.svg" : "/home/rtx/.local/share/plasma/plasmoids/plasmusic-toolbar/contents/ui/Play.svg"

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
                        source: "/home/rtx/.local/share/plasma/plasmoids/plasmusic-toolbar/contents/ui/player-track-next.svg"
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
                        source: player.loopStatus === Mpris.LoopStatus.Track ?
                            "/home/rtx/.local/share/plasma/plasmoids/plasmusic-toolbar/contents/ui/repeat-once.svg" :
                            player.loopStatus === Mpris.LoopStatus.None ? "/home/rtx/.local/share/plasma/plasmoids/plasmusic-toolbar/contents/ui/rep-off.svg" : "/home/rtx/.local/share/plasma/plasmoids/plasmusic-toolbar/contents/ui/rep_all.svg"


                        // Default opacity is 0.4 for None, 0.8 for others
                        // property real baseOpacity: player.loopStatus === Mpris.LoopStatus.None ? 0.4 : 0.8

                        // Use the base opacity unless hovered
                        opacity: hovered ? 1.0 : 0.7

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
