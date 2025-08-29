import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Utils
import qs.Widgets

LoaderWidget {
  id: wallpapaerChooser
  isLoaded: false
  // Clipboard state is persisted in Services/ClipboardService.qml
  content: Component {
    PanelWidget {
      id: wallpaperChooserPanel

      WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
     }
     }
    }
