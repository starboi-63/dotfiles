# KDE API contracts

The declarations describe only APIs consumed by these scripts. They were checked against KDE 6.7.4 source, matching this machine's KWin and Plasma packages. They are maintained declarations, not types supplied or guaranteed by KDE.

TypeScript checks our use of that declared contract. It cannot prove that the installed binaries match upstream source, that an output remains connected, or that a requested operation finishes successfully. Runtime checks cover observable failures, and native integration remains a separate verification step.

## KWin

| Declaration | Source | Contract |
| --- | --- | --- |
| Workspace desktop and window properties | [workspace_wrapper.h](https://github.com/KDE/kwin/blob/v6.7.4/src/scripting/workspace_wrapper.h) | Desktop list is read-only. Current desktop and active window are writable object pointers. Pointer results are treated conservatively as nullable. |
| Desktop queries and mutations | [workspace_wrapper.cpp](https://github.com/KDE/kwin/blob/v6.7.4/src/scripting/workspace_wrapper.cpp) | `currentDesktopForScreen` can return null. Creation, removal, and selection return void. They do not acknowledge successful state changes. |
| Window properties | [window.h](https://github.com/KDE/kwin/blob/v6.7.4/src/window.h) | Output is read-only and initialized as null. Desktop membership is writable. An empty desktop list represents all desktops. |
| Desktop identity | [virtualdesktops.h](https://github.com/KDE/kwin/blob/v6.7.4/src/virtualdesktops.h) | Desktop IDs are read-only strings and identify desktops across wrapper instances. |
| Shortcut registration | [scripting.cpp](https://github.com/KDE/kwin/blob/v6.7.4/src/scripting/scripting.cpp) | Returns a boolean and invokes callbacks with a QAction. `true` reports callback registration, not successful assignment of a particular keyboard chord. |
| Plasma bridge | [scripting.cpp](https://github.com/KDE/kwin/blob/v6.7.4/src/scripting/scripting.cpp) | `callDBus` dispatches asynchronously. Its success callback is not called on D-Bus failure; KWin logs that failure. The bundled Plasma toggle checks native panel readbacks. |
| Shifted symbols | [xkb.cpp](https://github.com/KDE/kwin/blob/v6.7.4/src/xkb.cpp) | Global matching removes consumed Shift for punctuation. Focused application events and global shortcut encodings differ for Shift+2 on the tested US layout. |

`KWinOutput` is an opaque handle. Its private declaration prevents accidental substitution of another object type without inventing public runtime properties. The declaration emits no JavaScript.

Runtime checks reject missing output or desktop handles, unknown desktop IDs, and unsupported per-screen APIs. An unknown current desktop no longer falls through to desktop one when moving forward. Desktop removal captures the target ID before KWin can invalidate that handle.

After a mutation, the helper checks desktop count or membership, window assignment, desktop selection, and focus as applicable. Window movement must be observed before following it. These checks detect rejection; they cannot undo earlier successful operations or rule out subsequent changes by other scripts.

## Plasma

| Declaration | Source | Contract |
| --- | --- | --- |
| `panels`, `desktops`, and `Panel` | [scriptengine_v1.cpp](https://github.com/KDE/plasma-workspace/blob/v6.7.4/shell/scripting/scriptengine_v1.cpp) | Queries construct JavaScript arrays. Panel creation can return an Error object. Desktops include activity containments, so screen IDs are deduplicated and inactive screens are excluded. |
| Widget discovery and creation | [containment.cpp](https://github.com/KDE/plasma-workspace/blob/v6.7.4/shell/scripting/containment.cpp) | `widgets` can return undefined for a missing containment. `addWidget` can return a widget, an Error object, or undefined. |
| Widget movement | [containment.cpp](https://github.com/KDE/plasma-workspace/blob/v6.7.4/shell/scripting/containment.cpp) | Passing an existing widget to `addWidget` moves its applet and returns its wrapper. Membership in both panels and preservation of its ID are checked. |
| Widget properties | [widget.h](https://github.com/KDE/plasma-workspace/blob/v6.7.4/shell/scripting/widget.h) | Widget ID, type, and configuration keys are read-only. Configuration group is writable. Removal returns void. |
| Configuration reads and writes | [applet.cpp](https://github.com/KDE/plasma-workspace/blob/v6.7.4/shell/scripting/applet.cpp) | Reads return QVariant values. Writes and reloads return void. A missing key can return the supplied default. |
| Panel property values | [panel.h](https://github.com/KDE/plasma-workspace/blob/v6.7.4/shell/scripting/panel.h), [panel.cpp](https://github.com/KDE/plasma-workspace/blob/v6.7.4/shell/scripting/panel.cpp) | Declarations preserve accepted location, visibility, length, alignment, and opacity strings. Numeric properties remain numbers. |
| Digital clock configuration | [digital-clock/main.xml](https://github.com/KDE/plasma-workspace/blob/v6.7.4/applets/digital-clock/main.xml) | `dateDisplayFormat` and `showSeconds` are three-value enums. `use24hFormat` is an unsigned integer. Other consumed keys retain their schema types. |
| Task filtering | [taskmanager/main.xml](https://github.com/KDE/plasma-desktop/blob/v6.7.4/applets/taskmanager/main.xml) | Both screen and desktop filters are booleans in group `General`. |

`readConfig` returns `unknown`. The declaration does not promise that its return value has the default's type. Configuration checks confirm that a key exists before supplying a typed default and comparing values. Otherwise a failed write could appear successful because the default equals the requested value.

Required widget availability, screen IDs, the reference height, and duplicate panel matches are checked before mutations. New widget handles and panel property assignments are checked afterward. Creation messages include panel IDs so a partial failure remains traceable.

Widget removal and configuration reload have no completion acknowledgement. [Widget removal](https://github.com/KDE/plasma-workspace/blob/v6.7.4/shell/scripting/widget.cpp) requests applet destruction and clears its wrapper's handle, so the script records the ID before removal. It reports removal as requested and does not claim that an immediate query proves its completion. Property and configuration readbacks likewise do not prove final geometry, visual appearance, or persistence across login.

## Initial window state

KWin [rule policies](https://github.com/KDE/kwin/blob/v6.7.4/src/rules.h) encode Apply Initially as `3`. The `initial-tiling` rule clears horizontal and vertical maximization only at initial mapping. The normal-window mask is `1`; exact transient-parent matching excludes child windows even when Wayland reports their type as normal. The [rule registry](https://github.com/KDE/kwin/blob/v6.7.4/src/rulebooksettings.cpp) reads group IDs from `General/rules`. Registration appends our group without replacing existing rule priority. Reconfiguration does not unmaximize existing windows or reload Krohnkite when its settings are unchanged.

## QML and panel internals

The desktop model uses Task Manager's per-screen desktop IDs and KWin D-Bus calls. Native [setCurrentDesktop](https://github.com/KDE/kwin/blob/v6.7.4/src/dbusinterface.cpp) returns false for an already selected desktop. The widget skips known no-ops and reads the actual desktop after a false reply to distinguish repeated-click races from rejected switches. QML D-Bus message signatures and reply wrappers were checked in live tests.

Window delegates use Task Manager's `AppName` and `display` roles for application names and captions. Text is explicitly plain text. The compact tooltip wraps long titles and caps its width at 360 logical pixels. `PanelToolTip.qml` uses native [ToolTipArea](https://github.com/KDE/libplasma/blob/v6.7.4/src/declarativeimports/core/tooltiparea.cpp) hover handling and a separate, non-interactive tooltip window. `TopEdge` places the popup below the panel. The previous Qt Controls popup was constrained inside the panel scene and interrupted hover by covering its own icon. CPU and network readings use installed `KSysGuard::Sensor` properties `status`, `formattedValue`, and `updateRateLimit`. Sensor IDs match KDE's bundled CPU and network widgets.

Plasma's scripted widget `index` setter is unimplemented in 6.7.4. The panel script saves `General/AppletOrder`, consumed by [LayoutManager.js](https://github.com/KDE/plasma-desktop/blob/v6.7.4/containments/panel/LayoutManager.js) on startup. Initial widget migration therefore requires a shell restart. Clock settings are applied before movement to avoid writing through its old configuration schema after migration.

`PanelAppearance.qml` finds an ancestor with `floating` and `floatingnessTarget`, then requires the six background items in [Panel.qml](https://github.com/KDE/plasma-desktop/blob/v6.7.4/desktoppackage/contents/views/Panel.qml). Bindings multiply the background layers' opacity without changing icons, masks, or blur. Binding destruction restores prior values. After native state changes, the adapter restores the requested floating margin target and applet hint. Disabling the option or removing the component lets native panel behavior resume.

`TrayAppearance.qml` finds the native tray through its `systemTrayState`, `visibleLayout`, and `hiddenLayout` aliases in [systemtray/main.qml](https://github.com/KDE/plasma-workspace/blob/v6.7.4/applets/systemtray/qml/main.qml). It changes GridView cell width and the `iconContainer` dimensions exposed by [AbstractItem.qml](https://github.com/KDE/plasma-workspace/blob/v6.7.4/applets/systemtray/qml/AbstractItem.qml). Full delegate input regions remain intact. Discovery stops after five seconds and reports an incompatible layout.

A stable `ListModel` retains each loader's binding objects across native `childrenChanged` signals. A direct children-list model recreated overrides for unchanged icons, and deferred cleanup restored their native size after replacement overrides had attached. This sequence reproduced the startup regression in real Qt. Loader insertion and removal now update individual model rows. Changes to each Loader's `item` still redirect its bindings when content is recreated. Adapter teardown explicitly disables overrides before destruction so native dimensions, spacing, and arrow visibility are restored.

The native [ExpanderArrow.qml](https://github.com/KDE/plasma-workspace/blob/v6.7.4/applets/systemtray/qml/ExpanderArrow.qml) retains its input handlers, accessibility, and popup state. The adapter hides its two overlapping glyphs and supplies one chevron with a 140-millisecond rotation. System animation disabling is honored. Native popup animations remain unchanged. Qt input tests verified icon dimensions, chevron opening and closing, and five applet popups after these adjustments.

These private properties are not guaranteed across Plasma versions or panel implementations. An incompatible background inventory or tray layout produces a visible error. The adapters have been checked on the current Breeze panel; other versions and themes need another live check.

## Verification

`PanelReservation.qml` uses the installed `org.kde.layershell` module's attached `Window.exclusionZone` property on the existing panel window. This property is defined by [LayerShellQt::Window](https://api.kde.org/legacy/plasma/layer-shell-qt/html/window_8h_source.html). The adapter reads Plasma's `thickness`, `visibilityMode`, and `userConfiguring` properties from [PanelView](https://github.com/KDE/plasma-workspace/blob/v6.7.4/shell/panelview.h), plus the checked panel QML floating inset. `NormalPanel` has enum value zero. It reserves thickness plus the inset and requests a panel repaint to commit the Wayland state.

Reservation changes are applied synchronously before the panel geometry commit. Deferred updates changed the reported work area but did not reliably trigger tiling. Synchronous updates passed repeated native ChatGPT geometry checks. Equal assignments do not write again. Native edit mode and disabled reservations are respected, and adapter removal restores the native reservation. Owned QML `Connections` disconnect on destruction. This code executes in Plasma and does not add KWin scripts, reload Krohnkite, or write application window geometry.

The type fixtures require compiler rejection of missing null checks, unchecked array access, invalid panel modes, incorrect clock values, unhandled creation failures, and use of globals from another runtime. Unused `@ts-expect-error` directives fail compilation if these restrictions are lost.

Runtime tests execute the generated JavaScript against independent in-memory substitutes. They cover normal workspace movement, boundaries, missing objects, refused mutations, panel reuse across screens, unrelated widget preservation, ambiguous layouts, failed creation, and rejected writes. They do not execute KWin, Plasma, or desktop services.

The tray regression test uses a substitute tray structure with real Qt GridView, ListModel, Loader, layout, and Binding objects. It covers twelve lifecycle cases, including late icon creation, reordering, removal, content reload, empty trays, burst updates, and restoration after adapter removal. Native tray arrivals and departures were also tested in Plasma after a shell restart.

Live tests cover same-desktop and rapid repeated clicks, actual sensor rendering, widget migration, panel order after restart, top-only floating toggles, and background-strength changes. A repeat configuration preserved a floating disposable window. See [TESTING.md](TESTING.md) for physical-input gaps and other remaining checks.
