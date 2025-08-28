pragma Singleton

import Quickshell
import qs.Utils
import qs.Services

Singleton {
    id: root
    // -------------------------------------------
    // Manual scaling via Settings
    function scale(aScreen) {
        Logger.log("Scaling", aScreen.name)
        try {
            return MonitorService.getMonitorByName(aScreen.name).scale;
        }catch (e) {
            Logger.warn(e)
        }
        return Settings.data.general.defaultScale;
    }
    // -------------------------------------------
    // Dynamic scaling based on resolution

    // Design reference resolution (for scale = 1.0)
    readonly property int designScreenWidth: 2560
    readonly property int designScreenHeight: 1440

    // Design reference resolution (for scale = 1.3)
    // readonly property int designScreenWidth: 1969
    // readonly property int designScreenHeight: 1107

    // todo: proper scaling
    function dynamic(aScreen) {
        var ratioW = aScreen.width / (designScreenWidth / Settings.data.general.defaultScale);
        var ratioH = aScreen.height / (designScreenHeight / Settings.data.general.defaultScale);
        return Math.min(ratioW, ratioH);
    }
}
