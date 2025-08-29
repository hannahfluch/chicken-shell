import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.Utils
import qs.Services
import qs.Widgets

// Loader for Wallpaper Chooser panel
LoaderWidget {
    id: root
    isLoaded: false

    content: Component {
        PanelWidget {
            id: wallpaperChooserPanel
            showOverlay: false

            // Override hide function to animate first
            function hide() {
                // Start hide animation
                wallpaperChooserRect.scaleValue = 0.8;
                wallpaperChooserRect.opacityValue = 0.0;

                // Hide after animation completes
                hideTimer.start();
            }
            Shortcut {
                sequence: "Escape"
                context: Qt.WindowShortcut
                onActivated: wallpaperChooserPanel.hide()
            }

            Connections {
                target: wallpaperChooserPanel
                ignoreUnknownSignals: true
                function onDismissed() {
                    // Start hide animation
                    wallpaperChooserRect.scaleValue = 0.8;
                    wallpaperChooserRect.opacityValue = 0.0;

                    // Hide after animation completes
                    hideTimer.start();
                }
            }

            // Also handle visibility changes from external sources
            onVisibleChanged: {
                if (!visible && wallpaperChooserRect.opacityValue > 0) {
                    // Start hide animation
                    wallpaperChooserRect.scaleValue = 0.8;
                    wallpaperChooserRect.opacityValue = 0.0;

                    // Hide after animation completes
                    hideTimer.start();
                }
            }

            // Timer to hide panel after animation
            Timer {
                id: hideTimer
                interval: Style.animationSlow
                repeat: false
                onTriggered: {
                    wallpaperChooserPanel.visible = false;
                    wallpaperChooserPanel.dismissed();
                }
            }

            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand


            function selectNext() {
                if (strip.count === 0) return;
                strip.currentIndex = (strip.currentIndex + 1) % strip.count;
            }
            function selectPrev() {
                if (strip.count === 0) return;
                if (strip.currentIndex === 0) strip.currentIndex = strip.count - 1;
                else strip.currentIndex = (strip.currentIndex - 1) % strip.count;
            }
            function activateSelected() {
                if(strip.currentItem) strip.currentItem.click()
            }

            Rectangle {
                id: wallpaperChooserRect
                color: Color.mSurface
                radius: Style.radiusL * scaling
                clip: true
                anchors.top: parent.top
                anchors.right: parent.right
                width: parent.width
                height: Style.wallpaperChooserHeight * scaling
                Keys.forwardTo: [strip]
                focus: true

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

                // Animation behaviors
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
                ScrollView {
                    id: scroller
                    anchors.fill: parent
                    anchors.margins: Style.marginM * scaling
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                    ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                    ListView {
                        id: strip
                        anchors.fill: parent
                        orientation: ListView.Horizontal
                        spacing: Style.marginM * scaling
                        boundsBehavior: Flickable.StopAtBounds
                        snapMode: ListView.NoSnap
                        model: WallpaperService.wallpapers
                        focus: true
                        // keyboard navigation
                        Keys.onRightPressed : selectNext()
                        Keys.onLeftPressed: selectPrev()
                        Keys.onEnterPressed: activateSelected()
                        Keys.onReturnPressed: activateSelected()
                        Keys.onEscapePressed: wallpaperChooserPanel.hide()

                        delegate: Item {
                            id: thumb
                            width: 300 * scaling
                            height:  strip.height 
                            property bool isSelected: strip.currentIndex === index
                            property string name: modelData
                            // expose a simple click method so keyboard can trigger it too
                            function click() {
                                WallpaperService.choose(name);
                                wallpaperChooserPanel.hide();
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: Style.radiusM * scaling
                                color: area.containsMouse || thumb.isSelected ? Qt.darker(Color.mPrimary, 1.12) : Color.mSurfaceVariant
                                border.color: area.containsMouse || thumb.isSelected ? Color.mPrimary : Color.mOutline
                                border.width: Math.max(1, (area.containsMouse || thumb.isSelected) ? Style.borderM * scaling : Style.borderS * scaling)
                                clip: true

                                Image {
                                    id: img
                                    anchors.fill: parent
                                    anchors.margins: Style.marginS * scaling
                                    asynchronous: true
                                    fillMode: Image.PreserveAspectCrop
                                    source: WallpaperService.path(thumb.name)
                                    cache: true
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Style.animationFast
                                    }
                                }
                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: Style.animationFast
                                    }
                                }
                                Behavior on border.width {
                                    NumberAnimation {
                                        duration: Style.animationFast
                                    }
                                }
                            }
                            MouseArea {
                                id: area
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    strip.currentIndex = index;
                                    thumb.click();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
