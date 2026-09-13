# Keyboard preferences

`keychron.conf` is a proposed keyd profile for the connected Keychron K17 Max in wired mode (`3434:0a00`). It has not been installed or activated.

The keyd 2.6.0 parser accepted this file. Twenty tests against its input engine verified emitted keys and held modifiers for both sides of the keyboard, including Shift selection. These tests do not replace a live hardware trial. Cached Fedora 44 repository metadata did not contain a keyd package, so an installation source still needs to be chosen before requesting installation approval.

| Physical keys | Emitted keys |
| --- | --- |
| Command with ordinary keys | Ctrl with those keys |
| Command+Left/Right | Home/End |
| Option+Left/Right | Ctrl+Left/Right |
| Shift with either arrow combination | Corresponding selection shortcut |
| Option with other keys | Alt with those keys |
| Physical Ctrl | Ctrl |

Both Command keys use the same mapping, as do both Option keys. This replaces Right Alt's usual AltGr behavior on this keyboard. KDE calls Command's original modifier Meta; Linux also calls it Super. Mapping both Command keys removes their original Meta shortcuts. No additional Meta binding is proposed yet.

The profile requires keyd, a system input service. Its declarative configuration would be installed as `/etc/keyd/keychron.conf`. The keyboard selector excludes other vendor/product IDs, including the Razer mouse. Wireless connection modes may expose a different device ID and require another explicit selector.

Application behavior still matters. Home/End may follow an editor's smart-line rules, and terminal copy/paste commonly uses Ctrl+Shift+C/V. This profile implements the requested key translations rather than application-specific macOS emulation.

The existing desktop setup does not install keyd or apply this profile. Installation and a live keyboard test require separate approval. Stopping `keyd.service` restores the original input path. keyd also provides its documented Backspace+Escape+Enter escape sequence.

See [keyd's layer documentation](https://github.com/rvaiya/keyd/blob/v2.6.0/docs/keyd.scdoc) for modifier inheritance and configuration syntax.
