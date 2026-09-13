# Verification record

The September 12–13, 2026 live trial used Fedora 44, Plasma/KWin 6.7.4, Qt 6.11.2, and Krohnkite `0.9.10.0_alpha` at commit `021c654`. One physical monitor was connected. This record describes observed results, not a claim that every KDE configuration is supported.

## Passed

| Check | Evidence |
| --- | --- |
| TypeScript compilation | Both strict projects compiled with TypeScript 5.7.3. |
| Negative type fixtures | Compiler rejected unsafe null/array access, unsupported values, unchecked creation failures, and globals from the wrong runtime. |
| Offline workspace logic | Generated JavaScript passed normal-operation and refused-operation cases against an in-memory substitute. |
| Offline panel logic | Ten tests passed, including migration of Peek back to the dock without duplication, dock preservation, repeat application, mixed-screen panel toggles, ignored writes, failed creation, and opacity reload failures. |
| Package installation | All runtime files in the three installed packages matched the tested archives byte for byte. |
| Native desktop actions | Creation, desktop selection 1–7, removal, and final-desktop protection passed. |
| Native window behavior | The initial 37 action-invocation checks passed for tiling, gaps, focus, reordering, resizing, floating, maximize/fullscreen, numbered sends, move-and-follow, boundaries, and sticky windows. A later targeted float test again changed a disposable window from tiled to floating, accepted a 700×450 resize, and tiled it again. |
| Shortcut configuration | All 36 owners and chords matched native KGlobalAccel readbacks. Qt independently confirmed their integer key encodings. This does not establish physical delivery. |
| Physical keyboard input | User confirmed `Alt+N`, `Alt+2`, and `Alt+1`. User confirmed instant switching after unloading the running Slide effect. |
| Widget backend | Real QML components created and switched desktops through KWin D-Bus. Native desktop state agreed afterward. |
| Widget interaction | Qt mouse-event tests passed creation, selection, active indication, empty-desktop display, and absence of backend errors. |
| Native panel rendering | Screenshots verified the monochrome emblem and spaces on the left, with compact CPU/network readings, smaller native tray icons, and an Adwaita Sans clock on the right. Peek at Desktop returned to the dock with its original ID. |
| Tray interaction | Fourteen live observations passed using Qt mouse events inside Plasma. Visible icon containers measured 18×18 pixels in 28-pixel cells. One chevron rotated to 180 degrees on opening and closed the popup. Clipboard, sound, Bluetooth, brightness, and network popups opened and closed. The temporary harness was removed afterward. |
| Floating bar gap | ChatGPT's tiled frame moved from y=54.29 to y=62.29 logical pixels. Screenshots confirmed about eight pixels of visible clearance below the floating bar. |
| Native panel toggle | Registered action changed top panel 31 from floating to edge-to-edge and back. Screenshots agreed. Bottom dock 2 retained floating, auto-hide, and content-sized settings. |
| Background strength | Runtime changes between 20% and 85% visibly changed the background without fading foreground content. Final user preference is 33%, applied to the session and saved default. |
| Repeat configuration | Reused panels and existing widget IDs, preserved the desktop list, and preserved a floating disposable window's geometry. Krohnkite is not reloaded when its settings are unchanged. |
| Repeated workspace clicks | Current-desktop, rapid-repeat, stale-model no-op, repeated-target, return, and invalid-position cases passed against the live KWin backend. User confirmed the original red error was gone. |
| Compact tooltips | All QML components compile. User confirmed application names and captions after a shell restart; the later smaller-font presentation awaits user confirmation. |
| Keyboard profile | keyd 2.6.0's parser accepted the proposed profile. Its actual input engine passed 20 semantic translations for both Command/Option keys, arrows, copy chords, and Shift selection. No service or profile was installed. |
| Desktop effects | Slide and Fade Desktop were both unloaded after configuration; saved settings also disabled them. |
| Display and palette | Output remained 3840×2160 at 239.998 Hz, 175% scale, HDR off. All 112 Breeze Dark palette and color-effect entries matched the installed scheme. |

Native action tests invoked registered actions through KGlobalAccel. They do not prove physical delivery of every key combination. The standalone widget harness could not enumerate other applications' windows; icon inventory was checked in the actual Plasma panel instead.

## Findings incorporated into the implementation

- The Pager package's root-path override loaded its bundled main QML instead of this widget. The widget now uses public Task Manager models and explicit D-Bus messages.
- D-Bus QML replies have different wrappers for strings and booleans. Real backend tests established the consumed return shapes and parenthesized argument signatures.
- Plasma 6.7.4's scripted panel opacity setter targets the wrong native property. The panel script writes the native opacity mode and reloads panel settings through a location change, then checks the result.
- KGlobalAccel's `setShortcut` did not replace existing registered bindings as required. Configuration uses `setForeignShortcut` and verifies both ownership and retained alternatives.
- Krohnkite's Binary Tree layout ignored the four resize actions in the trial. The profile uses Tile, which passed those checks.
- Generic KWin reconfiguration did not unload an already running Slide effect. Configuration explicitly unloads desktop-transition effects and checks their loaded state.
- Enabled KWin scripts retained their running instances and cached settings. Configuration reloads the workspace helper and reloads Krohnkite only when its settings changed. It waits for deferred destruction before reconfiguration.
- Physical Shift+Option+2 reached a focused Qt recorder as `Alt+Shift+@`, while KWin's global matcher consumes Shift for that symbol. Neither `Alt+Shift+2` nor `Alt+Shift+@` worked physically. The profile now uses `Alt+@` and corresponding symbols for 1–7; final physical confirmation is pending.
- Physical Option+Space emitted Krohnkite's native action, but the user reported no float change during the earlier combined test. A later isolated action-invocation test passed. The physical sequence still needs a focused-window retest.
- Native widget movement preserved IDs but did not preserve the requested order. Saving `AppletOrder` and restarting the shell fixed the actual layout. A malformed unused clock configuration group appeared during migration and was removed. Clock configuration now occurs before movement.
- QML package upgrades alone did not refresh cached widget code. A Plasma shell restart loaded the changes. A relative icon string also resolved as a generic icon; `Qt.resolvedUrl` fixed the Fedora emblem.
- Plasma reserves panel thickness without its floating inset. A sixteen-pixel Krohnkite top gap compensates for the eight-pixel inset and leaves visible clearance. Maximized windows bypass tiling gaps.
- Native tray icons have a fixed size of twenty-two pixels. A contained visual adapter reduces their dimensions without replacing input handlers. The live popup trial logged native `ExpandedRepresentation.qml` null-text warnings during popup changes, while all open/close assertions passed. No upstream popup code was changed.

## Remaining verification

- Independent switching, bar selection, window filtering, and focus with two physical monitors.
- Monitor connection/disconnection and activity changes.
- A complete logout/login or reboot after the final configuration, including updated QML loading.
- A fresh Kinoite installation with its actual Plasma version and available dependencies.
- Physical delivery of corrected window-send shortcuts, Option+Space, and Alt+B; unusual application windows; and long-term stability of the prerelease tiler.
- User review of compact tooltip typography and a live keyd keyboard trial after separate installation approval.
- Removal/reinstallation of the appearance adapter and persistent background preferences across a full login cycle.
- A complete backup/restore cycle.

Clicking a workspace queries KWin's active output before requesting selection. The two D-Bus calls are not atomic, so an intervening output change remains a multi-monitor race to test.

## App crash observed during the trial

ChatGPT crashed with SIGSEGV at 22:51:36 PDT on September 12. The main stack began in `libqt6_shim.so`, followed by GLib/GIO file-monitor dispatch. This resembles an earlier crash observed during the session. The stack does not identify the changed file or establish which action triggered the crash. No app-level fix has been made, and the configuration cannot be described as having passed a crash-free session test.

Detailed test JSON, screenshots, configuration snapshots, and the crash trace remain in the development workspace's `work/live-trial/` directory. They are local evidence rather than portable automated tests. Test-created windows and desktops were closed or removed. The user changed the desktop list during testing; subsequent checks capture IDs dynamically. KDE retained some layout entries for deleted test desktops and a previous test panel in its normal configuration files.
