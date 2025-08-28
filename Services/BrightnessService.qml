pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Utils

Singleton {
    id: root

    property string icon: "brightness_alert"
    property string percentage: "..."

    Component.onCompleted: {
    Logger.log("Brightness", "Service started")
    // initial set up
    update_brightness.running = true;

    // listen for changes
    listener.running = true;
    }

    property Process updateBrightnessProcess: Process {
        id: update_brightness
        running: false
        command: ["brightnessctl"]
        stdout: StdioCollector {
            onStreamFinished: {
            Logger.log("Brightness", "Updating percentage")

            const p = text.match(/\d+%/gm)[0]
            root.percentage = p;
            root.icon = `brightness_${Math.min(7, Math.max(1, Math.floor(parseInt(p, 10) / (100 / 7)) + 1))}`;
            }
        }
    }
    property Process listenForBrightnessChanges: Process {
        id: listener
        running: false
        command: ["udevadm" ,"monitor" ,"--udev" ,"--subsystem-match=backlight"]
        stdout: SplitParser {
            onRead: update_brightness.running = true;
        }
    }

    property Process increaseBrightness: Process {
        id: increase
        running: false
        command: ["brightnessctl", "set", `${Settings.data.brightnessStep}%+`]
    }
    property Process decreaseBrightness: Process {
        id: decrease
        running: false
        command: ["brightnessctl", "set", `${Settings.data.brightnessStep}%-`]
    }

    function changeBrightness(increaseBrightness) {
        if (increaseBrightness) increase.running = true;
        else decrease.running = true; 
     }
}
