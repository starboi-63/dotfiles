# Verification record

The September 12–13, 2026 live trial used Fedora 44, Plasma/KWin 6.7.4, Qt 6.11.2, and Krohnkite `0.9.10.0_alpha` at commit `021c654`. One physical monitor was connected. This record describes observed results, not a claim that every KDE configuration is supported.

The current checkpoint includes the unfinished shared style draft. The active bar still uses the previously verified compact appearance. Krohnkite `0.9.10.0_alpha+column-minimums.1` and vertical Columns settings are installed on disk for the next normal login. The running tiler was not reloaded. Node and Qt engine checks passed, but native window sizing with that package remains unverified until login. Optional dock opacity matching is a proposal and is not implemented.

## Passed

| Check | Evidence |
| --- | --- |
| TypeScript compilation | All three strict projects compiled with TypeScript 5.7.3. |
| Negative type fixtures | Compiler rejected unsafe null/array access, unsupported values, unchecked creation failures, and globals from the wrong runtime. |
| Offline workspace logic | Generated JavaScript passed normal-operation and refused-operation cases against an in-memory substitute. |
| Offline panel logic | Eleven tests passed, including stock full-width panel conversion to a centered floating auto-hide dock, removal of expanding spacers, migration of Peek without duplication, repeat application with unchanged IDs, mixed-screen panel toggles, ignored writes, failed creation, and opacity reload failures. |
| Package installation | All runtime files in the three installed packages matched the tested archives byte for byte. |
| Stable tiler comparison | Published stable `0.9.9.2` and pinned alpha `0.9.10.0_alpha` driver code were evaluated with simulated output and desktop objects. With outputs on desktops 1 and 2, stable selected either `[1, 1]` or `[2, 2]` according to the active desktop. Alpha selected `[1, 2]` in both cases. Both selected `[1, 1]` when desktops were shared. This establishes a desktop-selection incompatibility in stable, not complete multi-monitor validation of alpha. Evidence is in `work/krohnkite-stable/` in the development workspace. |
| Native desktop actions | Creation, desktop selection 1–9, removal, and final-desktop protection passed. The extension to 8–9 also passed window sends without following, followed by explicit desktop selection. Only temporary test desktops were removed afterward. |
| Native window behavior | The initial 37 action-invocation checks passed for tiling, gaps, focus, reordering, resizing, floating, maximize/fullscreen, numbered sends, move-and-follow, boundaries, and sticky windows. A later targeted float test again changed a disposable window from tiled to floating, accepted a 700×450 resize, and tiled it again. |
| Shortcut configuration | All 40 active chords matched native KGlobalAccel owners and saved configuration after extending navigation and window sends through 9. Qt independently confirmed their integer key encodings. `Alt+F` invokes native maximize; `Alt+Shift+F` invokes Krohnkite Monocle. Native fullscreen has no binding. This does not establish physical delivery. |
| Native maximize trial | Native action invocation expanded a disposable window to the usable desktop area while retaining `fullScreen=false`. A second invocation restored its original tiled geometry. User testing confirmed flush edges and animation, now explicitly requested for `Alt+F`. The Maximize effect is enabled and loaded. Evidence is in `work/shortcut-update/` in the development workspace. |
| Monocle geometry | Eight offline cases executed the pinned upstream configuration reader and tiling engine with simulated windows. One and two tiles retained eight-pixel gaps with both panel reservations and two output origins. Repeated Monocle selection restored the previous Tile layout instance. Live checks confirmed saved settings and shortcut ownership. Padded behavior in the desktop session awaits logout/login. Evidence is in `work/monocle/` in the development workspace. |
| Physical keyboard input | User confirmed `Alt+N`, `Alt+2`, and `Alt+1`. User confirmed instant switching after unloading the running Slide effect. |
| Widget backend | Real QML components created and switched desktops through KWin D-Bus. Native desktop state agreed afterward. |
| Widget interaction | Qt mouse-event tests passed creation, selection, active indication, empty-desktop display, and absence of backend errors. |
| Native panel rendering | Screenshots verified the monochrome emblem and spaces on the left, with compact CPU/network readings, smaller native tray icons, and an Adwaita Sans clock on the right. Peek at Desktop returned to the dock with its original ID. |
| Tray interaction | Fourteen live observations passed using Qt mouse events inside Plasma. Visible icon containers measured 18×18 pixels in 28-pixel cells. One chevron rotated to 180 degrees on opening and closed the popup. Clipboard, sound, Bluetooth, brightness, and network popups opened and closed. The temporary harness was removed afterward. |
| Tray lifecycle | The original code reproduced oversized icons after delegate insertion and removal. Twelve regression cases now pass using real Qt models and bindings. After a Plasma restart, 46 live samples retained 18×18 icon geometry while three temporary tray icons repeatedly arrived and departed. Native notification arrivals also retained compact sizing. |
| Floating bar gap | ChatGPT's tiled frame moved from y=54.29 to y=62.29 logical pixels. Screenshots confirmed about eight pixels of visible clearance below the floating bar. |
| Native panel toggle | Registered action changed top panel 31 from floating to edge-to-edge and back. Screenshots agreed. Bottom dock 2 retained floating, auto-hide, and content-sized settings. |
| Panel space reservation | Seventeen cases passed with real Qt layer-shell properties, including idempotence, native overwrites, edit mode, hiding, and adapter removal. After the reboot, repeated live toggles changed ChatGPT's tiled y-position between 54.29 and 62.29 and its height between 1173.14 and 1165.14 logical pixels. The dock was unchanged. |
| Background strength | Runtime changes between 20% and 85% visibly changed the background without fading foreground content. Final user preference is 33%, applied to the session and saved default. |
| Repeat configuration | Reused panels and existing widget IDs, preserved the desktop list, and preserved a floating disposable window's geometry. Krohnkite is not reloaded when its settings are unchanged. |
| Repeated workspace clicks | Current-desktop, rapid-repeat, stale-model no-op, repeated-target, return, and invalid-position cases passed against the live KWin backend. User confirmed the original red error was gone. |
| Compact tooltips | The original popup reproduced 24 visibility transitions in eight seconds. Native tooltip tests passed sustained hover, small pointer movements, long titles, dismissal, and parent clicks. A live Plasma pass covered ChatGPT, Discord, upload, and download across 92 stable samples, with one appearance per hover and popup geometry below the bar. Nine-point typography is preserved. |
| Initial window state | Firefox opened maximized before the rule and tiled immediately after it. Native disposable-window tests preserved later maximization, manual floating, and a maximized transient dialog. Rule registration preserved prior rule order and produced byte-identical configuration on repeat application. |
| Keyboard profile | keyd 2.6.0's parser accepted the proposed profile. Its actual input engine passed 20 semantic translations for both Command/Option keys, arrows, copy chords, and Shift selection. No service or profile was installed. |
| Desktop effects | Slide and Fade Desktop were both unloaded after configuration; saved settings also disabled them. |
| Display and palette | Output remained 3840×2160 at 239.998 Hz, 175% scale, HDR off. All 112 Breeze Dark palette and color-effect entries matched the installed scheme. |

Native action tests invoked registered actions through KGlobalAccel. They do not prove physical delivery of every key combination. The standalone widget harness could not enumerate other applications' windows; icon inventory was checked in the actual Plasma panel instead.

## Findings incorporated into the implementation

- The Pager package's root-path override loaded its bundled main QML instead of this widget. The widget now uses public Task Manager models and explicit D-Bus messages.
- D-Bus QML replies have different wrappers for strings and booleans. Real backend tests established the consumed return shapes and parenthesized argument signatures.
- Plasma 6.7.4's scripted panel opacity setter targets the wrong native property. The panel script writes the native opacity mode and reloads panel settings through a location change, then checks the result.
- KGlobalAccel's `setShortcut` did not replace existing registered bindings as required. Configuration uses `setForeignShortcut` and verifies both ownership and retained alternatives.
- Krohnkite's Binary Tree layout ignored the four resize actions in the initial trial. Tile passed those checks. The current profile selects vertical Columns to support movement between stacks and awaits native verification after login.
- Generic KWin reconfiguration did not unload an already running Slide effect. Configuration explicitly unloads desktop-transition effects and checks their loaded state.
- Enabled KWin scripts retain their running instances and cached settings. Configuration reloads only the workspace helper. Krohnkite code and settings changes require logout/login because live reload testing caused a crash.
- Physical Shift+Option+2 reached a focused Qt recorder as `Alt+Shift+@`, while KWin's global matcher consumes Shift for that symbol. Neither `Alt+Shift+2` nor `Alt+Shift+@` worked physically. The profile now uses `Alt+@` and corresponding symbols for 1–9; final physical confirmation is pending.
- Physical Option+Space emitted Krohnkite's native action, but the user reported no float change during the earlier combined test. A later isolated action-invocation test passed. The physical sequence still needs a focused-window retest.
- Native widget movement preserved IDs but did not preserve the requested order. Saving `AppletOrder` and restarting the shell fixed the actual layout. A malformed unused clock configuration group appeared during migration and was removed. Clock configuration now occurs before movement.
- QML package upgrades alone did not refresh cached widget code. A Plasma shell restart loaded the changes. A relative icon string also resolved as a generic icon; `Qt.resolvedUrl` fixed the Fedora emblem.
- Plasma reserves panel thickness without its floating inset. The original sixteen-pixel tiling gap was a static workaround. The current panel adapter instead reserves the floating inset through Wayland, so all tiling gaps can remain eight pixels. Equal assignments avoid redundant writes, and cleanup disables the adapter before restoring native reservation.
- Native tray icons have a fixed size of twenty-two pixels. A contained visual adapter reduces their dimensions without replacing input handlers. The live popup trial logged native `ExpandedRepresentation.qml` null-text warnings during popup changes, while all open/close assertions passed. No upstream popup code was changed.
- A direct children-list model recreated size overrides for existing tray items during startup changes. Deferred teardown restored KDE's larger sizes. A stable loader model now preserves those overrides and updates only inserted or removed rows. Explicit deactivation during adapter teardown also passed restoration checks for native bindings, cell width, and chevron visibility.

- A Qt Controls tooltip inside the short panel window covered its trigger, repeatedly ending hover. A separate native Plasma tooltip window removes that feedback loop.
- Firefox restored native maximization at startup, which Krohnkite deliberately excludes from tiling. A native Apply Initially rule clears startup maximization without constraining later user actions.

## Remaining verification

- The September 13 movement regression reproduced natively with three disposable windows. A left tile with a 600-pixel minimum caused Tile layout to float the right window moved left. The same movement with smaller minimums only swapped windows. The patched vertical Columns engine passes both right-window choices, both panel reservations, two output origins, reverse movement, dynamic minimums, Monocle restoration, and repeat arrangement. These checks also passed in Qt's JavaScript engine. Real window sizing with the patched package still requires a normal login before verification.

- The custom panel action was renamed to `Panel Toggle Floating` and placed beside native `Window Maximize`. All forty active chords were read back from KDE after upgrading only the workspace helper. The obsolete `WorkspaceTogglePanel` configuration key was removed.

- The shared style draft remains unverified and is not installed. The separate tile-height fix passed live action-invocation checks. User confirmation of physical Alt+B after the final timing correction remains outstanding.

- Padded Monocle after logout/login, including repeat toggling, focus, both bar modes, and physical confirmation of an instant transition. The running Krohnkite instance still has its startup configuration; it was not reloaded.

- Independent switching, bar selection, window filtering, and focus with two physical monitors.
- Monitor connection/disconnection and activity changes.
- A complete logout/login or reboot after the final configuration, including updated QML loading.
- A fresh Kinoite installation with its actual Plasma version and available dependencies.
- Physical delivery of corrected window-send shortcuts, new desktop 8–9 shortcuts, Option+F, Option+Space, and Alt+B; unusual application windows; and long-term stability of the prerelease tiler.
- User review of compact tooltip typography and a live keyd keyboard trial after separate installation approval.
- Removal/reinstallation of the panel background adapter and persistent background preferences across a full login cycle. Tray styling removal and recreation passed the Qt regression test.
- A complete backup/restore cycle.

Clicking a workspace queries KWin's active output before requesting selection. The two D-Bus calls are not atomic, so an intervening output change remains a multi-monitor race to test.

## App crash observed during the trial

Two `kdialog` processes aborted at 12:29:27 on September 13 after sandboxed `kreadconfig6` readback commands attempted to display a warning about unwritable `kreadconfig6rc`. Their command lines identify that warning, and their journals report denied Wayland access followed by Qt platform initialization failure. KWin remained PID 15200, started at 11:35, with no new compositor coredump. KDE configuration tools must run with host desktop access rather than inside that restricted sandbox. No filesystem permission repair or package reinstall is indicated by these records.

KWin crashed with SIGSEGV at 11:17:16 PDT on September 13 during live testing of a proposed Krohnkite gap-update hook. Temporary QML callbacks continued reporting missing context after script unloads. The recorded stack enters `QQmlContextData::initPropertyNames` during JavaScript callbacks from window resizing. These observations implicate the reload experiment but do not establish a complete root cause. The experiment is not considered safe or passed. Further live Krohnkite reload testing is suspended.

Recovery restored all files in the three installed packages and checked them against the original Krohnkite archive and saved local packages. A Plasma shell restart restored the prior compact clock while retaining the tooltip and tray lifecycle fixes. KWin was not restarted or reconfigured during recovery. A normal logout/login is required to replace script instances already loaded before recovery. The shared style draft remains separate from the restored installation. Recovery evidence is in the development workspace's `work/recovery-20260913/` directory.

The user rebooted at 11:34 on September 13, completing that recovery. ABRT's two newest saved reports were KWin at 11:17 and a KIO worker at 10:10, both before this boot. No coredumps were recorded after the reboot during the panel reservation checks. KWin's process remained the one started at 11:35. Installed Krohnkite files matched the original archive, and the workspace helper matched its restored archive. The active widget differs from the restored package only in `PanelAppearance.qml` and the added `PanelReservation.qml`. The shared style draft was not installed. Native evidence is in `work/panel-reservation/`.

ChatGPT crashed with SIGSEGV at 22:51:36 PDT on September 12. The main stack began in `libqt6_shim.so`, followed by GLib/GIO file-monitor dispatch. This resembles an earlier crash observed during the session. The stack does not identify the changed file or establish which action triggered the crash. No app-level fix has been made, and the configuration cannot be described as having passed a crash-free session test.

Detailed test JSON, screenshots, configuration snapshots, and the crash trace remain in the development workspace's `work/live-trial/` directory. They are local evidence rather than portable automated tests. Test-created windows and desktops were closed or removed. The user changed the desktop list during testing; subsequent checks capture IDs dynamically. KDE retained some layout entries for deleted test desktops and a previous test panel in its normal configuration files.
