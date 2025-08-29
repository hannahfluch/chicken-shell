pragma Singleton

import Quickshell.Io
import QtQuick
import Quickshell
import qs.Utils
import qs.Services

Singleton {
    id: root

    // Delegate to CompositorService for detection operations
    property bool isHyprland: false
    property bool isNiri: false
    property string spec: ""
    property string current: ""
    property string prev: "placeholder"
    property var wallpapers: [ ]
    property string directory: Quickshell.env("WALLPAPER_PATH") 
    function setWallpaper(name) {
        Logger.log("Wallpaper", "Setting new...");
    }

    Component.onCompleted: {
        Logger.log("Wallpaper", "Service started");
        // Connect to CompositorService monitor changes
        CompositorService.wallpaperChanged.connect(updateColorscheme);
        // Initial sync
        updateColorscheme();
    }

    // Update the bars colors (triggered by compositor)
    function updateColorscheme() {
        updateColors.running = true;
    }
    function choose(filename) {
        Logger.log("Wallpaper", "Updating current wallpaper...");
        root.spec = filename.substring(0, filename.lastIndexOf(".")) || filename
        if (root.spec !== root.prev) {
            root.current = filename;
            updater.running = true;
        }
        else {
          Logger.warn("Wallpaper", "User is asking to switch to same wallpaper");
        }
    } 
    function path(name) {
      return root.directory + name
    }

    Process {
        id: updater
        running: false
        command: ["sh", "-c", `${Quickshell.shellDir}/Scripts/switch-wallpaper.sh ${root.spec}`]

        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: (code, status) => {
            if (status !== 0) Logger.error("Could not update wallpaper status: ", status)
            else {
            root.prev = root.spec
        }
        }
    }

    Process {
        id: updateColors
        running: false
        command: ["matugen", "image", root.path(root.current), "--config", Quickshell.shellDir + "/Assets/Matugen/matugen.toml"]
    }
    
    Process {
        id: loaderProc
        running: true
        command: ["ls", "-1", root.directory]
        stdout: StdioCollector {
            onStreamFinished: {
            const lines = (text ? text.split("\n") : [])
              .filter(l => l.trim() !== "");
            root.wallpapers = lines;  
            loaderProc.running = false
            }
        }
    }
}
