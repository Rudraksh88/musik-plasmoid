import QtQuick 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris

Item {
    id: root
    property string type: "icon"
    property var imageUrl: null
    property var imageRadius: null
    property var icon: null
    property real size: Kirigami.Units.iconSizes.medium

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

    Kirigami.Icon {
        visible: type === "icon"
        id: iconComponent
        // source: root.icon
        // Set source icon based on the current player
        source: mpris2Source.sourceName.includes('brave') ? "brave_mono" : mpris2Source.sourceName.includes('fooyin') ? "spotify_mono" : mpris2Source.sourceName.includes('firefox') ? "firefox_mono" : mpris2Source.sourceName.includes('chrome') ? "chrome_mono" : "music_mono"
        width: 25
        height: 25
        color: Kirigami.Theme.textColor
        opacity: 0.8

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
