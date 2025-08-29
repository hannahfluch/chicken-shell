import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Utils
import qs.Services
import qs.Widgets

import "../../Helpers/FuzzySort.js" as Fuzzysort

LoaderWidget {
  id: appLauncher
  isLoaded: false
  content: Component {
    PanelWidget {
      id: appLauncherPanel
      showOverlay: false

      WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

      function selectNext() {
        if (filteredEntries.length > 0) {
          selectedIndex = Math.min(selectedIndex + 1, filteredEntries.length - 1)
        }
      }

      function selectPrev() {
        if (filteredEntries.length > 0) {
          selectedIndex = Math.max(selectedIndex - 1, 0)
        }
      }

      function activateSelected() {
        if (filteredEntries.length === 0)
          return

        var modelData = filteredEntries[selectedIndex]
        if (modelData && modelData.execute) {
          modelData.execute()
          appLauncherPanel.hide()
        }
      }

      property var desktopEntries: DesktopEntries.applications.values
      property string searchText: ""
      property int selectedIndex: 0

      property var filteredEntries: {
        Logger.log("AppLauncher", "Total desktop entries:", desktopEntries ? desktopEntries.length : 0)
        if (!desktopEntries || desktopEntries.length === 0) {
          Logger.log("AppLauncher", "No desktop entries available")
          return []
        }

        // Filter out entries that shouldn't be displayed
        var visibleEntries = desktopEntries.filter(entry => {
                                                     if (!entry || entry.noDisplay) {
                                                       return false
                                                     }
                                                     return true
                                                   })

        Logger.log("AppLauncher", "Visible entries:", visibleEntries.length)

        var query = searchText ? searchText.toLowerCase() : ""
        var results = []

        // Regular app search
        if (!query) {
          results = results.concat(visibleEntries.sort(function (a, b) {
            return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
          }))
        } else {
          var fuzzyResults = Fuzzysort.go(query, visibleEntries, {
                                            "keys": ["name", "comment", "genericName"]
                                          })
          results = results.concat(fuzzyResults.map(function (r) {
            return r.obj
          }))
        }

        Logger.log("AppLauncher", "Filtered entries:", results.length)
        return results
      }

      Component.onCompleted: {
        Logger.log("AppLauncher", "Component completed")
        Logger.log("AppLauncher", "DesktopEntries available:", typeof DesktopEntries !== 'undefined')
        if (typeof DesktopEntries !== 'undefined') {
          Logger.log("AppLauncher", "DesktopEntries.entries:",
                     DesktopEntries.entries ? DesktopEntries.entries.length : 'undefined')
        }
      }

      // Main content container
      Rectangle {
        anchors.centerIn: parent
        width: Math.min(500 * scaling, parent.width * 0.75)
        height: Math.min(350 * scaling, parent.height * 0.8)
        radius: Style.radiusL * scaling
        color: Color.mSurface
        border.color: Color.mOutline
        border.width: Style.borderS * scaling


        // Subtle gradient background
        gradient: Gradient {
          GradientStop {
            position: 0.0
            color: Qt.lighter(Color.mSurface, 1.02)
          }
          GradientStop {
            position: 1.0
            color: Qt.darker(Color.mSurface, 1.1)
          }
        }
        
        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM * scaling
          spacing: Style.marginS * scaling

          // Search bar
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Style.barHeight * scaling
            Layout.bottomMargin: Style.marginS * scaling
            radius: Style.radiusS * scaling
            color: Color.mSurface
            border.color: searchInput.activeFocus ? Color.mPrimary : Color.mOutline
            border.width: Math.max(1, searchInput.activeFocus ? Style.borderM * scaling : Style.borderS * scaling)

            Item {
              anchors.fill: parent
              anchors.margins: Style.marginS * scaling

              IconWidget {
                id: searchIcon
                text: "search"
                font.pointSize: Style.fontSizeM * scaling
                color: searchInput.activeFocus ? Color.mPrimary : Color.mOnSurface
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
              }

              TextField {
                id: searchInput
                placeholderText: "Search applications..."
                color: Color.mOnSurface
                placeholderTextColor: Color.mOnSurfaceVariant
                background: null
                font.pointSize: Style.fontSizeS * scaling
                anchors.left: searchIcon.right
                anchors.leftMargin: Style.marginS * scaling
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onTextChanged: {
                  searchText = text
                  selectedIndex = 0 // Reset selection when search changes
                }
                selectedTextColor: Color.mOnSurface
                selectionColor: Color.mPrimary
                padding: 0
                verticalAlignment: TextInput.AlignVCenter
                leftPadding: 0
                rightPadding: 0
                topPadding: 0
                bottomPadding: 0
                font.bold: true
                Component.onCompleted: {
                  contentItem.cursorColor = Color.mOnSurface
                  contentItem.verticalAlignment = TextInput.AlignVCenter
                  // Focus the search bar by default
                  Qt.callLater(() => {
                                 searchInput.forceActiveFocus()
                               })
                }
                onActiveFocusChanged: contentItem.cursorColor = Color.mOnSurface

                Keys.onDownPressed: selectNext()
                Keys.onUpPressed: selectPrev()
                Keys.onEnterPressed: activateSelected()
                Keys.onReturnPressed: activateSelected()
                Keys.onEscapePressed: appLauncherPanel.hide()
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

          // Applications list
          ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ListView {
              id: appsList
              anchors.fill: parent
              spacing: Style.marginXXS * scaling
              model: filteredEntries
              currentIndex: selectedIndex
              highlightMoveVelocity: -0.3

              delegate: Rectangle {
                width: appsList.width - Style.marginS * scaling
                height: 47 * scaling
                radius: Style.radiusM * scaling
                property bool isSelected: index === selectedIndex
                color: (appCardArea.containsMouse || isSelected) ? Qt.darker(Color.mPrimary, 1.1) : Color.mSurface
                border.color: (appCardArea.containsMouse || isSelected) ? Color.mPrimary : Color.transparent
                border.width: Math.max(1, (appCardArea.containsMouse || isSelected) ? Style.borderM * scaling : 0)

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: Style.marginS * scaling
                  spacing: Style.marginM * scaling

                  // App icon with background
                  Rectangle {
                    Layout.preferredWidth: Style.launcherWidgetSize * 1.25 * scaling
                    Layout.preferredHeight: Style.launcherWidgetSize * 1.25 * scaling
                    radius: Style.radiusS * scaling
                    color: appCardArea.containsMouse ? Qt.darker(Color.mPrimary, 1.1) : Color.mSurfaceVariant
                    property bool iconLoaded: iconImg.status === Image.Ready && iconImg.source !== "" && iconImg.status !== Image.Error
                    visible: true

                    IconImage {
                      id: iconImg
                      anchors.fill: parent
                      anchors.margins: Style.marginXS * scaling
                      asynchronous: true
                      source: modelData.icon ? Quickshell.iconPath(modelData.icon, "application-x-executable") : ""
                      visible: parent.iconLoaded && modelData.type !== 'image'
                    }

                    // Fallback icon container
                    Rectangle {
                      anchors.fill: parent
                      anchors.margins: Style.marginXS * scaling
                      radius: Style.radiusXS * scaling
                      color: Color.mPrimary
                      opacity: Style.opacityMedium
                      visible: !parent.iconLoaded
                    }

                    Text {
                      anchors.centerIn: parent
                      visible: !parent.iconLoaded 
                      text: modelData.name ? modelData.name.charAt(0).toUpperCase() : "?"
                      font.pointSize: Style.fontSizeM * scaling
                      font.weight: Font.Bold
                      color: Color.mPrimary
                    }

                    Behavior on color {
                      ColorAnimation {
                        duration: Style.animationFast
                      }
                    }
                  }

                  // App info
                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginXXS * scaling

                    TextWidget {
                      text: modelData.name || "Unknown"
                      font.pointSize: Style.fontSizeS * scaling
                      font.weight: Font.Bold
                      color: (appCardArea.containsMouse || isSelected) ? Color.mOnPrimary : Color.mOnSurface
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }

                    TextWidget {
                      text: modelData.genericName || modelData.comment || ""
                      font.pointSize: Style.fontSizeM * scaling
                      color: (appCardArea.containsMouse || isSelected) ? Color.mOnPrimary : Color.mOnSurface
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                      visible: text !== ""
                    }
                  }
                }

                MouseArea {
                  id: appCardArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor

                  onClicked: {
                    selectedIndex = index
                    activateSelected()
                  }
                }
              }
            }
          }

          // No results message
          TextWidget {
            text: searchText.trim() !== "" ? "No applications found" : "No applications available"
            font.pointSize: Style.fontSizeL * scaling
            color: Color.mOnSurface
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            visible: filteredEntries.length === 0
          }

          // Results count
          TextWidget {
            text:  `${filteredEntries.length} application${filteredEntries.length !== 1 ? 's' : ''}`
            font.pointSize: Style.fontSizeXS * scaling
            color: Color.mOnSurface
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            visible: searchText.trim() !== ""
          }
        }
      }
    }
  }
}
