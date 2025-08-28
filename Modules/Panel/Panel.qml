import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Modules.Panel.Tabs as Tabs
import qs.Utils
import qs.Services
import qs.Widgets

LoaderWidget {
    id: root

    // Tabs enumeration, order is NOT relevant
    enum Tab {
        AudioService,
        // Brightness, (todo)
        // Display,
        General
        // Network,
        // ScreenRecorder,
        // WallpaperSelector
    }

    property int requestedTab: Panel.Tab.General

    content: Component {
        PanelWidget {
            id: panel

            property int currentTabIndex: 0

            // Override hide function to animate first
            function hide() {
                // Start hide animation
                bgRect.scaleValue = 0.8;
                bgRect.opacityValue = 0.0;
                // Hide after animation completes
                hideTimer.start();
            }

            Shortcut {
                sequence: "Escape"
                context: Qt.WindowShortcut
                onActivated: panel.hide()
            }

            // Connect to NPanel's dismissed signal to handle external close events
            Connections {
                target: panel
                function onDismissed() {
                    hide();
                }
            }

            // Timer to hide panel after animation
            Timer {
                id: hideTimer
                interval: Style.animationSlow
                repeat: false
                onTriggered: {
                    panel.visible = false;
                    panel.dismissed();
                }
            }

            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            Component {
                id: generalTab
                Tabs.GeneralTab {}
            }
            Component {
                id: audioTab
                Tabs.AudioTab {}
            }
            // Component {
            //   id: brightnessTab
            //   Tabs.BrightnessTab {}
            // }
            // Component {
            //   id: displayTab
            //   Tabs.DisplayTab {}
            // }
            // Component {
            //   id: networkTab
            //   Tabs.NetworkTab {}
            // }
            // Component {
            //   id: wallpaperSelectorTab
            //   Tabs.WallpaperSelectorTab {}
            // }
            // Component {
            //   id: screenRecorderTab
            //   Tabs.ScreenRecorderTab {}
            // }

            // Order *DOES* matter
            property var tabsModel: [
                {
                    "id": Panel.Tab.General,
                    "label": "General",
                    "icon": "tune",
                    "source": generalTab
                },
                {
                    "id": Panel.Tab.AudioService,
                    "label": "Audio",
                    "icon": "volume_up",
                    "source": audioTab
                    // }, {
                    //   "id": Panel.Tab.Display,
                    //   "label": "Display",
                    //   "icon": "monitor",
                    //   "source": displayTab
                    // }, {
                    //   "id": Panel.Tab.Network,
                    //   "label": "Network",
                    //   "icon": "lan",
                    //   "source": networkTab
                    // }, {
                    //   "id": Panel.Tab.Brightness,
                    //   "label": "Brightness",
                    //   "icon": "brightness_6",
                    //   "source": brightnessTab
                    // }, {
                    //   "id": Panel.Tab.WallpaperSelector,
                    //   "label": "Wallpaper Selector",
                    //   "icon": "wallpaper_slideshow",
                    //   "source": wallpaperSelectorTab
                    // }, {
                    //   "id": Panel.Tab.ScreenRecorder,
                    //   "label": "Screen Recorder",
                    //   "icon": "videocam",
                    //   "source": screenRecorderTab
                }
            ]

            Component.onCompleted: {
                var initialIndex = 0;
                if (root.requestedTab !== null) {
                    for (var i = 0; i < panel.tabsModel.length; i++) {
                        if (panel.tabsModel[i].id === root.requestedTab) {
                            initialIndex = i;
                            break;
                        }
                    }
                }
                // Now that the UI is settled, set the current tab index.
                panel.currentTabIndex = initialIndex;
                show();
            }

            onVisibleChanged: {
                if (!visible && (bgRect.opacityValue > 0)) {
                    hide();
                }
            }

            Rectangle {
                id: bgRect
                color: Color.mSurface
                radius: Style.radiusL * scaling
                border.color: Color.mOutline
                border.width: Math.max(1, Style.borderS * scaling)
                layer.enabled: true
                width: Math.max(screen.width * 0.5, 1280) * scaling
                height: Math.max(screen.height * 0.5, 720) * scaling
                anchors.centerIn: parent

                // Animation properties
                property real scaleValue: 0.8
                property real opacityValue: 0.0

                scale: scaleValue
                opacity: opacityValue

                // Animate in when component is completed
                Component.onCompleted: {
                    scaleValue = 1.0;
                    opacityValue = 1.0;
                }

                MouseArea {
                    anchors.fill: parent
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Style.animationSlow
                        easing.type: Easing.OutExpo
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: Style.animationNormal
                        easing.type: Easing.OutQuad
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Style.marginL * scaling
                    spacing: Style.marginL * scaling

                    Rectangle {
                        id: sidebar
                        Layout.preferredWidth: Style.sliderWidth * 1.3 * scaling
                        Layout.fillHeight: true
                        color: Color.mSurfaceVariant
                        border.color: Color.mOutline
                        border.width: Math.max(1, Style.borderS * scaling)
                        radius: Style.radiusM * scaling

                        Column {
                            anchors.fill: parent
                            anchors.margins: Style.marginS * scaling
                            spacing: Style.marginXS * 1.5 * scaling

                            Repeater {
                                id: sections
                                model: panel.tabsModel
                                delegate: Rectangle {
                                    id: tabItem
                                    width: parent.width
                                    height: 32 * scaling
                                    radius: Style.radiusS * scaling
                                    color: selected ? Color.mPrimary : (tabItem.hovering ? Color.mTertiary : Color.transparent)
                                    readonly property bool selected: index === currentTabIndex
                                    property bool hovering: false
                                    property color tabTextColor: selected ? Color.mOnPrimary : (tabItem.hovering ? Color.mOnTertiary : Color.mOnSurface)
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: Style.marginS * scaling
                                        anchors.rightMargin: Style.marginS * scaling
                                        spacing: Style.marginS * scaling
                                        // Tab icon on the left side
                                        IconWidget {
                                            text: modelData.icon
                                            color: tabTextColor
                                            font.pointSize: Style.fontSizeL * scaling
                                        }
                                        // Tab label on the left side
                                        TextWidget {
                                            text: modelData.label
                                            color: tabTextColor
                                            font.pointSize: Style.fontSizeM * scaling
                                            font.weight: Style.fontWeightBold
                                            Layout.fillWidth: true
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton
                                        onEntered: tabItem.hovering = true
                                        onExited: tabItem.hovering = false
                                        onCanceled: tabItem.hovering = false
                                        onClicked: currentTabIndex = index
                                    }
                                }
                            }
                        }
                    }

                    // Content
                    Rectangle {
                        id: contentPane
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Style.radiusM * scaling
                        color: Color.mSurfaceVariant
                        border.color: Color.mOutline
                        border.width: Math.max(1, Style.borderS * scaling)
                        clip: true

                        ColumnLayout {
                            id: contentLayout
                            anchors.fill: parent
                            anchors.margins: Style.marginL * scaling
                            spacing: Style.marginS * scaling

                            RowLayout {
                                id: headerRow
                                Layout.fillWidth: true
                                spacing: Style.marginS * scaling

                                // Tab label on the main right side
                                TextWidget {
                                    text: panel.tabsModel[currentTabIndex].label
                                    font.pointSize: Style.fontSizeL * scaling
                                    font.weight: Style.fontWeightBold
                                    color: Color.mPrimary
                                    Layout.fillWidth: true
                                }
                                IconButtonWidget {
                                    icon: "close"
                                    tooltipText: "Close"
                                    Layout.alignment: Qt.AlignVCenter
                                    onClicked: panel.hide()
                                }
                            }

                            DividerWidget {
                                Layout.fillWidth: true
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true

                                Repeater {
                                    model: panel.tabsModel

                                    onItemAdded: function (index, item) {
                                        item.sourceComponent = panel.tabsModel[index].source;
                                    }

                                    delegate: Loader {
                                        // All loaders will occupy the same space, stacked on top of each other.
                                        anchors.fill: parent
                                        visible: index === panel.currentTabIndex
                                        // The loader is only active (and uses memory) when its page is visible.
                                        active: visible
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
