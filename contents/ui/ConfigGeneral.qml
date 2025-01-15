import QtQuick 2.0
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.15
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kcmutils as KCM
import QtQuick.Dialogs as QtDialogs

KCM.SimpleKCM {
    id: configPage

    property bool useCustomColor: false
    property bool progressBarAccentOnHover: true
    property alias cfg_panelIcon: panelIcon.value
    property alias cfg_useAlbumCoverAsPanelIcon: useAlbumCoverAsPanelIcon.checked
    property alias cfg_albumCoverRadius: albumCoverRadius.value
    property alias cfg_commandsInPanel: commandsInPanel.checked
    property alias cfg_maxSongWidthInPanel: maxSongWidthInPanel.value
    property alias cfg_sourceIndex: sourceComboBox.currentIndex
    property alias cfg_sources: sourceComboBox.model
    property alias cfg_textScrollingSpeed: textScrollingSpeed.value
    property alias cfg_separateText: separateText.checked
    property alias cfg_textScrollingBehaviour: scrollingBehaviourRadio.value

    // property alias cfg_useCustomFont: customFontCheckbox.checked
    // property alias cfg_customFont: fontDialog.fontChosen

    property alias cfg_accentedSongName: accentedSongName.checked
    property alias cfg_accentedArtistName: accentedArtistName.checked
    property alias cfg_accentedButtons: accentedButtons.checked
    property alias cfg_accentColor: colorDialog.selectedColor
    property alias cfg_accentedProgressBar: accentedProgressBar.checked
    property alias cfg_progressBarAccentOnHover: configPage.progressBarAccentOnHover
    property alias cfg_useCustomColor: configPage.useCustomColor

    // Mini Player font properties
    property alias cfg_miniPlayerSongNameUseCustomFont: miniPlayerSongNameFontCheckbox.checked
    property alias cfg_miniPlayerSongNameFont: miniPlayerSongNameFontDialog.fontChosen
    property alias cfg_miniPlayerSongNameCapitalize: miniPlayerSongNameCapitalize.checked
    property double cfg_miniPlayerSongNameSpacing: 0.00

    property alias cfg_miniPlayerArtistNameUseCustomFont: miniPlayerArtistNameFontCheckbox.checked
    property alias cfg_miniPlayerArtistNameFont: miniPlayerArtistNameFontDialog.fontChosen
    property alias cfg_miniPlayerArtistNameCapitalize: miniPlayerArtistNameCapitalize.checked
    property double cfg_miniPlayerArtistNameSpacing: 0.00

    // Full Player font properties
    property alias cfg_fullPlayerSongNameUseCustomFont: fullPlayerSongNameFontCheckbox.checked
    property alias cfg_fullPlayerSongNameFont: fullPlayerSongNameFontDialog.fontChosen
    property alias cfg_fullPlayerSongNameCapitalize: fullPlayerSongNameCapitalize.checked
    property double cfg_fullPlayerSongNameSpacing: 0.00

    property alias cfg_fullPlayerArtistNameUseCustomFont: fullPlayerArtistNameFontCheckbox.checked
    property alias cfg_fullPlayerArtistNameFont: fullPlayerArtistNameFontDialog.fontChosen
    property alias cfg_fullPlayerArtistNameCapitalize: fullPlayerArtistNameCapitalize.checked
    property double cfg_fullPlayerArtistNameSpacing: 0.00

    property alias cfg_timerUseCustomFont: timerFontCheckbox.checked
    property alias cfg_timerFont: timerFontDialog.fontChosen
    property alias cfg_timerCapitalize: timerCapitalize.checked
    property double cfg_timerSpacing: 0.00

    // Margin & Spacing properties
    property alias cfg_beforeAlbumCover: beforeAlbumCover.value
    property alias cfg_beforeSongName: beforeSongName.value
    property alias cfg_afterSongName: afterSongName.value
    property alias cfg_afterArtistName: afterArtistName.value
    property alias cfg_beforePlayerControls: beforePlayerControls.value
    property alias cfg_afterPlayerControls: afterPlayerControls.value
    property alias cfg_playerControlsSpacing: playerControlsSpacing.value
    property alias cfg_controlsRowSpacing: controlsRowSpacing.value


    // Audio visualization
    property alias cfg_audioVisualization: audioVisualization.checked

    // Helper function to validate and format spacing input
    function validateSpacing(text) {
        if (text === "") return 0.00
        const num = parseFloat(text)
        return isNaN(num) ? 0.00 : Math.max(-20.00, Math.min(20.00, num))
    }

    Kirigami.FormLayout {
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Panel icon"
        }

        ConfigIcon {
            id: panelIcon
            Kirigami.FormData.label: i18n("Choose icon:")
        }

        CheckBox {
            id: useAlbumCoverAsPanelIcon
            Kirigami.FormData.label: i18n("Album cover:")
            text: i18n("Use album cover as panel icon")
        }

        Label {
            text: i18n("Album cover corner radius:")
            font.weight: Font.DemiBold
            font.pointSize: 10
            opacity: 0.5
            Layout.bottomMargin: -10
            Layout.topMargin: 30
        }

        RowLayout {
            Layout.fillWidth: true

            Slider {
                id: albumCoverRadius
                // Layout.fillWidth: true
                Layout.minimumWidth: 250  // Ensures minimum width for better step visibility
                from: 0
                to: 30
                stepSize: 1
                Kirigami.FormData.label: i18n("Album cover radius:")
            }

            SpinBox {
                id: albumCoverRadiusSpinBox
                from: albumCoverRadius.from
                to: albumCoverRadius.to
                stepSize: albumCoverRadius.stepSize
                value: albumCoverRadius.value
                onValueChanged: albumCoverRadius.value = value
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Sources"
        }

        ComboBox {
            id: sourceComboBox
            editable: true

            onAccepted: () => {
                if (find(editText) === -1)
                    model = [...model, editText]
            }

            Kirigami.FormData.label: i18n("Preferred MPRIS2 source:")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Font settings"
        }

        ColumnLayout {
            id: miniPlayerFontSettings
            spacing: 20

            Label {
                text: "MINI PLAYER"
                font.bold: true
                font.pointSize: 10
                font.letterSpacing: 2
                opacity: 0.5
                Layout.bottomMargin: -10
                Layout.topMargin: 5
            }

            ColumnLayout {
                // spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Label {
                        text: i18n("Song name:")
                        font.weight: Font.ExtraBold
                        opacity: 0.7
                    }

                    Label {
                        visible: miniPlayerSongNameFontCheckbox.checked && miniPlayerSongNameFontDialog.fontChosen
                        text: i18n("%2pt, %3, %1", miniPlayerSongNameFontDialog.fontChosen.family,
                                miniPlayerSongNameFontDialog.fontChosen.pointSize, miniPlayerSongNameFontDialog.fontChosen.styleName)
                        font: Qt.font({
                            family: miniPlayerSongNameFontDialog.fontChosen.family,
                            pointSize: 12
                        })
                    }
                }

                RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    CheckBox {
                        id: miniPlayerSongNameFontCheckbox
                        text: i18n("Use custom font")
                    }

                    Button {
                        text: i18n("Choose font...")
                        icon.name: "settings-configure"
                        enabled: miniPlayerSongNameFontCheckbox.checked
                        onClicked: miniPlayerSongNameFontDialog.open()
                    }

                    Item { Layout.fillWidth: true } // Spacer

                    Label {
                        visible: miniPlayerSongNameFontCheckbox.checked
                        text: i18n("Letter spacing:")
                    }

                    TextField {
                        id: miniPlayerSongNameSpacingField
                        visible: miniPlayerSongNameFontCheckbox.checked
                        text: cfg_miniPlayerSongNameSpacing.toFixed(2)
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        validator: DoubleValidator { bottom: -20; top: 20; decimals: 2 }
                        onTextChanged: {
                            cfg_miniPlayerSongNameSpacing = validateSpacing(text)
                        }
                    }
                }

                CheckBox {
                    id: miniPlayerSongNameCapitalize
                    text: i18n("Capitalize text")
                    enabled: miniPlayerSongNameFontCheckbox.checked
                }
            }

            // Mini Player Artist Name (similar structure)
            ColumnLayout {
                // spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Label {
                        text: i18n("Artist name:")
                        font.weight: Font.ExtraBold
                        opacity: 0.7
                    }

                    Label {
                        visible: miniPlayerArtistNameFontCheckbox.checked && miniPlayerArtistNameFontDialog.fontChosen
                        text: i18n("%2pt, %3, %1", miniPlayerArtistNameFontDialog.fontChosen.family,
                                miniPlayerArtistNameFontDialog.fontChosen.pointSize, miniPlayerArtistNameFontDialog.fontChosen.styleName)
                        font: Qt.font({
                            family: miniPlayerArtistNameFontDialog.fontChosen.family,
                            pointSize: 12
                        })
                    }
                }

                RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    CheckBox {
                        id: miniPlayerArtistNameFontCheckbox
                        text: i18n("Use custom font")
                    }

                    Button {
                        text: i18n("Choose font...")
                        icon.name: "settings-configure"
                        enabled: miniPlayerArtistNameFontCheckbox.checked
                        onClicked: miniPlayerArtistNameFontDialog.open()
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        visible: miniPlayerArtistNameFontCheckbox.checked
                        text: i18n("Letter spacing:")
                    }

                    TextField {
                        id: miniPlayerArtistNameSpacingField
                        visible: miniPlayerArtistNameFontCheckbox.checked
                        text: cfg_miniPlayerArtistNameSpacing.toFixed(2)
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        validator: DoubleValidator { bottom: -20; top: 20; decimals: 2 }
                        onTextChanged: {
                            cfg_miniPlayerArtistNameSpacing = validateSpacing(text)
                        }
                    }
                }

                CheckBox {
                    id: miniPlayerArtistNameCapitalize
                    text: i18n("Capitalize text")
                    enabled: miniPlayerArtistNameFontCheckbox.checked
                }

            }
        }

        // Full Player Font Settings header
        ColumnLayout {
            id: fullPlayerFontSettings
            spacing: 20

            Label {
                text: i18n("FULL PLAYER")
                font.bold: true
                font.pointSize: 10
                font.letterSpacing: 2
                opacity: 0.5
                Layout.bottomMargin: -10
                Layout.topMargin: 30
            }

            ColumnLayout {
                id: fullPlayerSongNameFontSettings
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Label {
                        text: i18n("Song name:")
                        font.weight: Font.ExtraBold
                        opacity: 0.7
                    }

                    Label {
                        visible: fullPlayerSongNameFontCheckbox.checked && fullPlayerSongNameFontDialog.fontChosen
                        text: i18n("%2pt, %3, %1", fullPlayerSongNameFontDialog.fontChosen.family,
                                fullPlayerSongNameFontDialog.fontChosen.pointSize, fullPlayerSongNameFontDialog.fontChosen.styleName)
                        font: Qt.font({
                            family: fullPlayerSongNameFontDialog.fontChosen.family,
                            pointSize: 12
                        })
                    }
                }

                RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    CheckBox {
                        id: fullPlayerSongNameFontCheckbox
                        text: i18n("Use custom font")
                    }

                    Button {
                        text: i18n("Choose font...")
                        icon.name: "settings-configure"
                        enabled: fullPlayerSongNameFontCheckbox.checked
                        onClicked: fullPlayerSongNameFontDialog.open()
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        visible: fullPlayerSongNameFontCheckbox.checked
                        text: i18n("Letter spacing:")
                    }

                    TextField {
                        id: fullPlayerSongNameSpacingField
                        visible: fullPlayerSongNameFontCheckbox.checked
                        text: cfg_fullPlayerSongNameSpacing.toFixed(2)
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        validator: DoubleValidator { bottom: -20; top: 20; decimals: 2 }
                        onTextChanged: {
                            cfg_fullPlayerSongNameSpacing = validateSpacing(text)
                        }
                    }
                }

                CheckBox {
                    id: fullPlayerSongNameCapitalize
                    text: i18n("Capitalize text")
                    enabled: fullPlayerSongNameFontCheckbox.checked
                }
            }

            // Full Player Artist Name
            ColumnLayout {
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Label {
                        text: i18n("Artist name:")
                        font.weight: Font.ExtraBold
                        opacity: 0.7
                    }

                    Label {
                        visible: fullPlayerArtistNameFontCheckbox.checked && fullPlayerArtistNameFontDialog.fontChosen
                        text: i18n("%2pt, %3, %1", fullPlayerArtistNameFontDialog.fontChosen.family,
                                fullPlayerArtistNameFontDialog.fontChosen.pointSize, fullPlayerArtistNameFontDialog.fontChosen.styleName)
                        font: Qt.font({
                            family: fullPlayerArtistNameFontDialog.fontChosen.family,
                            pointSize: 12
                        })
                    }
                }

                RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    CheckBox {
                        id: fullPlayerArtistNameFontCheckbox
                        text: i18n("Use custom font")
                    }

                    Button {
                        text: i18n("Choose font...")
                        icon.name: "settings-configure"
                        enabled: fullPlayerArtistNameFontCheckbox.checked
                        onClicked: fullPlayerArtistNameFontDialog.open()
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        visible: fullPlayerArtistNameFontCheckbox.checked
                        text: i18n("Letter spacing:")
                    }

                    TextField {
                        id: fullPlayerArtistNameSpacingField
                        visible: fullPlayerArtistNameFontCheckbox.checked
                        text: cfg_fullPlayerArtistNameSpacing.toFixed(2)
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        validator: DoubleValidator { bottom: -20; top: 20; decimals: 2 }
                        onTextChanged: {
                            cfg_fullPlayerArtistNameSpacing = validateSpacing(text)
                        }
                    }
                }

                CheckBox {
                    id: fullPlayerArtistNameCapitalize
                    text: i18n("Capitalize text")
                    enabled: fullPlayerArtistNameFontCheckbox.checked
                }
            }

            // Timer Font Settings
            ColumnLayout {
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Label {
                        text: i18n("Time labels:")
                        font.weight: Font.ExtraBold
                        opacity: 0.7
                    }

                    Label {
                        visible: timerFontCheckbox.checked && timerFontDialog.fontChosen
                        text: i18n("%2pt, %3, %1", timerFontDialog.fontChosen.family,
                                timerFontDialog.fontChosen.pointSize, timerFontDialog.fontChosen.styleName)
                        font: Qt.font({
                            family: timerFontDialog.fontChosen.family,
                            pointSize: 12
                        })
                    }
                }

                RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    CheckBox {
                        id: timerFontCheckbox
                        text: i18n("Use custom font")
                    }

                    Button {
                        text: i18n("Choose font...")
                        icon.name: "settings-configure"
                        enabled: timerFontCheckbox.checked
                        onClicked: timerFontDialog.open()
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        visible: timerFontCheckbox.checked
                        text: i18n("Letter spacing:")
                    }

                    TextField {
                        id: timerSpacingField
                        visible: timerFontCheckbox.checked
                        text: cfg_timerSpacing.toFixed(2)
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        validator: DoubleValidator { bottom: -20; top: 20; decimals: 2 }
                        onTextChanged: {
                            cfg_timerSpacing = validateSpacing(text)
                        }
                    }
                }

                CheckBox {
                    id: timerCapitalize
                    text: i18n("Capitalize text")
                    enabled: timerFontCheckbox.checked
                    visible: false
                }
            }
        }


        // Font dialogs remain the same as before
        QtDialogs.FontDialog {
            id: miniPlayerSongNameFontDialog
            title: i18n("Choose Mini Player Song Name Font")
            property font fontChosen: Qt.font({})
            selectedFont: fontChosen  // Initialize with saved font
            onAccepted: { fontChosen = selectedFont }
        }

        QtDialogs.FontDialog {
            id: miniPlayerArtistNameFontDialog
            title: i18n("Choose Mini Player Artist Name Font")
            property font fontChosen: Qt.font({})
            selectedFont: fontChosen
            onAccepted: { fontChosen = selectedFont }
        }

        QtDialogs.FontDialog {
            id: fullPlayerSongNameFontDialog
            title: i18n("Choose Full Player Song Name Font")
            property font fontChosen: Qt.font({})
            selectedFont: fontChosen
            onAccepted: { fontChosen = selectedFont }
        }

        QtDialogs.FontDialog {
            id: fullPlayerArtistNameFontDialog
            title: i18n("Choose Full Player Artist Name Font")
            property font fontChosen: Qt.font({})
            selectedFont: fontChosen
            onAccepted: { fontChosen = selectedFont }
        }

        QtDialogs.FontDialog {
            id: timerFontDialog
            title: i18n("Choose Timer Font")
            property font fontChosen: Qt.font({})
            selectedFont: fontChosen
            onAccepted: { fontChosen = selectedFont }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Accent Colors"
        }

        // Radio button selector for either using the album cover color or a custom color
        RowLayout {
            spacing: 30
            RadioButton {
                // Align the radio button to the top
                Layout.alignment: Qt.AlignTop
                text: i18n("Album cover")
                checked: !cfg_useCustomColor
                onCheckedChanged: {
                    if (checked) {
                        cfg_useCustomColor = false
                    }
                }
            }
            ColumnLayout {
                RadioButton {
                    text: i18n("Custom color")
                    checked: cfg_useCustomColor
                    onCheckedChanged: {
                        if (checked) {
                            cfg_useCustomColor = true
                        }
                    }
                }

                RowLayout {
                    visible: cfg_useCustomColor
                    // Layout.leftMargin: -20
                    // Label {
                    //     text: i18n("Custom accent color:")
                    // }
                    Rectangle {
                        width: 30
                        height: 30
                        color: colorDialog.selectedColor || "#1d99f3"  // Default KDE blue
                        radius: 4
                        border.width: 1
                        border.color: Qt.rgba(0, 0, 0, 0.2)
                        MouseArea {
                            anchors.fill: parent
                            onClicked: colorDialog.open()
                        }
                    }
                    TextField {
                        text: colorDialog.selectedColor.toString()
                        placeholderText: "#RRGGBB"
                        inputMask: "\\#HHHHHH"
                        onTextChanged: {
                            // Only update if it's a valid hex color
                            if (text.match(/#[0-9A-Fa-f]{6}/)) {
                                colorDialog.selectedColor = text
                                cfg_accentColor = text
                            }
                        }
                        Layout.preferredWidth: 100
                    }
                }
            }

            Layout.topMargin: 10
            Layout.bottomMargin: 10
        }

        QtDialogs.ColorDialog {
            id: colorDialog
            title: i18n("Choose accent color")
            selectedColor: cfg_accentColor || "#1d99f3"  // Default KDE blue
            onAccepted: {
                cfg_accentColor = selectedColor
            }
        }

        // Description text
        Label {
            text: i18n("Use the accent color for the following elements:")
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            opacity: 0.5
            Layout.topMargin: 6
            Layout.bottomMargin: 6
        }

        CheckBox {
            id: accentedArtistName
            text: i18n("Artist name")
            // Kirigami.FormData.label: i18n("Album accent color for Artist text:")
        }

        CheckBox {
            id: accentedButtons
            text: i18n("Buttons (Repeat, Shuffle)")
            // Kirigami.FormData.label: i18n("Album accent color for Title text:")
        }

        CheckBox {
            id: accentedSongName
            text: i18n("Song name")
            // Kirigami.FormData.label: i18n("Album accent color for Title text:")
        }

        ColumnLayout {
            // Accent color settings for the progress bar
            CheckBox {
                id: accentedProgressBar
                text: i18n("Progress bar")
                checked: cfg_accentedProgressBar
                onCheckedChanged: {
                    cfg_accentedProgressBar = checked
                    // If accent is disabled, also disable hover mode
                    // if (!checked) {
                    //     cfg_progressBarAccentOnHover = false
                    // }
                }
            }

            // Radio button selector for accent behavior
            RowLayout {
                visible: accentedProgressBar.checked  // Only show when accent is enabled
                spacing: 30
                RadioButton {
                    Layout.alignment: Qt.AlignTop
                    text: i18n("On hover")
                    checked: cfg_progressBarAccentOnHover
                    onCheckedChanged: {
                        if (checked) {
                            cfg_progressBarAccentOnHover = true
                        }
                    }
                }
                ColumnLayout {
                    RadioButton {
                        text: i18n("Always")
                        checked: !cfg_progressBarAccentOnHover
                        onCheckedChanged: {
                            if (checked) {
                                cfg_progressBarAccentOnHover = false
                            }
                        }
                    }
                }

                Layout.topMargin: -5
                Layout.bottomMargin: 10
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Spacing"
        }

        // Description text
        Label {
            text: i18n("Adjust the vertical and horizontal spacing between elements:")
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            opacity: 0.5
            Layout.topMargin: 6
            Layout.bottomMargin: 6
        }

        // SpinBox {
        //     id: beforeAlbumCover
        //     from: -50
        //     to: 100
        //     stepSize: 1
        //     Kirigami.FormData.label: i18n("Before album cover:")
        // }

        ColumnLayout {
            Label {
                text: i18n("Album cover")
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                font.pointSize: 10
                font.letterSpacing: 2
                font.bold: true
                font.capitalization: Font.AllUppercase
                opacity: 0.5
                Layout.topMargin: 6
            }

            spacing: 2

            RowLayout {
                spacing: Kirigami.Units.largeSpacing
                Label {
                    text: i18n("Before album cover:")
                    Layout.minimumWidth: 160
                }
                SpinBox {
                    id: beforeAlbumCover
                    from: -50
                    to: 100
                    stepSize: 1
                }
            }
        }

        // Text block margins
        ColumnLayout {
            Label {
                text: i18n("Text elements")
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                font.pointSize: 10
                font.letterSpacing: 2
                font.bold: true
                font.capitalization: Font.AllUppercase
                opacity: 0.5
                Layout.topMargin: 10
            }
            spacing: 2

            RowLayout {
                spacing: Kirigami.Units.largeSpacing
                Label {
                    text: i18n("Before song name:")
                    Layout.minimumWidth: 160
                }
                SpinBox {
                    id: beforeSongName
                    from: -50
                    to: 100
                    stepSize: 1
                }
            }

            RowLayout {
                spacing: Kirigami.Units.largeSpacing
                Label {
                    text: i18n("After song name:")
                    Layout.minimumWidth: 160
                }
                SpinBox {
                    id: afterSongName
                    from: -50
                    to: 100
                    stepSize: 1
                }
            }

            RowLayout {
                spacing: Kirigami.Units.largeSpacing
                Label {
                    text: i18n("After artist name:")
                    Layout.minimumWidth: 160
                }
                SpinBox {
                    id: afterArtistName
                    from: -50
                    to: 100
                    stepSize: 1
                }
            }
        }

        // Player controls margins
        ColumnLayout {
            Label {
                text: i18n("Player controls")
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                font.pointSize: 10
                font.letterSpacing: 2
                font.bold: true
                font.capitalization: Font.AllUppercase
                opacity: 0.5
                Layout.topMargin: 10
            }
            spacing: 2

            RowLayout {
                spacing: Kirigami.Units.largeSpacing
                Label {
                    text: i18n("Before controls:")
                    Layout.minimumWidth: 160
                }
                SpinBox {
                    id: beforePlayerControls
                    from: -50
                    to: 100
                    stepSize: 1
                }
            }

            RowLayout {
                spacing: Kirigami.Units.largeSpacing
                Label {
                    text: i18n("After controls:")
                    Layout.minimumWidth: 160
                }
                SpinBox {
                    id: afterPlayerControls
                    from: -50
                    to: 100
                    stepSize: 1
                }
            }
        }

        // Player controls row spacing
        ColumnLayout {
            // Kirigami.FormData.label: i18n("Player controls row:")
            Label {
                text: i18n("Horizontal spacing (row):")
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                font.pointSize: 10
                opacity: 0.5
                Layout.topMargin: 6
            }
            // Label {
            //     text: i18n("Adjust the horizontal spacing between player controls")
            //     textFormat: Text.PlainText
            //     wrapMode: Text.WordWrap
            //     opacity: 0.5
            //     font.pointSize: 10
            //     Layout.topMargin: -6
            //     Layout.bottomMargin: 6
            // }


            spacing: 2

            RowLayout {
                spacing: Kirigami.Units.largeSpacing
                Label {
                    text: i18n("Main controls spacing:")
                    Layout.minimumWidth: 160
                }
                SpinBox {
                    id: playerControlsSpacing
                    from: -50
                    to: 100
                    stepSize: 1
                }
            }

            RowLayout {
                spacing: Kirigami.Units.largeSpacing
                Label {
                    text: i18n("Full Row spacing:")
                    Layout.minimumWidth: 160
                }
                SpinBox {
                    id: controlsRowSpacing
                    from: -50
                    to: 100
                    stepSize: 1
                }
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Audio Visualization"
        }

        CheckBox {
            id: audioVisualization
            text: i18n("Enable audio visualization")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Text scrolling"
        }

        SpinBox {
            id: maxSongWidthInPanel
            from: 0
            to: 1000
            Kirigami.FormData.label: i18n("Panel song max width:")
        }

        Slider {
            id: textScrollingSpeed
            from: 1
            to: 10
            stepSize: 1
            Kirigami.FormData.label: i18n("Text scrolling speed:")
        }

        CheckBox {
            id: separateText
            text: i18n("Display title and artist in separate lines")
            Kirigami.FormData.label: i18n("Separate text:")
        }

        ColumnLayout {
            id: scrollingBehaviourRadio
            property int value: ScrollingText.OverflowBehaviour.AlwaysScroll

            Kirigami.FormData.label: i18n("Scrolling behaviour when song text overflows:")
            RadioButton {
                text: i18n("Always scroll")
                checked: scrollingBehaviourRadio.value == ScrollingText.OverflowBehaviour.AlwaysScroll
                onCheckedChanged: () => {
                    if (checked) {
                        scrollingBehaviourRadio.value = ScrollingText.OverflowBehaviour.AlwaysScroll
                    }
                }
            }
            RadioButton {
                text: i18n("Scroll only on mouse over")
                checked: scrollingBehaviourRadio.value == ScrollingText.OverflowBehaviour.ScrollOnMouseOver
                onCheckedChanged: () => {
                    if (checked) {
                        scrollingBehaviourRadio.value = ScrollingText.OverflowBehaviour.ScrollOnMouseOver
                    }
                }
            }
            RadioButton {
                text: i18n("Always scroll except on mouse over")
                checked: scrollingBehaviourRadio.value == ScrollingText.OverflowBehaviour.StopScrollOnMouseOver
                onCheckedChanged: () => {
                    if (checked) {
                        scrollingBehaviourRadio.value = ScrollingText.OverflowBehaviour.StopScrollOnMouseOver
                    }
                }
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Music controls"
        }
        CheckBox {
            id: commandsInPanel
            text: i18n("Show music controls in the panel (play/pause/previous/next)")
            Kirigami.FormData.label: i18n("Show controls:")
        }
    }

    QtDialogs.FontDialog {
        id: fontDialog
        title: i18n("Choose a Font")
        modality: Qt.WindowModal
        parentWindow: configPage.Window.window
        property font fontChosen: Qt.font()
        onAccepted: {
            fontChosen = selectedFont
        }
    }

}
