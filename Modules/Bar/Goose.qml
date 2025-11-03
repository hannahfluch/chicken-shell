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

    icon: GooseService.icon
    onClicked: function () {
        GooseService.render = !GooseService.render;
    }
}
