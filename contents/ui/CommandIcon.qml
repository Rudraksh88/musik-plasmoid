import QtQuick 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: container
    property alias size: icon.width
    property bool active: false
    property alias source: icon.source
    readonly property color defaultColor: Qt.rgba(1, 1, 1, 0.65)
    property color iconColor: defaultColor
    property bool hovered: mouseArea.containsMouse
    property bool isAccented: iconColor !== defaultColor

    // Function to brighten a color
    function brightenColor(color, factor) {
        let r = Math.min(1, color.r + (1 - color.r) * factor)
        let g = Math.min(1, color.g + (1 - color.g) * factor)
        let b = Math.min(1, color.b + (1 - color.b) * factor)
        return Qt.rgba(r, g, b, color.a)
    }

    signal clicked()

    Layout.preferredWidth: size
    Layout.preferredHeight: size

    Kirigami.Icon {
        id: icon
        width: Kirigami.Units.iconSizes.small
        height: width
        color: container.iconColor
        visible: false

        Behavior on scale {
            NumberAnimation { duration: 150 }
        }

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    ColorOverlay {
        id: overlay
        anchors.fill: icon
        source: icon
        color: isAccented ?
               (mouseArea.containsMouse ? brightenColor(iconColor, 0.5) : iconColor) : // Brighten accented colors
               iconColor
        antialiasing: true
        opacity: isAccented ? 1.0 : (mouseArea.containsMouse ? 1.0 : 0.7) // Only apply opacity animation to non-accented

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: container.clicked()
    }
}