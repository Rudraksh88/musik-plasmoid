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
    property alias cfg_miniPlayerSongNameSpacing: miniPlayerSongNameSpacing.value

    property alias cfg_miniPlayerArtistNameUseCustomFont: miniPlayerArtistNameFontCheckbox.checked
    property alias cfg_miniPlayerArtistNameFont: miniPlayerArtistNameFontDialog.fontChosen
    property alias cfg_miniPlayerArtistNameSpacing: miniPlayerArtistNameSpacing.value

    // Full Player font properties
    property alias cfg_fullPlayerSongNameUseCustomFont: fullPlayerSongNameFontCheckbox.checked
    property alias cfg_fullPlayerSongNameFont: fullPlayerSongNameFontDialog.fontChosen
    property alias cfg_fullPlayerSongNameSpacing: fullPlayerSongNameSpacing.value

    property alias cfg_fullPlayerArtistNameUseCustomFont: fullPlayerArtistNameFontCheckbox.checked
    property alias cfg_fullPlayerArtistNameFont: fullPlayerArtistNameFontDialog.fontChosen
    property alias cfg_fullPlayerArtistNameSpacing: fullPlayerArtistNameSpacing.value

    property alias cfg_timerUseCustomFont: timerFontCheckbox.checked
    property alias cfg_timerFont: timerFontDialog.fontChosen
    property alias cfg_timerSpacing: timerSpacing.value

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

        Slider {
            id: albumCoverRadius
            from: 0
            to: 25
            stepSize: 2
            Kirigami.FormData.label: i18n("Album cover radius:")
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

        Label {
            text: i18n("Mini Player")
            font.bold: true
            Layout.topMargin: Kirigami.Units.largeSpacing
        }

        // Mini Player Song Name
        ColumnLayout {
            Kirigami.FormData.label: i18n("Song name:")
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
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

                Label {
                    visible: miniPlayerSongNameFontCheckbox.checked
                    text: i18n("Letter spacing:")
                }

                SpinBox {
                    id: miniPlayerSongNameSpacing
                    visible: miniPlayerSongNameFontCheckbox.checked
                    from: -5
                    to: 20
                    stepSize: 1
                }
            }

            Label {
                visible: miniPlayerSongNameFontCheckbox.checked && miniPlayerSongNameFontDialog.fontChosen
                text: i18n("Selected font: %1 %2pt", miniPlayerSongNameFontDialog.fontChosen.family,
                          miniPlayerSongNameFontDialog.fontChosen.pointSize)
                font: miniPlayerSongNameFontDialog.fontChosen
            }
        }

        // Mini Player Artist Name (similar structure)
        ColumnLayout {
            Kirigami.FormData.label: i18n("Artist name:")
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
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

                Label {
                    visible: miniPlayerArtistNameFontCheckbox.checked
                    text: i18n("Letter spacing:")
                }

                SpinBox {
                    id: miniPlayerArtistNameSpacing
                    visible: miniPlayerArtistNameFontCheckbox.checked
                    from: -5
                    to: 20
                    stepSize: 1
                }
            }

            Label {
                visible: miniPlayerArtistNameFontCheckbox.checked && miniPlayerArtistNameFontDialog.fontChosen
                text: i18n("Selected font: %1 %2pt", miniPlayerArtistNameFontDialog.fontChosen.family,
                          miniPlayerArtistNameFontDialog.fontChosen.pointSize)
                font: miniPlayerArtistNameFontDialog.fontChosen
            }
        }

        // Full Player Font Settings
        Label {
            text: i18n("Full Player")
            font.bold: true
            Layout.topMargin: Kirigami.Units.largeSpacing * 2
        }

        // Full Player Song Name (similar structure)
        ColumnLayout {
            Kirigami.FormData.label: i18n("Song name:")
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
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

                Label {
                    visible: fullPlayerSongNameFontCheckbox.checked
                    text: i18n("Letter spacing:")
                }

                SpinBox {
                    id: fullPlayerSongNameSpacing
                    visible: fullPlayerSongNameFontCheckbox.checked
                    from: -5
                    to: 20
                    stepSize: 1
                }
            }

            Label {
                visible: fullPlayerSongNameFontCheckbox.checked && fullPlayerSongNameFontDialog.fontChosen
                text: i18n("Selected font: %1 %2pt", fullPlayerSongNameFontDialog.fontChosen.family,
                          fullPlayerSongNameFontDialog.fontChosen.pointSize)
                font: fullPlayerSongNameFontDialog.fontChosen
            }
        }

        // Full Player Artist Name (similar structure)
        ColumnLayout {
            Kirigami.FormData.label: i18n("Artist name:")
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
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

                Label {
                    visible: fullPlayerArtistNameFontCheckbox.checked
                    text: i18n("Letter spacing:")
                }

                SpinBox {
                    id: fullPlayerArtistNameSpacing
                    visible: fullPlayerArtistNameFontCheckbox.checked
                    from: -5
                    to: 20
                    stepSize: 1
                }
            }

            Label {
                visible: fullPlayerArtistNameFontCheckbox.checked && fullPlayerArtistNameFontDialog.fontChosen
                text: i18n("Selected font: %1 %2pt", fullPlayerArtistNameFontDialog.fontChosen.family,
                          fullPlayerArtistNameFontDialog.fontChosen.pointSize)
                font: fullPlayerArtistNameFontDialog.fontChosen
            }
        }

        // Timer Font Settings
        ColumnLayout {
            Kirigami.FormData.label: i18n("Timer:")
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
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

                Label {
                    visible: timerFontCheckbox.checked
                    text: i18n("Letter spacing:")
                }

                SpinBox {
                    id: timerSpacing
                    visible: timerFontCheckbox.checked
                    from: -5
                    to: 20
                    stepSize: 1
                }
            }

            Label {
                visible: timerFontCheckbox.checked && timerFontDialog.fontChosen
                text: i18n("Selected font: %1 %2pt", timerFontDialog.fontChosen.family,
                          timerFontDialog.fontChosen.pointSize)
                font: timerFontDialog.fontChosen
            }
        }

        // Font dialogs
        QtDialogs.FontDialog {
            id: miniPlayerSongNameFontDialog
            title: i18n("Choose Mini Player Song Name Font")
            property font fontChosen: Qt.font({})
            onAccepted: { fontChosen = selectedFont }
        }

        QtDialogs.FontDialog {
            id: miniPlayerArtistNameFontDialog
            title: i18n("Choose Mini Player Artist Name Font")
            property font fontChosen: Qt.font({})
            onAccepted: { fontChosen = selectedFont }
        }

        QtDialogs.FontDialog {
            id: fullPlayerSongNameFontDialog
            title: i18n("Choose Full Player Song Name Font")
            property font fontChosen: Qt.font({})
            onAccepted: { fontChosen = selectedFont }
        }

        QtDialogs.FontDialog {
            id: fullPlayerArtistNameFontDialog
            title: i18n("Choose Full Player Artist Name Font")
            property font fontChosen: Qt.font({})
            onAccepted: { fontChosen = selectedFont }
        }

        QtDialogs.FontDialog {
            id: timerFontDialog
            title: i18n("Choose Timer Font")
            property font fontChosen: Qt.font({})
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
