// shell.qml
import Quickshell
import qs.Modules.Bar
import qs.Modules.Panel
import qs.Modules.Notification

ShellRoot {
    id: shellRoot

    Bar {}
    Panel {
        id: panel
    }
    Notification {
        id: notification
    }
    NotificationHistoryPanel {
        id: notificationHistoryPanel
    }
}
