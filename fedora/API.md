# KDE integration notes

These notes explain KDE behavior that matters when maintaining the configuration. The [KWin](kwin/shortcuts/api.d.ts) and [Plasma](plasma/api.d.ts) TypeScript definitions describe the interfaces used by the scripts.

## Workspace and panel scripts

| Feature | How it works |
| --- | --- |
| [Workspaces](https://github.com/KDE/kwin/blob/v6.7.4/src/scripting/workspace_wrapper.cpp) | KWin does not report whether workspace creation or deletion succeeded, so the script checks the updated workspace list. Before deletion, it saves the workspace's ID so it can verify that the ID disappears from the list. |
| [Moving windows](https://github.com/KDE/kwin/blob/v6.7.4/src/window.h) | Confirms that a window moved before switching the monitor to its destination workspace. A window with an empty workspace list appears on every workspace. |
| [Shortcut registration](https://github.com/KDE/kwin/blob/v6.7.4/src/scripting/scripting.cpp) | Checks which action KDE associates with each assigned key combination. Reassigning a conflicting combination preserves the previous action's other shortcuts. |
| [Shifted shortcuts](https://github.com/KDE/kwin/blob/v6.7.4/src/xkb.cpp) | On a US keyboard, Shift+2 produces `@`. KWin matches that symbol, so `Shift+Alt+2` is registered as `Alt+@`. |
| [Panels and widgets](https://github.com/KDE/plasma-workspace/blob/v6.7.4/shell/scripting/containment.cpp) | Checks that creation succeeded and that moved widgets keep their IDs in the destination panel. Plasma may finish removing a widget after the removal call returns. |
| [Widget settings](https://github.com/KDE/plasma-workspace/blob/v6.7.4/shell/scripting/applet.cpp) | Checks that each setting was saved, then reads it using the expected type (such as number or boolean) and compares it with the requested value. |
| [Panel opacity](https://github.com/KDE/plasma-workspace/blob/v6.7.4/shell/scripting/panel.cpp) | Saves the panel's opacity mode in Plasma's configuration file, reloads those settings, and verifies the new mode. |
| [Widget order](https://github.com/KDE/plasma-desktop/blob/v6.7.4/containments/panel/LayoutManager.js) | Stores widget IDs in the desired order under `General/AppletOrder`. Plasma applies that order when it restarts. |
| [Window rules](https://github.com/KDE/kwin/blob/v6.7.4/src/rules.h) | Opens normal application windows unmaximized so Krohnkite can tile them. This rule applies when windows open and is placed after existing user rules. |

Running `scripts/configure.py` reloads the workspace shortcut script. Log out and back in to load Krohnkite code or settings changes.

## Bar and dock appearance

| Feature | How it works |
| --- | --- |
| [Workspace selection](plasma/bar/contents/ui/DesktopModel.qml) | Clicking the active workspace does nothing. If KWin reports a failed switch, the widget checks the current workspace before showing an error. |
| [Tooltips](https://github.com/KDE/libplasma/blob/v6.7.4/src/declarativeimports/core/tooltiparea.cpp) | Shows the application name (`AppName`) above the window title (`display`) in Plasma's tooltip popup. |
| [Backgrounds](https://github.com/KDE/plasma-desktop/blob/v6.7.4/desktoppackage/contents/views/Panel.qml) | Adjusts opacity across Plasma's six panel backgrounds. Breeze supplies shape, blur, shadows, and outer spacing. Disabling or removing the customization returns control of opacity to the theme. |
| [Panel attachment](plasma/shared/PanelAttachment.qml) | Tracks the complete widget ancestry and panel backgrounds through QML bindings. Restores appearance after delayed startup, container moves, and display reconnection. |
| [Dock appearance](plasma/dock/contents/ui/main.qml) | Changes the dock's background opacity. The helper's icon appears during panel editing or when it reports an error. |
| [Floating space](https://github.com/KDE/plasma-workspace/blob/v6.7.4/shell/panelview.h) | Reserves room for the bar and the gap above it so tiled windows stay below both. Updates that space immediately as the bar changes and restores Plasma's usual spacing when removed. |
| [Tray sizing](https://github.com/KDE/plasma-workspace/blob/v6.7.4/applets/systemtray/qml/main.qml) | Keeps icons at the configured size and spacing as tray entries change. Plasma's existing [icon containers](https://github.com/KDE/plasma-workspace/blob/v6.7.4/applets/systemtray/qml/AbstractItem.qml) handle clicks and popups. |
| [Clock](https://github.com/KDE/plasma-workspace/blob/v6.7.4/applets/digital-clock/main.xml) | Sets the font and date format through Plasma's digital clock settings. |
