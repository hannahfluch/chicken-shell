pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Utils

Singleton {
  id: root

  property var connectedInterfaces: []
  property string icon:  "signal_disconnected";
  property string interfaceStr: "No available networks.";

  Component.onCompleted: {
    Logger.log("Network", "Service started")

    // initial set up
    update_interfaces.running = true;
    
    // listen for changes
    listener.running = true;
  }

  function updateIcon() {
    let current = "signal_disconnected";
    for (var i = 0; i < connectedInterfaces.length; i++) {
      const netint = connectedInterfaces[i];
      // prioritize wifi
      if (netint["type"] === "wifi") {
        current = "wifi"
        break;
      }
      else if (current !== "cable" && netint["type"] === "ethernet") {
        current = "cable"
      }
    }
    icon = current
  }

  function updateInterfaceStr() {
    let fmt = "";
    for (var i = 0; i < connectedInterfaces.length; i++) {
      const netint = connectedInterfaces[i];
      fmt += `${netint["interface"]}${netint["network"] ? `(${netint["network"]})` :  ""}: ${netint["inet4"] ?? "/"}\n`
    }
    interfaceStr = fmt;
  }
  

  property Process getInterfaceProcess: Process {
    id: update_interfaces
    running: false
    command: ["nmcli"] // gives the most overall info in one cmd
    stdout: StdioCollector {
      onStreamFinished: {
        Logger.log("Network", "Updating interfaces")
        root.connectedInterfaces = parseNmcli(text)
        updateIcon()
        updateInterfaceStr()
      }
    } 
  }

  
  property Process listenForNetworkChanges: Process {
    id: listener
    running: false
    command: ["nmcli", "device", "monitor"]
    stdout: SplitParser {
      onRead: function(line) {
        if (line.includes("connected") || line.includes("available")) {
          update_interfaces.running = true;
        }
      }
    } 
  }

  // since nmcli alone yields the most information in a single command!
  function parseNmcli(input) {
    const lines = input.split("\n");
    const results = [];
    let current = null;

    for (let raw of lines) {
      const line = raw.trim();

      // Start of an interface block
      const ifaceMatch = line.match(/^([a-zA-Z0-9\-]+): (connected|disconnected|unavailable)(?:\s+(?:\(externally\)\s+)?to\s+(.+))?/i);
      if (ifaceMatch) {
        // finalize previous
        if (current && current.connected) {
          results.push({
            interface: current.name,
            inet4: current.inet4 || null,
            type: current.deviceType || null,
            network: current.network || null
          });
        }
        // start new
        current = {
          name: ifaceMatch[1],
          connected: ifaceMatch[2].toLowerCase() === "connected",
          inet4: null,
          type: null,
          network: ifaceMatch[3]
        };
        continue;
      }

      if (!current) continue;

      // End of block on blank line
      if (line === "") {
        if (current.connected) {
          results.push({
            interface: current.name,
            inet4: current.inet4 || null,
            type: current.deviceType || null,
            network: current.network || null
          });
        }
        current = null;
        continue;
      }

      // Only extract details if connected
      if (current.connected) {
        // inet4 address
        const inet4Match = line.match(/^inet4\s+([\d.]+\/\d+)/i);
        if (inet4Match) current.inet4 = inet4Match[1];

        // device type: first word before "(" or "," if present
        const typeMatch = line.match(/^([a-zA-Z0-9\-]+)(?=\s*(\(|,|$))/);
        if (typeMatch) current.deviceType = typeMatch[1].toLowerCase();
      }
    }

    // finalize last block if file doesn't end with newline
    if (current && current.connected) {
      results.push({
        interface: current.name,
        inet4: current.inet4 || null,
        type: current.deviceType || null,
        network: current.network || null
      });
    }

    return results;
  }
}
