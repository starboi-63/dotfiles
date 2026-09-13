# Fedora Plasma configuration

Adds a custom top bar, a styled bottom dock, and shortcuts for workspace switching and window tiling.

Requires Plasma 6.7 or newer on Wayland.

Shared Vim, Zsh, Powerlevel10k, and Ghostty settings are installed separately. From this directory:

```sh
python3 ../scripts/link.py fedora
```

See [shared configuration](../shared/README.md) for prerequisites and OS overrides.

## Configuration

| File | Purpose |
| --- | --- |
| [style.json](style.json) | Appearance values. Every setting is explained in the [style reference](STYLE.md). |
| [shortcuts.json](shortcuts.json) | Native KWin and custom shortcut assignments. |
| [settings.json](settings.json) | Desktop behavior, Columns layout, and initial window rules. |
| [dependencies.json](dependencies.json) | Pinned Krohnkite archive and checksum. |

After editing appearance values, rebuild and upgrade affected widgets. Run `scripts/configure.py` again to apply panel settings, shortcuts, or tiling gaps. Log out and back in to load Krohnkite changes.

The bar's settings dialog also lets you change background opacity, floating behavior, and the number of icons per workspace. Running `scripts/configure.py` replaces those local choices with values from `style.json`. To give both bars the same opacity, edit `style.json` and reapply the configuration; the top bar's slider changes only the top bar.

## Build

Requires Python 3 and a TypeScript compiler. No npm dependencies are needed. Run commands from this directory.

Download the archive pinned in `dependencies.json`:

```sh
mkdir -p .build
curl --fail --location --output .build/krohnkite.kwinscript https://codeberg.org/anametologin/Krohnkite/releases/download/0.9.10.0_alpha/krohnkite-0.9.10.0_alpha_021c654.kwinscript
python3 scripts/build.py
```

The build validates appearance values, compiles TypeScript, verifies the upstream checksum, and applies the [column minimums fix](kwin/krohnkite/README.md). It writes only to `.build/` and produces `shortcuts.kwinscript`, `bar.plasmoid`, `dock.plasmoid`, and `krohnkite-patched.kwinscript`. Without the downloaded upstream archive, it builds only the three local packages.

## Install

Requires an active Plasma session, an existing bottom panel, Python's `dbus` module, `kpackagetool6`, `kwriteconfig6`, and `kreadconfig6`. Choose the desired theme in System Settings first. The default font is Adwaita Sans; Qt uses an available fallback if it is absent.

```sh
kpackagetool6 --type KWin/Script --install .build/krohnkite-patched.kwinscript
kpackagetool6 --type KWin/Script --install .build/shortcuts.kwinscript
kpackagetool6 --type Plasma/Applet --install .build/bar.plasmoid
kpackagetool6 --type Plasma/Applet --install .build/dock.plasmoid
python3 scripts/configure.py
```

Skip the dock package when `dock.matchBarOpacity` is disabled. Use `--upgrade` for packages already installed. Log out and back in after installation. For widget-only updates, `systemctl --user restart plasma-plasmashell.service` reloads QML and saved panel order without restarting KWin or application windows. Never hot-reload Krohnkite.

Configuration creates or reuses one top bar and bottom dock per active screen. Existing tray and clock widgets move to the top bar. Bottom panels become centered, floating, content-sized docks with auto-hide; existing height, native opacity mode, launcher, and pinned tasks are retained. Stock Pager, separators, and expanding spacers are removed. Repeated application preserves panel and widget identities.

Installed packages live under `$XDG_DATA_HOME`, normally `~/.local/share`:

- `kwin/scripts/krohnkite`
- `kwin/scripts/workspace-shortcuts`
- `plasma/plasmoids/com.starboi.bar`
- `plasma/plasmoids/com.starboi.dockappearance` when enabled

Configuration modifies these files under `$XDG_CONFIG_HOME`, normally `~/.config`:

- `kwinrc` and `kwinrulesrc` for desktop behavior, tiling, and initial maximization rules.
- `kglobalshortcutsrc` for requested shortcuts and conflicting assignments. Unrelated alternate shortcuts are preserved.
- `plasma-org.kde.plasma.desktop-appletsrc` and `plasmashellrc` for widgets and panel settings.

## Shortcuts

Option corresponds to Alt. Desktop numbers use Plasma's shared desktop list; each monitor independently selects its current desktop. Creating or removing a desktop changes the shared list.

| Keys | Action |
| --- | --- |
| `Alt+1…9` | Switch to desktop. |
| `Shift+Alt+1…9` | Send window to desktop without following. |
| `Alt+I/O` | Switch to previous/next desktop. |
| `Shift+Alt+I/O` | Move window to previous/next desktop and follow. |
| `Alt+N/W` | Create/remove desktop. |
| `Alt+B` | Toggle top bar floating mode. |
| `Alt+F` | Toggle animated maximization, flush with screen edges and below the bar. |
| `Shift+Alt+F` | Toggle padded Monocle view and restore the previous layout. |
| `Alt+H/J/K/L` | Focus left/down/up/right. |
| `Shift+Alt+H/J/K/L` | Move within or between columns. |
| `Ctrl+Alt+H/J/K/L` | Shrink width/grow height/shrink height/grow width. |
| `Alt+Space` | Toggle window floating. |

Desktop switching is instant and does not wrap. The final desktop cannot be removed. Monocle expands every tiled window into the padded work area, with the focused window in front. Floating and maximized windows remain outside that layout. Leave native maximization with `Alt+F` before using Monocle.

On the US keyboard layout, Shift+Alt+1…9 is stored as `Alt+!` through `Alt+(` because KWin consumes Shift when matching punctuation. Other keyboard layouts require corresponding symbol bindings. Empty shortcut values clear an action's bindings.

## Development checks

After building, check desktop operations, panel configuration, widget migration, and tiling:

```sh
node --test tests/*.cjs
```

Check tray sizing, tooltips, panel spacing, opacity restoration, and window rules with PySide6 and KDE's QML modules:

```sh
python3 tests/tray.py
python3 tests/tooltip.py
python3 tests/reservation.py
python3 tests/opacity.py
python3 tests/rules.py
```

KDE integration details are documented in [API.md](API.md).
