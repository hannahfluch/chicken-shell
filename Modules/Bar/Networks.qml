import QtQuick
import Quickshell
import qs.Utils
import qs.Services
import qs.Widgets

IconButtonWidget {
    id: root

    sizeMultiplier: 0.8
    visible: true

    colorBg: Color.mSurfaceVariant
    colorFg: Color.mOnSurface
    colorBorder: Color.transparent
    colorBorderHover: Color.transparent

    icon: NetworkService.icon
    tooltipText: NetworkService.interfaceStr
}
