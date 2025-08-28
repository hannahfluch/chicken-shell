import QtQuick
import qs.Services
import qs.Utils
import qs.Widgets

Rectangle {
    id: root

    property string tooltipText: ""

    signal entered
    signal exited
    signal clicked

    width: textItem.paintedWidth
    height: textItem.paintedHeight
    color: Color.transparent

    TextWidget {
        id: textItem
        text: Time.time
        anchors.centerIn: parent
        font.weight: Style.fontWeightBold
    }

    TooltipWidget {
        id: tooltip
        positionAbove: !Settings.data.bar.top
        target: root
        delay: Style.tooltipDelayLong
        text: root.tooltipText
    }

    MouseArea {
        id: clockMouseArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onEntered: {
            tooltip.show();
            root.entered();
        }
        onExited: {
            tooltip.hide();
            root.exited();
        }
        onClicked: root.clicked()
    }
}
