import QtQuick
import Quickshell
import qs.Utils
import qs.Services
import qs.Widgets

Row {
  id: root
  anchors.verticalCenter: parent.verticalCenter
  spacing: Style.marginS * scaling
  visible: true

  Rectangle {
    // Let the Rectangle size itself based on its content (the Row)
    width: row.width + Style.marginM * scaling * 2

    height: Math.round(Style.capsuleHeight * scaling)
    radius: Math.round(Style.radiusM * scaling)
    color: Color.mSurfaceVariant

    anchors.verticalCenter: parent.verticalCenter

    Item {
      id: mainContainer
      anchors.fill: parent
      anchors.leftMargin: Style.marginS * scaling
      anchors.rightMargin: Style.marginS * scaling

      Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.marginS * scaling
        Row {
          id: cpuUsageLayout
          spacing: Style.marginXS * scaling

          IconWidget {
            id: cpuUsageIcon
            text: "speed"
            anchors.verticalCenter: parent.verticalCenter
          }

          TextWidget {
            id: cpuUsageText
            text: `${SystemStatService.cpuUsage}%`
            font.pointSize: Style.fontSizeS * scaling
            font.weight: Style.fontWeightMedium
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignVCenter
            color: Color.mPrimary
          }
        }

        // CPU Temperature Component
        Row {
          id: cpuTempLayout
          // spacing is thin here to compensate for the vertical thermometer icon
          spacing: Style.marginXXS * scaling

          IconWidget {
            text: "thermometer"
            anchors.verticalCenter: parent.verticalCenter
          }

          TextWidget {
            text: `${SystemStatService.cpuTemp}°C`
            font.pointSize: Style.fontSizeS * scaling
            font.weight: Style.fontWeightMedium
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignVCenter
            color: Color.mPrimary
          }
        }

        // Memory Usage Component
        Row {
          id: memoryUsageLayout
          spacing: Style.marginXS * scaling

          IconWidget {
            text: "memory"
            anchors.verticalCenter: parent.verticalCenter
          }

          TextWidget {
            text: `${SystemStatService.memoryUsageGb}G`
            font.pointSize: Style.fontSizeS * scaling
            font.weight: Style.fontWeightMedium
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignVCenter
            color: Color.mPrimary
          }
        }
      }
    }
  }
}
