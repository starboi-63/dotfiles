import QtQuick
import org.kde.taskmanager as TaskManager
import org.kde.plasma.workspace.dbus as DBus

QtObject {
    id: root

    required property string screenName
    readonly property var desktopIds: desktops.desktopIds
    readonly property var desktopNames: desktops.desktopNames
    property string currentDesktop: ""
    property string errorMessage: ""

    readonly property TaskManager.VirtualDesktopInfo desktops: TaskManager.VirtualDesktopInfo {
        onCurrentDesktopForScreenChanged: root.refreshCurrent()
        onCurrentDesktopChanged: root.refreshCurrent()
        onDesktopIdsChanged: root.refreshCurrent()
    }

    function refreshCurrent(): void {
        currentDesktop = desktops.currentDesktopByScreenName(screenName) || "";
    }

    function changeDesktop(position: int): void {
        if (position < 0 || position >= desktopIds.length) {
            throw new Error("Desktop position is unavailable.");
        }
        errorMessage = "";
        if (desktopIds[position] === currentDesktop) {
            return;
        }

        // Checks output selected by pointer before switching its desktop.
        DBus.SessionBus.asyncCall(new DBus.dbusMessage({service: "org.kde.KWin", path: "/KWin", interface: "org.kde.KWin",
            member: "activeOutputName"}), reply => {
            if (reply.value.value !== screenName) {
                errorMessage = "Move the pointer onto this monitor before switching desktops.";
                return;
            }
            DBus.SessionBus.asyncCall(new DBus.dbusMessage({service: "org.kde.KWin", path: "/KWin", interface: "org.kde.KWin",
                member: "setCurrentDesktop", arguments: [position + 1], signature: "(i)"}), reply => {
                if (reply.value !== true) {
                    // Distinguishes unchanged desktop from rejected selection after repeated clicks.
                    DBus.SessionBus.asyncCall(new DBus.dbusMessage({service: "org.kde.KWin", path: "/KWin", interface: "org.kde.KWin",
                        member: "currentDesktop"}), reply => {
                        if (reply.value.value !== position + 1) {
                            errorMessage = "KWin refused the desktop switch.";
                        }
                        refreshCurrent();
                    }, reply => { errorMessage = reply.error.message; });
                }
            }, reply => { errorMessage = reply.error.message; });
        }, reply => { errorMessage = reply.error.message; });
    }

    function createDesktop(): void {
        errorMessage = "";
        DBus.SessionBus.asyncCall(new DBus.dbusMessage({service: "org.kde.KWin", path: "/VirtualDesktopManager",
            interface: "org.kde.KWin.VirtualDesktopManager", member: "createDesktop",
            arguments: [desktopIds.length, ""], signature: "(us)"}), () => {},
            reply => { errorMessage = reply.error.message; });
    }

    onScreenNameChanged: refreshCurrent()
    Component.onCompleted: refreshCurrent()
}
