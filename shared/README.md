# Shared configuration

Shared defaults live in `shared/home/`, with OS overrides in `fedora/home/` and `macos/home/`.

| Application | Shared settings | OS settings |
| --- | --- | --- |
| Ghostty | Font family, theme, and window styling. | Fedora uses 10.5pt and Zsh. macOS uses 12.5pt and a hidden titlebar. |
| Zsh | Oh My Zsh and Powerlevel10k initialization. | Plugins, paths, aliases, and startup commands. |
| Powerlevel10k | Prompt. | |
| Vim | Settings and theme. | |

## Setup

Install Python 3, Vim, Ghostty, Zsh, Oh My Zsh, Powerlevel10k, and the plugins listed in your OS's `.zshrc`. From the repository root, run this command with `fedora` or `macos`:

```sh
python3 scripts/link.py fedora
```

The script symlinks configuration into your home directory, so keep the repository at a stable path. Move reported conflicts aside and rerun. When migrating Ghostty, also move its old `config` file aside; this setup uses `config.ghostty`.
