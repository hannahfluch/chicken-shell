pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Utils
import qs.Services

Singleton {
    id: root

    property bool volumeOverdrive: false

    property string shellName: "chicken-shell"
    property string cacheDir: Quickshell.env("XDG_CACHE_HOME") + "/" + shellName + "/"
    property string dataDir: Quickshell.env("XDG_DATA_HOME") + "/" + shellName + "/"
    property string dataFile: dataDir + "state.json" // stuff like active wallpaper...
    property string colorFile: dataDir + "colors.json" // colors for bar generated using matugen
    // Used to access via Settings.data.xxx.yyy
    property alias data: adapter

    FileView {
        path: dataFile
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        Component.onCompleted: function () {
            reload();
        }
        onLoaded: function () {
            Logger.log("Settings", "OnLoaded");
        }
        onLoadFailed: function (error) {
            if (error.toString().includes("No such file") || error === 2)
                // File doesn't exist, create it with default values
                writeAdapter();
        }

        JsonAdapter {
            id: adapter

            // bar
            property JsonObject bar

            bar: JsonObject {
                property bool top: true
                property bool showNotificationsHistory: true
                property real backgroundOpacity: 1.0
                property list<string> monitors: []
            }

            // general
            property JsonObject general
            general: JsonObject {
                property bool dimDesktop: true
                property real defaultScale: 1.3333
            }

            // Scaling (not stored inside JsonObject, or it crashes)
            property var monitorsScaling: {}

            // brightness
            property int brightnessStep: 5

            // notifications
            property JsonObject notifications
            notifications: JsonObject {
                property list<string> monitors: []
                property bool suppressed: false
            }
        }
    }
}
