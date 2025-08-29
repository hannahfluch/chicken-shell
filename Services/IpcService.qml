import QtQuick
import Quickshell.Io

Item {
  id: root
  IpcHandler {
    target: "appLauncher"

    function load() {
      appLauncherPanel.isLoaded = true
    }
  }
  IpcHandler {
    target: "clipboard"

    function load() {
      clipboardPanel.isLoaded = true
    }
  }
  
}
