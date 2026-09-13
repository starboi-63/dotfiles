# Keyboard preferences

`keychron.conf` is an optional keyd profile for the Keychron K17 Max in wired mode (`3434:0a00`). It is separate from desktop installation and has not been activated on the test machine.

| Physical keys | Emitted keys |
| --- | --- |
| Command with ordinary keys | Ctrl with those keys |
| Command+Left/Right | Home/End |
| Option+Left/Right | Ctrl+Left/Right |
| Shift with either arrow combination | Corresponding selection shortcut |
| Option with other keys | Alt with those keys |
| Physical Ctrl | Ctrl |

Both sides use identical mappings. This replaces Meta shortcuts and Right Alt's AltGr behavior. Wireless modes may expose different device IDs. Terminal copy/paste commonly still requires Ctrl+Shift+C/V.

Install keyd separately and place the profile at `/etc/keyd/keychron.conf` to use it. Stopping `keyd.service` restores normal input. The profile passed keyd 2.6.0 parser and input-engine checks; a physical keyboard trial remains necessary. See [keyd's configuration reference](https://github.com/rvaiya/keyd/blob/v2.6.0/docs/keyd.scdoc).
