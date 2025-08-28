import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Utils
import qs.Services
import qs.Widgets

Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
        id: root
        required property ShellScreen modelData
        readonly property real scaling: ScalingService.scale(screen)
        screen: modelData
        implicitHeight: Style.barHeight * scaling
        color: Color.transparent
        visible: true
        anchors {
            top: Settings.data.bar.top
            bottom: !Settings.data.bar.top
            left: true
            right: true
        }

        Item {
            anchors.fill: parent
            clip: true

            // Background fill
            Rectangle {
                id: bar

                anchors.fill: parent
                color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, Settings.data.bar.backgroundOpacity)
                layer.enabled: true
            }
            // Left
            Row {
                id: leftSection

                height: parent.height
                anchors.left: parent.left
                anchors.leftMargin: Style.marginS * scaling
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.marginS * scaling

                SystemMonitor {}
            }

            // Center
            Row {
                id: centerSection

                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.marginS * scaling

                Workspaces {}
            }

            // Right
            Row {
                id: rightSection

                height: parent.height
                anchors.right: bar.right
                anchors.rightMargin: Style.marginS * scaling
                anchors.verticalCenter: bar.verticalCenter
                spacing: Style.marginS * scaling

                Networks { anchors.verticalCenter: parent.verticalCenter }
                
                NotificationHistory {
                    anchors.verticalCenter: parent.verticalCenter
                }

                Volume {
                    anchors.verticalCenter: parent.verticalCenter
                }

                Brightness {
                    anchors.verticalCenter: parent.verticalCenter
                }

                Battery {
                    anchors.verticalCenter: parent.verticalCenter
                }
                Clock {
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
