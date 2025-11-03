pragma Singleton

import QtQuick
import Quickshell
import qs.Utils

Singleton {
    id: root

    property string icon: root.render ? "egg" : "egg_alt"
    property bool render:false

    Component.onCompleted: {
        Logger.log("Goose", "Service started")
        root.render = true
    }
}
