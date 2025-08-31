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
    property var wallpapers: [ ]
    property string directory: ""

    // map of monitor - wallpaper (currently only the main monitors wallpaper is applied)
    property var initialWallpapers: {} // set by compositor service

    // initialize the wallpaper service
    function initialize() {

        updateState();
                
        // Connect to CompositorService wallpaper changes
        CompositorService.wallpaperChanged.connect(updateColorscheme);
        // Initial sync
        updateColorscheme();
    }
    function updateState() {
        const focused = MonitorService.getFocusedMonitor();
        // try to get focused monitor otherwise fallback to default wallaper for other monitors
        const path = initialWallpapers[focused ? focused.name : "other"];
        if(!path) {
            Logger.error("WallpaperService", "Could not determine initial wallpaper! Aborting service...")
            return;
        }
        const parts = path.split("/");
        current = parts.pop();
        directory = parts.join("/") + "/";

        loaderProc.running = true;
    }
    Component.onCompleted: {
        Logger.log("Wallpaper", "Service started");
        // Connect to CompositorService intial wallpaper detection
        CompositorService.wallpaperInitialized.connect(initialize);
    }

    Connections {
        target: CompositorService
        function onIsHyprlandChanged() {
          isHyprland = CompositorService.isHyprland
        }
        function onIsNiriChanged() {
          isNiri = CompositorService.isNiri
        }
    }


    // Update the bars colors (triggered by compositor)
    function updateColorscheme() {
        Logger.log("WallpaperService", "updating color scheme: ", root.current)
        updateColors.running = true;
    }
    function choose(filename) {
        Logger.log("Wallpaper", "Updating current wallpaper...");
        root.spec = filename.substring(0, filename.lastIndexOf(".")) || filename
        root.current = filename;
        updater.running = true;
    } 
    function path(name) {
      return root.directory + name
    }

    // switches wallpapers
    Process {
        id: updater
        running: false
        command: ["sh", "-c", `${Quickshell.shellDir}/Scripts/switch-wallpaper.sh ${root.spec}`]

        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: (code, status) => {
            if (status !== 0) Logger.error("Could not update wallpaper status: ", status)
            else {
            // load directory of new specialisation
            updateState();
        }
        }
    }

    // updates the colorscheme using matugen
    Process {
        id: updateColors
        running: false
        command: ["matugen", "image", root.path(root.current), "--config", Quickshell.shellDir + "/Assets/Matugen/matugen.toml"]
    }

    // adds new wallpapers to list
    Process {
        id: loaderProc
        running: false
        command: ["ls", "-1", root.directory]
        stdout: StdioCollector {
            onStreamFinished: {
            const lines = (text ? text.split("\n") : [])
              .filter(l => l.trim() !== "");
            root.wallpapers = lines;  
            }
        }
    }
}
