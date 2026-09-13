# KDE integration notes

The [KWin](kwin/shortcuts/api.d.ts) and [Plasma](plasma/api.d.ts) declarations describe the APIs used by this configuration. Runtime readbacks verify desktop, panel, and shortcut changes.

## KWin and Plasma scripts

| Interface | Integration |
| --- | --- |
| [KWin workspace](https://github.com/KDE/kwin/blob/v6.7.4/src/scripting/workspace_wrapper.cpp) | Desktop operations return `void`. Readbacks verify desktop counts and selection. IDs are saved before removal invalidates handles. |
| [KWin windows](https://github.com/KDE/kwin/blob/v6.7.4/src/window.h) | Desktop membership is writable. An empty list means all desktops. Movement checks the assignment before following the window. |
| [Shortcut registration](https://github.com/KDE/kwin/blob/v6.7.4/src/scripting/scripting.cpp) | Registers KWin actions. KGlobalAccel readbacks verify key ownership and preserve unrelated alternate shortcuts. |
| [Shifted shortcuts](https://github.com/KDE/kwin/blob/v6.7.4/src/xkb.cpp) | KWin removes consumed Shift when matching punctuation. On a US layout, `Shift+Alt+2` is stored as `Alt+@`. |
| [Panel and widget creation](https://github.com/KDE/plasma-workspace/blob/v6.7.4/shell/scripting/containment.cpp) | Validates object type, ID, and panel membership. Moving a widget preserves its ID. Removal is deferred. |
| [Widget configuration](https://github.com/KDE/plasma-workspace/blob/v6.7.4/shell/scripting/applet.cpp) | Reads return QVariant values. Writes and reloads return `void`. Verification checks key presence and typed readbacks. |
| [Panel settings](https://github.com/KDE/plasma-workspace/blob/v6.7.4/shell/scripting/panel.cpp) | Saves `panelOpacity` through KConfig, reloads panel settings, and checks the applied opacity. |
| [Panel order](https://github.com/KDE/plasma-desktop/blob/v6.7.4/containments/panel/LayoutManager.js) | Saves widget IDs in `General/AppletOrder`. Restarting Plasma applies the saved order. |
| [Window rules](https://github.com/KDE/kwin/blob/v6.7.4/src/rules.h) | Uses Apply Initially (`3`) to clear startup maximization for normal, non-transient windows. Registration appends the rule after existing `General/rules` entries. |

The configurator reloads the workspace shortcut helper. Krohnkite loads code and settings at login.

## QML adapters

| Component | Integration |
| --- | --- |
| [Workspace selection](plasma/bar/contents/ui/DesktopModel.qml) | Skips already-selected desktops. A false D-Bus reply triggers a readback of the current desktop. |
| [Tooltips](https://github.com/KDE/libplasma/blob/v6.7.4/src/declarativeimports/core/tooltiparea.cpp) | Uses `AppName` for application names and `display` for window titles. Native `ToolTipArea` shows plain text in a separate popup. |
| [Backgrounds](https://github.com/KDE/plasma-desktop/blob/v6.7.4/desktoppackage/contents/views/Panel.qml) | Opacity bindings track six theme backgrounds and restore native bindings when disabled or removed. Breeze supplies shape, blur, shadows, and floating insets. |
| [Dock appearance](plasma/dock/contents/ui/main.qml) | Uses `HiddenStatus` during normal operation. The helper becomes visible during panel editing or when it reports an error. |
| [Floating space](https://github.com/KDE/plasma-workspace/blob/v6.7.4/shell/panelview.h) | `LayerShell.Window.exclusionZone` reserves panel thickness plus the floating inset. Synchronous updates keep tiling aligned with panel geometry. Teardown restores native reservation. |
| [Tray sizing](https://github.com/KDE/plasma-workspace/blob/v6.7.4/applets/systemtray/qml/main.qml) | Preserves each [icon container's](https://github.com/KDE/plasma-workspace/blob/v6.7.4/applets/systemtray/qml/AbstractItem.qml) bindings across item insertion and removal. Native tray controls handle input and popups. |
| [Clock](https://github.com/KDE/plasma-workspace/blob/v6.7.4/applets/digital-clock/main.xml) | Uses Plasma's digital clock configuration for font and date formatting. |
