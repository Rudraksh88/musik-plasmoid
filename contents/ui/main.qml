import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris

PlasmoidItem {
    id: widget

    Plasmoid.status: PlasmaCore.Types.HiddenStatus

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

    compactRepresentation: Item {
        id: compact

        // Layout.preferredWidth: row.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: row.implicitWidth + Kirigami.Units.largeSpacing * 2
        Layout.fillHeight: true

        readonly property real controlsSize: Math.min(height, Kirigami.Units.iconSizes.medium)

        MouseArea {
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
            }


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

            PlasmaComponents3.ToolButton {
                visible: plasmoid.configuration.commandsInPanel
                enabled: player.canGoPrevious
                icon.name: "gtk-go-forward-rtl"
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
                icon.name: "gtk-go-forward-ltr"
                onClicked: player.next()

                // Reduce left margin to make the button closer to the previous button
                Layout.leftMargin: -2
                Layout.rightMargin: 4
            }
        }
    }

    fullRepresentation: Item {
        id: fullRep
        Layout.preferredWidth: Math.max(300, imageContainer.width + 40)  // Minimum width of 300
        Layout.preferredHeight: column.implicitHeight
        Layout.minimumWidth: 300
        Layout.minimumHeight: 300

        ColumnLayout {
            id: column

            // spacing: 0
            anchors.fill: parent
            spacing: Kirigami.Units.largeSpacing

            Rectangle {
                id: imageContainer
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(fullRep.width - 40, fullRep.height - 160)  // Subtract space for other elements
                Layout.preferredHeight: Layout.preferredWidth
                Layout.topMargin: Kirigami.Units.largeSpacing
                color: "transparent"

                Image {
                    anchors.fill: parent
                    visible: player.artUrl
                    source: player.artUrl
                    fillMode: Image.PreserveAspectFit
                }
            }

            TrackPositionSlider {
                Layout.leftMargin: 20
                Layout.rightMargin: 20

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

            ScrollingText {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(imageContainer.width, maxWidth)
                horizontalAlignment: Text.AlignHCenter

                speed: plasmoid.configuration.textScrollingSpeed
                font: Qt.font({
                    family: widget.boldTextFont.family,
                    weight: Font.Bold,
                    pixelSize: 22
                })
                maxWidth: imageContainer.width
                text: player.title
            }

            ScrollingText {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(imageContainer.width, maxWidth)
                horizontalAlignment: Text.AlignHCenter

                speed: plasmoid.configuration.textScrollingSpeed
                font: Qt.font({
                    family: widget.textFont.family,
                    pixelSize: 15
                })
                maxWidth: imageContainer.width
                text: player.artists
            }

            VolumeBar {
                Layout.preferredWidth: imageContainer.width
                Layout.alignment: Qt.AlignHCenter

                Layout.leftMargin: 40
                Layout.rightMargin: 40
                Layout.topMargin: 10
                volume: player.volume
                onChangeVolume: (vol) => {
                    player.setVolume(vol)
                }
            }

            Item {
                Layout.preferredWidth: imageContainer.width
                Layout.preferredHeight: row.implicitHeight
                Layout.alignment: Qt.AlignHCenter

                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.bottomMargin: 10
                Layout.fillWidth: true
                RowLayout {
                    id: row

                    anchors.fill: parent

                    CommandIcon {
                        enabled: player.canChangeShuffle
                        Layout.alignment: Qt.AlignHCenter
                        size: Kirigami.Units.iconSizes.medium
                        source: "media-playlist-shuffle"
                        onClicked: player.setShuffle(player.shuffle === Mpris.ShuffleStatus.Off ? Mpris.ShuffleStatus.On : Mpris.ShuffleStatus.Off)
                        active: player.shuffle === Mpris.ShuffleStatus.On
                    }

                    CommandIcon {
                        enabled: player.canGoPrevious
                        Layout.alignment: Qt.AlignHCenter
                        size: Kirigami.Units.iconSizes.medium
                        source: "media-skip-backward"
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
                        source: player.playbackStatus === Mpris.PlaybackStatus.Playing ? "currenttrack_pause" : "currenttrack_play"
                        onClicked: {
                            player.playPause()
                            titleText.forceUpdateScroll()
                            artistText.forceUpdateScroll()
                        }
                    }

                    CommandIcon {
                        enabled: player.canGoNext
                        Layout.alignment: Qt.AlignHCenter
                        size: Kirigami.Units.iconSizes.medium
                        source: "media-skip-forward"
                        onClicked: {
                            player.next()
                            // Call forceUpdateScroll() from the ScrollingText.qml
                            titleText.forceUpdateScroll()
                            artistText.forceUpdateScroll()
                        }
                    }

                    CommandIcon {
                        enabled: player.canChangeLoopStatus
                        Layout.alignment: Qt.AlignHCenter
                        size: Kirigami.Units.iconSizes.medium
                        source: player.loopStatus === Mpris.LoopStatus.Track ? "media-playlist-repeat-song" : "media-playlist-repeat"
                        active: player.loopStatus != Mpris.LoopStatus.None
                        onClicked: () => {
                            let status = Mpris.LoopStatus.None;
                            if (player.loopStatus == Mpris.LoopStatus.None)
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
