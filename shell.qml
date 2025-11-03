// shell.qml
import Quickshell
import qs.Modules.Bar
import qs.Modules.Goose
import qs.Modules.Panel
import qs.Modules.Notification
import qs.Modules.Launcher
import qs.Services

ShellRoot {
    id: shellRoot

    Bar {}
    Goose {}
    Panel {
        id: panel
    }
    Notification {
        id: notification
    }
    NotificationHistoryPanel {
        id: notificationHistoryPanel
    }
    AppLauncher { id: appLauncherPanel }
    Clipboard { id: clipboardPanel }

    IpcService { }
    WallpaperChooser { id: wallpaperChooser }
}
