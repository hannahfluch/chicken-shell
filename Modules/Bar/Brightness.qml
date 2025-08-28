import QtQuick
import Quickshell
import qs.Utils
import qs.Widgets
import qs.Services

IconButtonWidget {
    id: root

    sizeMultiplier: 0.8
    visible: true

    colorBg: Color.mSurfaceVariant
    colorFg: Color.mOnSurface
    colorBorder: Color.transparent
    colorBorderHover: Color.transparent

    icon: BrightnessService.icon
    tooltipText: "Brightness: "+ BrightnessService.percentage+"\nScroll up/down to change brightness."
    onWheel: function (angle) {
            if (angle > 0) {
                BrightnessService.changeBrightness(true);
            } else if (angle < 0) {
                BrightnessService.changeBrightness(false);
            }
    
    }
}
