# Fedora Plasma configuration

The shared `style.json` refactor is unfinished and is not the active desktop version. A live KWin gap experiment crashed the compositor on September 13. The original Krohnkite package and prior widget were restored, including the compact clock, tooltip fix, and stable tray sizing. After a reboot, a Plasma panel reservation adapter was added and verified with ChatGPT. It adjusts window space on Alt+B without changing Krohnkite. The experimental KWin hook was removed from the build. Do not deploy the remaining style draft until its layout and lifecycle checks are complete. See [TESTING.md](TESTING.md).

Krohnkite handles tiling. Native KWin shortcuts handle navigation, and a small helper adds desktop creation, removal, moving a window while following it, and a panel toggle. A native top bar holds a monochrome Fedora emblem, workspaces, CPU and network readings, the system tray, and a clock. The launcher, task icons, and Peek at Desktop stay in the bottom dock.

The live trial uses Fedora 44 with Plasma 6.7.4 on Wayland. Instant switching was confirmed with physical keyboard input. Physical window-send shortcuts are still awaiting confirmation after a corrected binding. Multiple monitors and a fresh Kinoite installation remain unverified. See [TESTING.md](TESTING.md).

## Components

| Path | Purpose |
| --- | --- |
| `kwin/shortcuts/` | Five TypeScript actions that supplement KWin's existing shortcuts. |
| `kwin/krohnkite/` | Minimum size handling applied to the pinned upstream Columns layout. |
| `plasma/bar/` | Workspace display, sensor readings, compact tooltips, and panel appearance controls. |
| `plasma/panels.ts` | Creates or reuses native panels and configures appearance, task filtering, and clock. |
| `plasma/toggle.ts` | Toggles only workspace panels. Compiled code is bundled into the KWin helper for execution by Plasma. |
| `settings.json` | Enables per-output desktops, disables desktop transitions, selects vertical Columns, and prevents startup maximization from bypassing tiling. |
| `shortcuts.json` | Maps native and custom actions to keyboard chords. |
| `dependencies.json` | Records the tested Krohnkite prerelease and its SHA-256 digest. |
| `scripts/build.py` | Compiles TypeScript and packages the two local extensions. |
| `scripts/configure.py` | Applies settings, reloads workspace scripts, unloads desktop transitions, assigns shortcuts, and runs panel configuration. |
| `API.md` | Documents consumed KDE contracts and runtime checks. |
| `keyboard/` | Proposed, separately tested keyd profile. The desktop setup does not install or activate it. |

The custom code implements presentation and integration. Krohnkite supplies the tiling engine. Declarations and offline tests add source without adding runtime services. TypeScript catches mistakes against our declared contracts; native readbacks and integration tests check assumptions those declarations cannot prove.

Krohnkite is an external package downloaded into `.build/` and installed under `$XDG_DATA_HOME/kwin/scripts/krohnkite`. The build applies the documented [column minimums adjustment](kwin/krohnkite/README.md) to a checksum-verified copy. The KWin 6 fork [moved from GitHub to Codeberg](https://github.com/anametologin/krohnkite). Prefer a stable release when it supports this setup. As checked on September 13, 2026, stable `0.9.9.2` uses one current desktop for every output when selecting tiling surfaces. The pinned alpha queries each output's current desktop separately. A comparison using both packages' actual driver code reproduced this difference with simulated outputs. Independent monitor desktops therefore prevent switching to that stable release; physical testing with two monitors remains outstanding.

## Build and check

Requires Python 3 and TypeScript. Node.js runs the offline tests. Verified with TypeScript 5.7.3 and Node.js 24.18.0. No npm dependencies are required.

Run from this directory:

```sh
python3 scripts/build.py
tsc --project tests/types/kwin.json
tsc --project tests/types/plasma.json
node tests/workspaces.cjs
node tests/panels.cjs
```

`python3 tests/rules.py` checks idempotent rule registration with native KConfig commands in a temporary directory.

`python3 tests/tray.py` runs the tray lifecycle regression test with PySide6 and the installed KDE QML modules. `python3 tests/tooltip.py` checks sustained hover, dismissal, long titles, and click delivery through native Plasma tooltips. Both use offscreen Qt scenes and do not modify the desktop. PySide6 is a development test dependency, not a dependency of the installed widget.

`python3 tests/reservation.py` checks seventeen panel reservation cases with native Qt layer-shell objects. These include both bar modes, repeated assignments, native overwrites, resizing, edit mode, hiding, removal, and recreation. The installed `org.kde.layershell` QML module is required by the reservation adapter.

The build writes only into `.build/`. It produces `workspaces.kwinscript`, `workspaces.plasmoid`, and `plasma/panels.js`. Archives contain runtime files and metadata, excluding TypeScript declarations and tests. Failed compilation removes previous archives to prevent installation of stale builds.

QML remains the widget's native interface language. KWin and Plasma scripts compile separately without browser or Node.js globals.

The helper mirrors KWin's installed package layout. KWin 6.7.4's [loader](https://github.com/KDE/kwin/blob/v6.7.4/src/scripting/scripting.cpp#L723) requires `contents/code/main.js` for JavaScript scripts. The bar's SVG assets live in `plasma/bar/contents/icons/` and use explicit relative references.

## Install and configure

Requires an active Plasma Wayland session with KWin 6.7 or newer, an existing bottom panel, Python's `dbus` module, `kpackagetool6`, `kwriteconfig6`, and `kreadconfig6`. Version 6.7.4 is the tested target. On a new Kinoite installation, check these requirements before choosing how to supply any missing dependencies.

Choose the desired theme in System Settings first. Both panels and the workspace widget inherit it; the live trial used Breeze Dark.

For a fresh installation, build first, then download the pinned upstream package and verify its digest:

```sh
curl --fail --location --output .build/krohnkite.kwinscript https://codeberg.org/anametologin/Krohnkite/releases/download/0.9.10.0_alpha/krohnkite-0.9.10.0_alpha_021c654.kwinscript
sha256sum --check <<'CHECKSUM'
971af496ccb51e6306d10409815c4641bdf5504212fcd491336b35e27fa48dea  .build/krohnkite.kwinscript
CHECKSUM
```

Continue only if the checksum passes. Rebuild to produce the patched tiler and run its tests, then install three user packages and configure the session:

```sh
python3 scripts/build.py
node tests/columns.cjs
kpackagetool6 --type KWin/Script --install .build/krohnkite-patched.kwinscript
kpackagetool6 --type KWin/Script --install .build/workspaces.kwinscript
kpackagetool6 --type Plasma/Applet --install .build/workspaces.plasmoid
python3 scripts/configure.py
```

Use `--upgrade` instead of `--install` when a package already exists. Updated QML and saved panel order require a Plasma shell restart or normal logout/login. A live update can use `systemctl --user restart plasma-plasmashell.service` after configuration. This restarts the shell, not KWin or application windows.

Configuration reloads only the workspace helper. Krohnkite is never reloaded live. If its saved settings change, configuration prints a reminder to log out and back in. The same applies after upgrading Krohnkite itself.

## Changes to the session

Package installation writes three directories under `$XDG_DATA_HOME`, normally `~/.local/share`:

- `kwin/scripts/krohnkite`
- `kwin/scripts/workspace-shortcuts`
- `plasma/plasmoids/com.starboi.workspaces`

Configuration intentionally changes five files under `$XDG_CONFIG_HOME`, normally `~/.config`:

| File | Changes |
| --- | --- |
| `kwinrc` | Settings listed in `settings.json`. KWin also saves desktops created or removed during use. |
| `kwinrulesrc` | Registers `initial-tiling` after existing user rules. Normal non-transient windows start unmaximized so Krohnkite can tile them. Later maximize actions remain available. |
| `kglobalshortcutsrc` | Requested bindings and conflicting chords removed from previous owners. Unrelated alternate chords are preserved and checked. |
| `plasma-org.kde.plasma.desktop-appletsrc` | Panel order, moved system widgets, obsolete dock Pager/separator removal, task filters, clock, and widget appearance. |
| `plasmashellrc` | Native panel geometry and appearance. |

The script checks package availability and duplicate chords before changing settings. It checks saved settings, assigned chords, and relevant native panel properties afterward. These checks detect failures; they are not a transaction or an automatic rollback system. KDE can also update its ordinary caches and service data during operation.

Back up these files and any existing package directories before applying to another machine. Restore configuration files while logged out of Plasma so running services cannot overwrite them. Removing an extension alone does not restore previous shortcuts or panel contents. A complete restore cycle has not been tested.

Do not test in a second Plasma session under the same user. Separate XDG paths and a private D-Bus session did not isolate earlier service side effects. Use a separate VM or an explicitly disposable desktop for another full integration trial.

## Panel behavior

The script creates or reuses one workspace panel per active screen and rejects ambiguous duplicates. Every bottom panel becomes a centered, floating, content-sized dock with auto-hide. Existing dock height, opacity, launcher, and task pins are preserved. Screens without a dock receive one containing a launcher and task manager. Stock Pager, separator, and spacer widgets are removed so expanding spacers cannot keep the dock full-width. The tray and clock move to the top bar, and Peek at Desktop occupies the dock's right edge. Reapplying configuration keeps existing panel and widget IDs.

The top bar stays visible at full width. Existing tray and clock widgets move to it with their IDs and settings. Peek at Desktop moves to the dock's right edge. Native panel order is saved explicitly because widget movement alone does not guarantee visual order. The clock uses Adwaita Sans at 10 points with regular weight and inline date/time. This font is already installed on the trial machine. Qt falls back to an available font if it is absent. Both panels retain the system theme.

Tiling gaps are eight logical pixels. Plasma ordinarily reserves panel thickness without its floating inset. `PanelReservation.qml` adds that inset to the panel's native Wayland reservation while floating. In edge-to-edge mode, it releases the inset. ChatGPT's tiled frame gained eight pixels of height in full-width mode and lost them again in floating mode during repeated live checks. Maximized windows follow the reserved work area but do not use Krohnkite's extra tiling gap. Fullscreen windows bypass it.

The workspace display shows one icon per window, up to six followed by an overflow count. Minimized icons fade. Compact nine-point tooltips show application name and window title in a native Plasma popup below the bar. The popup cannot overlap its own icon and interrupt hover. KDE controls the tooltip delay. Clicking the selected desktop is a no-op; rapid repeat clicks are also accepted. The plus button creates a desktop. Dock task icons filter to the current screen and desktop.

CPU, upload, and download readings come from KDE's installed sensor API and refresh at most every two seconds. Missing sensors show an em dash. Network rates form two compact rows with adjacent arrows and values. Readouts use Adwaita Sans with tabular digits. No polling shell scripts or additional monitoring daemon are installed.

The tray keeps native controls, tooltips, menus, and status indicators. `TrayAppearance.qml` sizes visible icons to eighteen logical pixels in twenty-eight-pixel cells. Overrides remain attached to existing icon loaders when applications arrive or leave during startup. A single chevron rotates over 140 milliseconds and respects disabled system animations. These visual adjustments use checked Plasma 6.7.4 internals and do not replace KDE's popup implementations or install an icon theme.

Right-click the workspace widget and open its configuration to change background strength, persistent floating margins, or the icon limit. Background strength defaults to 33% of the theme's own background opacity. Text, icons, masks, and native blur are preserved. This is a multiplier, not an exact final pixel alpha.

`Alt+B` switches the top bar between floating and edge-to-edge. It does not change the dock. `PanelAppearance.qml` uses checked Plasma 6.7.4 panel internals to retain floating margins beside tiled or maximized windows. This adapter is version-sensitive and reports incompatible panel backgrounds. Fullscreen applications can still cover the panel. Default settings live in `plasma/bar/contents/config/main.xml`; existing widget preferences take precedence.

The monochrome emblem contains only the Fedora symbol from the installed `fedora-logos` SVG. Its license is included beside the asset. The layout reference was [macOS Sonoma's Apple menu](https://512pixels.net/projects/aqua-screenshot-library/macos-14-sonoma/).

## Shortcuts

Desktop numbers follow Plasma's shared desktop list. Each monitor independently selects its current desktop. Creating or deleting a desktop changes the shared list.

| Keys | Action |
| --- | --- |
| `Alt+1…9` | Switch to desktop. |
| `Shift+Alt+1…9` | Send window to desktop without following. |
| `Alt+I/O` | Switch to previous/next desktop. |
| `Shift+Alt+I/O` | Move window to previous/next desktop and follow it. |
| `Alt+N/W` | Create/remove desktop. |
| `Alt+B` | Toggle top bar floating mode. |
| `Alt+H/J/K/L` | Focus left/down/up/right. |
| `Shift+Alt+H/J/K/L` | Reorder windows left/down/up/right. |
| `Ctrl+Alt+H/J/K/L` | Shrink width/grow height/shrink height/grow width. |
| `Alt+Space` | Toggle floating. |
| `Alt+F` | Toggle animated maximization, flush with screen edges and below the bar. |
| `Shift+Alt+F` | Toggle padded Monocle view and return to the previous tiling layout. |

Shortcut values contain one chord. An empty string clears an action's bindings. `Alt+Shift+F` uses Krohnkite's Monocle layout with `monocleMaximize=false`. Tiled windows share the full padded rectangle, with the focused window in front. A second press restores the previous layout. Padding follows the same Krohnkite gap settings as normal tiling, including changes to available space when the bar floats. Other windows are not minimized. Floating windows remain outside this layout.

`Alt+F` uses native maximization with the Maximize effect enabled. It fills the usable work area without outer tiling gaps and leaves the bar visible. Monocle moves tiled geometry without native maximization, so it does not trigger that growth animation. These toggles are independent. Leave native maximization with `Alt+F` before using Monocle. Native fullscreen, which covers the bar, has no assigned chord.

Krohnkite reads its Monocle settings at startup, so changing them requires logout/login. The settings and shortcuts are saved on the trial machine; live padding verification after that login is still pending.

Desktop navigation does not wrap, and the helper never removes the final desktop. `Alt+Space` replaces KRunner's binding on the trial machine; its two other shortcuts were preserved. Vertical Columns supports the movement and resize bindings. `Alt+Shift+H/L` transfers a tile between columns instead of swapping it with a tile in the other column. Application minimum sizes can produce unequal stack heights. Existing maximized windows must be unmaximized to participate in normal tiling.

On the US layout, physical Shift+Alt+1…9 produces `!@#$%^&*(`. KWin consumes Shift when matching these symbols, so the saved bindings use `Alt+!` through `Alt+(`. A different keyboard layout requires its own corresponding symbol bindings. Native owner readbacks pass; final physical confirmation remains pending.
