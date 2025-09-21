import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.Utils
import qs.Services
import qs.Widgets

// Simple notification popup - displays multiple notifications
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: root

        required property ShellScreen modelData
        readonly property real scaling: ScalingService.scale(screen)
        screen: modelData

        // Access the notification model from the service
        property ListModel notificationModel: NotificationService.notificationModel

        // Track notifications being removed for animation
        property var removingNotifications: ({})

        color: Color.transparent

        // If no notification display activated in settings, then show them all
        visible: modelData ? (Settings.data.notifications.monitors.includes(modelData.name) || (Settings.data.notifications.monitors.length === 0)) && (NotificationService.notificationModel.count > 0) : false

        // Position based on bar location
        anchors.top: Settings.data.bar.top ? "top" : ""
        anchors.bottom: !Settings.data.bar.top ? "bottom" : ""
        anchors.right: true
        margins.top: Settings.data.bar.top ? (Style.barHeight + Style.marginM) * scaling : 0
        margins.bottom: !Settings.data.bar.top ? (Style.barHeight + Style.marginM) * scaling : 0
        margins.right: Style.marginM * scaling
        implicitWidth: 360 * scaling
        implicitHeight: Math.min(notificationStack.implicitHeight, (NotificationService.maxVisible * 120) * scaling)
        Behavior on implicitHeight { NumberAnimation { duration: Style.animationNormal; easing.type: Easing.OutCubic } }
        WlrLayershell.layer: WlrLayer.Overlay
        exclusionMode: ExclusionMode.Ignore

        // Connect to animation signal from service
        Component.onCompleted: {
            NotificationService.animateAndRemove.connect(function (notification, index) {
                // Find the delegate and trigger its animation
                if (notificationStack.children && notificationStack.children[index]) {
                    let delegate = notificationStack.children[index];
                    if (delegate && delegate.animateOut) {
                        delegate.animateOut();
                    }
                }
            });
        }

        // Main notification container
        Column {
            id: notificationStack
            spacing: Style.marginS * scaling
            width: 360 * scaling
            visible: true

            // Multiple notifications display
            Repeater {
                model: notificationModel
                delegate: Rectangle {
                    width: 360 * scaling
                    height: Math.max(80 * scaling, contentColumn.implicitHeight + (Style.marginM * 2 * scaling))
                    clip: true
                    radius: Style.radiusM * scaling
                    border.color: Color.mPrimary
                    border.width: Math.max(1, Style.borderS * scaling)
                    color: Color.mSurface

                    // Animation properties
                    property real opacityValue: 0.0
                    property bool isRemoving: false

                    // Scale and fade-in animation
                    opacity: opacityValue

                    property real ty: 8 * scaling
                    transform: Translate { y: ty }

                    // recommended: cache during anim to avoid paint artifacts on rounded corners
                    antialiasing: true
                    layer.enabled: true
                    layer.smooth: true
                    // Animate in when the item is created
                    Component.onCompleted: {
                        ty = 0;
                        opacityValue = 1.0;
                    }

                    // Animate out when being removed
                    function animateOut() {
                        isRemoving = true;
                        ty = -8 * scaling;
                        opacityValue = 0.0;
                    }

                    // Timer for delayed removal after animation
                    Timer {
                        id: removalTimer
                        interval: Style.animationSlow
                        repeat: false
                        onTriggered: {
                            NotificationService.forceRemoveNotification(model.rawNotification);
                        }
                    }

                    // Check if this notification is being removed
                    onIsRemovingChanged: {
                        if (isRemoving) {
                            // Remove from model after animation completes
                            removalTimer.start();
                        }
                    }

                    // Animation behaviors
                    Behavior on ty {
                        NumberAnimation {
                            duration: Style.animationFast;
                            easing.type: Easing.OutQuad
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Style.animationNormal
                            easing.type: Easing.OutQuad
                        }
                    }

                    Column {
                        id: contentColumn
                        anchors.fill: parent
                        anchors.margins: Style.marginM * scaling
                        spacing: Style.marginS * scaling

                        RowLayout {
                            spacing: Style.marginS * scaling
                            TextWidget {
                                text: (model.appName || model.desktopEntry) || "Unknown App"
                                color: Color.mSecondary
                                font.pointSize: Style.fontSizeXS * scaling
                            }
                            Rectangle {
                                width: 6 * scaling
                                height: 6 * scaling
                                radius: Style.radiusXS * scaling
                                color: (model.urgency === NotificationUrgency.Critical) ? Color.mError : (model.urgency === NotificationUrgency.Low) ? Color.mOnSurface : Color.mPrimary
                                Layout.alignment: Qt.AlignVCenter
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            TextWidget {
                                text: NotificationService.formatTimestamp(model.timestamp)
                                color: Color.mOnSurface
                                font.pointSize: Style.fontSizeXS * scaling
                            }
                        }

                        TextWidget {
                            text: model.summary || "No summary"
                            font.pointSize: Style.fontSizeL * scaling
                            font.weight: Style.fontWeightBold
                            color: Color.mOnSurface
                            wrapMode: Text.Wrap
                            width: 300 * scaling
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }

                        TextWidget {
                            text: model.body || ""
                            font.pointSize: Style.fontSizeXS * scaling
                            color: Color.mOnSurface
                            wrapMode: Text.Wrap
                            width: 300 * scaling
                            maximumLineCount: 5
                            elide: Text.ElideRight
                        }
                    }

                    IconButtonWidget {
                        icon: "close"
                        tooltipText: "Close"
                        sizeMultiplier: 0.8
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: Style.marginS * scaling

                        onClicked: {
                            animateOut();
                        }
                    }
                }
            }
        }
    }
}
