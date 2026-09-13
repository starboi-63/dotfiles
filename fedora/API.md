# KDE integration notes

The TypeScript declarations cover the APIs this repository consumes. They were checked against KDE 6.7.4 source; they are maintained locally, not supplied by KDE. Strict compilation checks our declarations, while runtime readbacks catch observable failures. Neither proves that an API remains compatible after a KDE update.

## KWin and Plasma scripts

| Interface | Contract |
| --- | --- |
| [KWin workspace](https://github.com/KDE/kwin/blob/v6.7.4/src/scripting/workspace_wrapper.cpp) | Desktop creation, removal, and per-output selection return void. Check resulting state. Output and current-desktop handles may be absent. Save desktop IDs before removal invalidates handles. |
| [KWin windows](https://github.com/KDE/kwin/blob/v6.7.4/src/window.h) | Desktop membership is writable. An empty list means all desktops. Check assignment before following a moved window. |
| [Shortcut registration](https://github.com/KDE/kwin/blob/v6.7.4/src/scripting/scripting.cpp) | Registration success does not confirm a key assignment. The configurator checks KGlobalAccel ownership and retained alternatives separately. |
| [Shifted shortcuts](https://github.com/KDE/kwin/blob/v6.7.4/src/xkb.cpp) | KWin removes consumed Shift when matching punctuation. Physical chords and stored shortcut strings can differ. |
| [Panel and widget creation](https://github.com/KDE/plasma-workspace/blob/v6.7.4/shell/scripting/containment.cpp) | Creation can return an error or missing handle. Moving an existing widget should preserve its ID and change panel membership. Removal is deferred. |
| [Widget configuration](https://github.com/KDE/plasma-workspace/blob/v6.7.4/shell/scripting/applet.cpp) | Reads return QVariant values; writes and reloads return void. Check key presence before supplying a typed default, which can otherwise conceal a rejected write. |
| [Panel settings](https://github.com/KDE/plasma-workspace/blob/v6.7.4/shell/scripting/panel.cpp) | The 6.7.4 opacity setter targets the wrong native property. Write `panelOpacity` through KConfig and reload panel settings before checking the result. |
| [Panel order](https://github.com/KDE/plasma-desktop/blob/v6.7.4/containments/panel/LayoutManager.js) | Save `General/AppletOrder` explicitly. The scripted widget index setter does not establish order in 6.7.4; reload Plasma to apply it. |

The initial-window rule uses Apply Initially (`3`) to clear startup maximization for normal, non-transient windows. It preserves later user maximization. Registration appends its group to existing `General/rules` entries. See [rule policies](https://github.com/KDE/kwin/blob/v6.7.4/src/rules.h).

Krohnkite must load new code or preferences at a normal login. Live unloading caused a compositor crash during development. The configurator reloads only the separate workspace shortcut helper.

## QML adapters

- **Workspace selection.** Native `setCurrentDesktop` returns false when the desktop is already selected. Skip known no-ops and read current state after a false reply. Output selection and switching are separate D-Bus calls, so an intervening output change remains a multi-monitor race.
- **Tooltips.** Task Manager exposes application names through `AppName` and captions through `display`. Keep text plain. Native [ToolTipArea](https://github.com/KDE/libplasma/blob/v6.7.4/src/declarativeimports/core/tooltiparea.cpp) creates a separate popup window; an in-panel popup can cover its trigger and repeatedly cancel hover.
- **Backgrounds.** [Panel.qml](https://github.com/KDE/plasma-desktop/blob/v6.7.4/desktoppackage/contents/views/Panel.qml) exposes six theme background items. Shared opacity bindings preserve object identity during rediscovery and restore native bindings when disabled or removed. Incompatible structure produces an error. The dock helper uses `HiddenStatus` outside edit mode; hidden containers may retain dimensions while being excluded from layout.
- **Floating space.** [PanelView](https://github.com/KDE/plasma-workspace/blob/v6.7.4/shell/panelview.h) provides thickness, visibility, and edit state. `LayerShell.Window.exclusionZone` reserves thickness plus the theme's floating inset. Update synchronously before the Wayland geometry commit; deferred changes did not reliably trigger tiling. Equal assignments must avoid repeated writes, and teardown restores native reservation.
- **Tray sizing.** [System tray](https://github.com/KDE/plasma-workspace/blob/v6.7.4/applets/systemtray/qml/main.qml) aliases expose layouts and native [icon containers](https://github.com/KDE/plasma-workspace/blob/v6.7.4/applets/systemtray/qml/AbstractItem.qml). Retain each loader's bindings across item insertion and removal. Recreating every override lets deferred cleanup restore oversized native icons. Keep input handlers and popup state native.

Breeze supplies panel shape, blur, shadow, and floating insets. The native digital clock uses its [configuration schema](https://github.com/KDE/plasma-workspace/blob/v6.7.4/applets/digital-clock/main.xml). These adapters intentionally avoid replacing the clock or tray popup implementations. Other themes or Plasma versions need a fresh compatibility check.
