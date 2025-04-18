import QtQuick 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import QtQuick.Effects

Item {
    id: root
    property string type: "icon"
    property var imageUrl: null
    property var imageRadius: null
    property var icon: null
    property real size: Kirigami.Units.iconSizes.medium
    property bool hoveredOnPlasmoid: false

    Mpris.Mpris2Model {
        id: mpris2Source
        readonly property string sourceName: mpris2Source.currentPlayer.identity.toLowerCase()
    }

    Layout.preferredHeight: size
    Layout.preferredWidth: size

    onTypeChanged: () => {
        if ([ "icon", "image" ].includes(type)) {
            console.error("Panel icon type not supported")
        }
        if (type === "icon" && !icon) {
            console.error("Panel icon type is icon but no icon is set")
        }
        if (type === "image" && !imageUrl) {
            console.error("Panel icon type is image but no image url is set")
        }
    }

    QtObject {
        id: mediaSources
        readonly property string brave:   Qt.resolvedUrl("assets/brave_mono.svg")
        readonly property string chrome:  Qt.resolvedUrl("assets/chrome_mono.svg")
        readonly property string fooyin:  Qt.resolvedUrl("assets/spotify_mono.svg")
        readonly property string firefox: Qt.resolvedUrl("assets/firefox_mono.svg")
        readonly property string ytMusic: Qt.resolvedUrl("assets/yt_music_mono.svg")
        readonly property string music:   Qt.resolvedUrl("assets/music_mono.svg")
        readonly property string spotify: Qt.resolvedUrl("assets/spotify_mono.svg")
        readonly property string zen:     Qt.resolvedUrl("assets/zen_mono.svg")
    }

    Kirigami.Icon {
        visible: type === "icon"
        id: iconComponent
        // source: root.icon
        // Set source icon based on the current player
        source: mpris2Source.sourceName.includes('brave') ? mediaSources.brave : mpris2Source.sourceName.includes('fooyin') ? mediaSources.fooyin : mpris2Source.sourceName.includes('firefox') ? mediaSources.firefox : mpris2Source.sourceName.includes('chrome') ? mediaSources.chrome : mpris2Source.sourceName.includes('youtube') ? mediaSources.ytMusic : mpris2Source.sourceName.includes('zen') ? mediaSources.zen : mediaSources.music
        // Set a fixed source size that's higher than display size
        width: widget.height
        height: width

        smooth: true
        antialiasing: true

        color: Kirigami.Theme.textColor
        opacity: hoveredOnPlasmoid ? 0.55 : 0.4

        layer.enabled: true
        // layer.smooth: true
        layer.samples: 8
        layer.effect: MultiEffect {
            brightness: 0.8
            contrast: 0.07
            saturation: 1.0
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        // Align the icon in the center
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
    }

    Image {
        visible: type === "image"
        width: root.size - 6
        height: root.size - 6
        id: imageComponent
        // anchors.fill: parent
        source: root.imageUrl
        fillMode: Image.PreserveAspectFit

        // Align the image in the center
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        // enables round corners while the radius is set
        // ref: https://stackoverflow.com/questions/6090740/image-rounded-corners-in-qml
        layer.enabled: imageRadius > 0
        layer.effect: OpacityMask {
            maskSource: Item {
                width: imageComponent.width
                height: imageComponent.height
                Rectangle {
                    anchors.fill: parent
                    radius: imageRadius
                }
            }
        }
    }
}
