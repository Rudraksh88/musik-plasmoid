import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.5 as Kirigami

PlasmaComponents3.Control {
    id: root

    property int handleSize: Kirigami.Units.gridUnit

    rightPadding: handleSize / 2
    bottomPadding: handleSize / 2

    background: Item {
        Rectangle {
            id: resizeHandle
            width: handleSize
            height: handleSize
            color: "transparent"
            border.color: Kirigami.Theme.textColor
            border.width: 1
            radius: 3
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeFDiagCursor
                property point startPoint
                property size startSize

                onPressed: {
                    startPoint = Qt.point(mouseX, mouseY)
                    startSize = Qt.size(root.width, root.height)
                }

                onPositionChanged: {
                    if (pressed) {
                        var dx = mouseX - startPoint.x
                        var dy = mouseY - startPoint.y
                        var newWidth = Math.max(root.Layout.minimumWidth, startSize.width + dx)
                        var newHeight = Math.max(root.Layout.minimumHeight, startSize.height + dy)
                        root.Layout.preferredWidth = newWidth
                        root.Layout.preferredHeight = newHeight
                    }
                }
            }
        }
    }
}
