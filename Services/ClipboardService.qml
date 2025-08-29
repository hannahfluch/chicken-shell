pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Utils
import qs.Services

Singleton {
  id: root

  property var history: []          // [{ id: "123", preview: "..." }]
  property bool initialized: false

  Process {
    id: listProcess
    stdout: StdioCollector {}
    stderr: StdioCollector {}
    onExited: (code, status) => {
      const text = String(stdout.text || "").trim()
      const lines = text ? text.split("\n") : []
      const out = []
      for (let i = 0; i < lines.length; i++) {
        const line = lines[i]
        if (!line) continue
        // cliphist format: "<id>\t<preview>"
        const tab = line.indexOf("\t")
        if (tab === -1) {
          out.push({ id: line.trim(), preview: "" })
        } else {
          const id = line.slice(0, tab).trim()
          const preview = line.slice(tab + 1)
          out.push({ id: id, preview: preview })
        }
      }
      root.history = out
      root.initialized = true
    }
  }

  function refresh() {
    listProcess.command = [ "cliphist", "list" ]
    listProcess.running = true
  }

  function copyById(id) {
    if (!id) return
    Quickshell.execDetached([
      "sh", "-lc",
      `cliphist decode ${id} | wl-copy`
    ])
  }
}
