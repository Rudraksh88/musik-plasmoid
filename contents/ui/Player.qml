import QtQuick 2.15
import QtQml.Models 2.3
import org.kde.plasma.private.mpris as Mpris

QtObject {
    id: root

    property var mpris2Model: Mpris.Mpris2Model {
        onRowsInserted: (_, rowIndex) => {
            selectPlayerSource(rowIndex);
        }

        // Use rowsChanged signal instead of sourcesChanged
        onRowsRemoved: () => {
            // When players are removed, also check what's still available
            initTimer.restart();
        }

        // We can also check when the model data changes
        onDataChanged: () => {
            checkPlayingPlayers();
        }
    }

    property string sourceName: "any"
    property bool prioritizePlayingSource: true // New property to control priority behavior

    readonly property bool ready: {
        if (!mpris2Model.currentPlayer) {
            return false
        }
        return mpris2Model.currentPlayer.desktopEntry === sourceName || sourceName === "any";
    }

    // Initialization timer to select active source after shell restart
    property var initTimer: Timer {
        id: initTimer
        interval: 1000
        running: true
        repeat: false
        onTriggered: {
            selectActiveSource();
        }
    }

    // Timer to periodically check for playing sources (can be adjusted or disabled)
    property var checkTimer: Timer {
        interval: 5000
        running: prioritizePlayingSource
        repeat: true
        onTriggered: {
            checkPlayingPlayers();
        }
    }

    // Check if any players have started playing
    function checkPlayingPlayers() {
        if (!prioritizePlayingSource) return;

        // Only look for playing sources if we don't already have one
        if (ready && mpris2Model.currentPlayer &&
            mpris2Model.currentPlayer.playbackStatus === Mpris.PlaybackStatus.Playing) {
            return; // Already have a playing source selected
        }

        // Otherwise scan for any playing sources
        selectActiveSource();
    }

    // Function to select a player when a new source is added
    function selectPlayerSource(rowIndex) {
        const CONTAINER_ROLE = Qt.UserRole + 1
        const player = mpris2Model.data(mpris2Model.index(rowIndex, 0), CONTAINER_ROLE)

        // If this is the configured source, use it
        if (player.desktopEntry === root.sourceName) {
            mpris2Model.currentIndex = rowIndex;
            return;
        }

        // If we're prioritizing playing sources and this one is playing
        if (prioritizePlayingSource && player.playbackStatus === Mpris.PlaybackStatus.Playing) {
            // Check if we should override the current selection
            let shouldOverride = false;

            // If no source is selected yet or "any" is selected
            if (sourceName === "any") {
                shouldOverride = true;
            }
            // If current player is not playing but this one is
            else if (mpris2Model.currentPlayer &&
                    mpris2Model.currentPlayer.playbackStatus !== Mpris.PlaybackStatus.Playing) {
                shouldOverride = true;
            }

            if (shouldOverride) {
                console.log("Selecting active player:", player.desktopEntry);
                mpris2Model.currentIndex = rowIndex;
                // Update the source name to the playing source
                sourceName = player.desktopEntry;
            }
        }
    }

    // Function to scan all sources and find any actively playing source
    function selectActiveSource() {
        if (!prioritizePlayingSource || mpris2Model.rowCount() === 0) return;

        // First pass: look for playing sources
        for (let i = 0; i < mpris2Model.rowCount(); i++) {
            const CONTAINER_ROLE = Qt.UserRole + 1
            const player = mpris2Model.data(mpris2Model.index(i, 0), CONTAINER_ROLE)

            if (player.playbackStatus === Mpris.PlaybackStatus.Playing) {
                console.log("Found playing source:", player.desktopEntry);
                mpris2Model.currentIndex = i;
                // Update the source name to the playing source
                sourceName = player.desktopEntry;
                return;
            }
        }

        // Second pass: if no playing source, try to find the configured source
        if (sourceName !== "any") {
            for (let i = 0; i < mpris2Model.rowCount(); i++) {
                const CONTAINER_ROLE = Qt.UserRole + 1
                const player = mpris2Model.data(mpris2Model.index(i, 0), CONTAINER_ROLE)

                if (player.desktopEntry === sourceName) {
                    console.log("Using configured source:", player.desktopEntry);
                    mpris2Model.currentIndex = i;
                    return;
                }
            }
        }

        // Last resort: if we're using "any" and no playing source was found, use the first source
        if (sourceName === "any" && mpris2Model.rowCount() > 0) {
            console.log("Using first available source");
            mpris2Model.currentIndex = 0;
        }
    }

    readonly property string artists: ready ? mpris2Model.currentPlayer.artist : ""
    readonly property string title: ready ? mpris2Model.currentPlayer.track : ""
    readonly property int playbackStatus: ready ? mpris2Model.currentPlayer.playbackStatus : Mpris.PlaybackStatus.Unknown
    readonly property int shuffle: ready ? mpris2Model.currentPlayer.shuffle : Mpris.ShuffleStatus.Unknown
    readonly property string artUrl: ready ? mpris2Model.currentPlayer.artUrl : ""
    readonly property int loopStatus: ready ? mpris2Model.currentPlayer.loopStatus : Mpris.LoopStatus.Unknown
    readonly property double songPosition: ready ? mpris2Model.currentPlayer.position : 0
    readonly property double songLength: ready ? mpris2Model.currentPlayer.length : 0
    readonly property real volume: ready ? mpris2Model.currentPlayer.volume : 0

    readonly property bool canGoNext: ready ? mpris2Model.currentPlayer.canGoNext : false
    readonly property bool canGoPrevious: ready ? mpris2Model.currentPlayer.canGoPrevious : false
    readonly property bool canPlay: ready ? mpris2Model.currentPlayer.canPlay : false
    readonly property bool canPause: ready ? mpris2Model.currentPlayer.canPause : false
    readonly property bool canSeek: ready ? mpris2Model.currentPlayer.canSeek : false

    // To know whether Shuffle and Loop can be changed we have to check if the property is defined,
    // unlike the other commands, LoopStatus and Shuffle hasn't a specific propety such as
    // CanPause, CanSeek, etc.
    readonly property bool canChangeShuffle: ready ? mpris2Model.currentPlayer.shuffle != undefined : false
    readonly property bool canChangeLoopStatus: ready ? mpris2Model.currentPlayer.loopStatus != undefined : false

    function playPause() {
        mpris2Model.currentPlayer?.PlayPause();
    }

    function setPosition(position) {
        mpris2Model.currentPlayer.position = position;
    }

    function next() {
        mpris2Model.currentPlayer?.Next();
    }

    function previous() {
        mpris2Model.currentPlayer?.Previous();
    }

    function updatePosition() {
        mpris2Model.currentPlayer?.updatePosition();
    }

    function setVolume(volume) {
        mpris2Model.currentPlayer.volume = volume
    }

    function setShuffle(shuffle) {
        mpris2Model.currentPlayer.shuffle = shuffle
    }

    function setLoopStatus(loopStatus) {
        mpris2Model.currentPlayer.loopStatus = loopStatus
    }
}