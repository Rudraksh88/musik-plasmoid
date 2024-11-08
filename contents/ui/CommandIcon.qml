import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: container
    property alias size: icon.width
    property bool active: false;
    property alias source: icon.source
    signal clicked()

    Layout.preferredWidth: size
    Layout.preferredHeight: size

    Kirigami.Icon {
        id: icon
        width: Kirigami.Units.iconSizes.small;
        height: width;
        color: container.active ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: container.clicked()
        }
    }

    opacity: mouseArea.containsMouse ? 1.0 : 0.7

    // Scale the icon when hovered
    scale: mouseArea.containsMouse ? 1.07 : 1.0

    Behavior on scale {
        NumberAnimation { duration: 150 }  // Smooth transition
    }


    Behavior on opacity {
        NumberAnimation { duration: 150 }  // Smooth transition
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true  // Enable hover detection
        onClicked: parent.clicked()  // Forward the click signal
    }
}