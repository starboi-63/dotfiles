# Shared configuration

Common settings live in `shared/home/`. Each OS adds its own files from `fedora/home/` or `macos/home/`.

| Application | Shared settings | OS settings |
| --- | --- | --- |
| Ghostty | Font family, theme, colors, padding, and window behavior. | Fedora uses 10.5pt and Zsh. macOS uses 12.5pt and a hidden titlebar. |
| Zsh | Oh My Zsh and Powerlevel10k initialization. | Plugins, paths, aliases, and startup commands. |
| Powerlevel10k | Prompt configuration. | |
| Vim | Editor configuration and theme. | |

## Setup

Install the applications, Oh My Zsh, Powerlevel10k, and the plugins listed in your OS's `.zshrc`. From the repository root, choose your OS:

```sh
python3 scripts/link.py fedora
# or
python3 scripts/link.py macos
```

The script links shared and OS files into your home directory. It honors `XDG_CONFIG_HOME` for `.config` files and reports existing files before creating any links. Move conflicting files aside and rerun it. Ghostty uses `config.ghostty`; move an older `ghostty/config` aside when migrating.

Keep the checkout at a stable path. Editing a linked file updates the repository. Repeating the command preserves existing links. Use `--check` to preview changes or `--target /path/to/home` to stage them elsewhere.

Ghostty loads `base.conf` first and `platform.conf` second. Change common defaults in `shared/home/.config/ghostty/base.conf` and OS overrides in the corresponding `platform.conf`. Each OS's `.zshrc` selects plugins before sourcing shared Zsh initialization.

Check link creation, repeated application, conflict handling, and custom destinations with:

```sh
python3 -B tests/link.py
```
