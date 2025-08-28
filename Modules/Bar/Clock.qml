import QtQuick
import qs.Utils
import qs.Widgets

// Clock Icon with attached calendar
Rectangle {
    id: root
    width: clock.width + Style.marginM * 2 * scaling
    height: Math.round(Style.capsuleHeight * scaling)
    radius: Math.round(Style.radiusM * scaling)
    color: Color.mSurfaceVariant

    ClockWidget {
        id: clock
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        tooltipText: Time.date
    }
}
