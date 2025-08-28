import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.Utils
import qs.Modules.Panel
import qs.Services
import qs.Widgets

Item {
    id: root

    width: pill.width
    height: pill.height

    // Used to avoid opening the pill on Quickshell startup
    property bool firstVolumeReceived: false

    function getIcon() {
        if (AudioService.muted) {
            return "volume_off";
        }
        return AudioService.volume <= Number.EPSILON ? "volume_off" : (AudioService.volume < 0.33 ? "volume_down" : "volume_up");
    }

    // Connection used to open the pill when volume changes
    Connections {
        target: AudioService.sink?.audio ? AudioService.sink?.audio : null
        function onVolumeChanged() {
            // Logger.log("Bar:Volume", "onVolumeChanged")
            if (!firstVolumeReceived) {
                // Ignore the first volume change
                firstVolumeReceived = true;
            } else {
                pill.show();
                externalHideTimer.restart();
            }
        }
    }

    Timer {
        id: externalHideTimer
        running: false
        interval: 1500
        onTriggered: {
            pill.hide();
        }
    }

    PillWidget {
        id: pill
        icon: getIcon()
        iconCircleColor: Color.mPrimary
        collapsedIconColor: Color.mOnSurface
        autoHide: false // Important to be false so we can hover as long as we want
        text: Math.floor(AudioService.volume * 100) + "%"
        tooltipText: "Volume: " + Math.round(AudioService.volume * 100) + "%\nLeft click for advanced settings.\nRight click to toggle mute.\nScroll up/down to change volume."

        onWheel: function (angle) {
            if (angle > 0) {
                AudioService.increaseVolume();
            } else if (angle < 0) {
                AudioService.decreaseVolume();
            }
        }
        onClicked: mouse => {
            switch (mouse.button) {
            // left button: advanced settings
            case Qt.LeftButton:
                panel.requestedTab = Panel.Tab.AudioService;
                panel.isLoaded = true;
                break;
            // right button: toggle mute
            case Qt.RightButton:
                if (AudioService.sink && AudioService.sink.audio) {
                    AudioService.sink.audio.muted = !AudioService.sink.audio.muted;
                }

                break;
            }
        }
    }
}
