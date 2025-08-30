pragma Singleton

import QtQuick
import Quickshell
import qs.Utils
import qs.Services

Singleton {
  id: root

  // Delegate to CompositorService for all monitor operations
  property var monitors: []
  property bool isHyprland: false
  property bool isNiri: false

  function getMonitorByName(name) {
    for (var i = 0; i < monitors.length; i++) {
        const m = monitors[i];
        if (m.name === name) return m;
    }
    return null;
  }
  function getFocusedMonitor() {
    return CompositorService.focusedMonitorIndex === -1 ? null : monitors[CompositorService.focusedMonitorIndex];
  }

  Component.onCompleted: {
    // Connect to CompositorService monitor changes
    CompositorService.monitorListChanged.connect(updateMonitors)
    // Initial sync
    updateMonitors()
  }

  // Listen to compositor detection changes
  Connections {
    target: CompositorService
    function onIsHyprlandChanged() {
      isHyprland = CompositorService.isHyprland
    }
    function onIsNiriChanged() {
      isNiri = CompositorService.isNiri
    }
  }

  function updateMonitors() {
    monitors = [];
    for (var i = 0; i < CompositorService.monitors.length; i++) {
      const m = CompositorService.monitors[i];
      monitors.push(m)
    }
  }
}
