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

LoaderWidget {
  id: clipboard
  isLoaded: false
  content: Component {
    PanelWidget {
      id: clipboardPanel
      showOverlay: false
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

      function selectNext() {
        if (filteredEntries.length > 0)
          selectedIndex = Math.min(selectedIndex + 1, filteredEntries.length - 1)
      }
      function selectPrev() {
        if (filteredEntries.length > 0)
          selectedIndex = Math.max(selectedIndex - 1, 0)
      }
      function activateSelected() {
        if (filteredEntries.length === 0) return
        var m = filteredEntries[selectedIndex]
        if (m && m.execute) {
          m.execute()
          clipboardPanel.hide()
        }
      }

      property string searchText: ""
      property int selectedIndex: 0

      // build from cliphist list results
      property var filteredEntries: {
        const q = (searchText || "").toLowerCase()
        const src = ClipboardService.history || []
        const out = []
        for (let i = 0; i < src.length; i++) {
          const row = src[i]
          const preview = String(row.preview || "")
          if (q && preview.toLowerCase().indexOf(q) === -1) continue
          out.push({
            id: row.id,
            name: preview,
            execute: function () { ClipboardService.copyById(row.id) }
          })
        }
        return out
      }

      Component.onCompleted: ClipboardService.refresh()

      Rectangle {
        anchors.centerIn: parent
        width: Math.min(500 * scaling, parent.width * 0.75)
        height: Math.min(350 * scaling, parent.height * 0.8)
        radius: Style.radiusL * scaling
        color: Color.mSurface
        border.color: Color.mOutline
        border.width: Style.borderS * scaling

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM * scaling
          spacing: Style.marginS * scaling

          // search
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
                placeholderText: "Search clipboard history..."
                color: Color.mOnSurface
                placeholderTextColor: Color.mOnSurfaceVariant
                background: null
                font.pointSize: Style.fontSizeS * scaling
                anchors.left: searchIcon.right
                anchors.leftMargin: Style.marginS * scaling
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onTextChanged: { searchText = text; selectedIndex = 0 }
                selectedTextColor: Color.mOnSurface
                selectionColor: Color.mPrimary
                font.bold: true
                Component.onCompleted: {
                  contentItem.cursorColor = Color.mOnSurface
                  contentItem.verticalAlignment = TextInput.AlignVCenter
                  Qt.callLater(() => searchInput.forceActiveFocus())
                }
                Keys.onDownPressed: selectNext()
                Keys.onUpPressed: selectPrev()
                Keys.onEnterPressed: activateSelected()
                Keys.onReturnPressed: activateSelected()
                Keys.onEscapePressed: clipboardPanel.hide()
              }
            }
          }

          // list
          ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ListView {
              id: clipList
              anchors.fill: parent
              spacing: Style.marginXXS * scaling
              model: filteredEntries
              currentIndex: selectedIndex
              highlightMoveVelocity: -0.3

              delegate: Rectangle {
                width: clipList.width - Style.marginS * scaling
                height: 47 * scaling
                radius: Style.radiusM * scaling
                property bool isSelected: index === selectedIndex
                color: (ma.containsMouse || isSelected) ? Qt.darker(Color.mPrimary, 1.1) : Color.mSurface
                border.color: (ma.containsMouse || isSelected) ? Color.mPrimary : Color.transparent
                border.width: Math.max(1, (ma.containsMouse || isSelected) ? Style.borderM * scaling : 0)

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: Style.marginS * scaling
                  spacing: Style.marginM * scaling

                  // single line preview text
                  TextWidget {
                    Layout.fillWidth: true
                    text: modelData.name || ""
                    font.pointSize: Style.fontSizeXS * scaling
                    color: (ma.containsMouse || isSelected) ? Color.mOnPrimary : Color.mOnSurface
                    elide: Text.ElideRight
                  }
                }

                MouseArea {
                  id: ma
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: { selectedIndex = index; activateSelected() }
                }
              }
            }
          }

          // footer
          TextWidget {
            text: filteredEntries.length === 0 ? "No clipboard entries" :
                  `${filteredEntries.length} item${filteredEntries.length !== 1 ? 's' : ''}`
            font.pointSize: Style.fontSizeXS * scaling
            color: Color.mOnSurface
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
          }
        }
      }
    }
  }
}
