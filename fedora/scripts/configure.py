#!/usr/bin/env python3
"""Applies settings, shortcuts, and panels through native KDE interfaces."""

from pathlib import Path
import json
import subprocess
import time

import dbus

ROOT = Path(__file__).resolve().parents[1]
MODIFIERS = {"Alt": 0x08000000, "Ctrl": 0x04000000, "Shift": 0x02000000}


def key_code(sequence):
    """Encodes supported single chords using Qt keyboard constants."""
    parts = sequence.split("+")
    key = parts.pop()
    if key != "Space" and (len(key) != 1 or key not in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&"):
        raise ValueError(f"Unsupported shortcut key {key}")
    code = ord(" " if key == "Space" else key)
    for modifier in parts:
        code |= MODIFIERS[modifier]
    return code


def disable_desktop_effects(bus):
    """Unloads desktop transitions that remain active after configuration changes."""
    effects = dbus.Interface(bus.get_object("org.kde.KWin", "/Effects"), "org.kde.kwin.Effects")
    for name in ("slide", "fadedesktop"):
        if effects.isEffectLoaded(name):
            effects.unloadEffect(name)
        if effects.isEffectLoaded(name):
            raise RuntimeError(f"KWin did not unload desktop effect {name}.")


def reload_scripts(bus, plugins):
    """Reloads workspace scripts so installed code and saved settings take effect."""
    scripts = dbus.Interface(bus.get_object("org.kde.KWin", "/Scripting"), "org.kde.kwin.Scripting")
    for plugin in plugins:
        if scripts.isScriptLoaded(plugin) and not scripts.unloadScript(plugin):
            raise RuntimeError(f"KWin refused to unload {plugin}.")

    # Waits for deferred script destruction before requesting new instances.
    for _ in range(100):
        if not any(scripts.isScriptLoaded(plugin) for plugin in plugins):
            break
        time.sleep(0.1)
    else:
        raise RuntimeError("KWin did not finish unloading workspace scripts.")
    bus.call_blocking("org.kde.KWin", "/KWin", "org.kde.KWin", "reconfigure", "", ())


def main():
    """Configures installed workspace components and checks native readbacks."""
    bus = dbus.SessionBus()
    if not all(bus.name_has_owner(name) for name in ("org.kde.KWin", "org.kde.plasmashell", "org.kde.kglobalaccel")):
        raise RuntimeError("Run configuration inside an active Plasma session.")
    panel_script = (ROOT / ".build/plasma/panels.js").read_text()
    for structure, plugin in (("KWin/Script", "krohnkite"), ("KWin/Script", "workspace-shortcuts"),
                              ("Plasma/Applet", "com.starboi.workspaces")):
        subprocess.run(["kpackagetool6", "--type", structure, "--show", plugin], check=True, stdout=subprocess.DEVNULL)
    shortcuts = json.loads((ROOT / "shortcuts.json").read_text())
    chords = {action: key_code(sequence) for action, sequence in shortcuts.items()}
    if len(set(chords.values())) != len(chords):
        raise ValueError("Shortcut chords must be unique.")

    changed_scripts = {"workspace-shortcuts"}
    for filename, groups in json.loads((ROOT / "settings.json").read_text()).items():
        for group, settings in groups.items():
            for key, value in settings.items():
                encoded = str(value).lower() if isinstance(value, bool) else str(value)
                location = ["--file", filename, "--group", group, "--key", key]
                previous = subprocess.check_output(["kreadconfig6", *location], text=True).strip()
                if previous != encoded and (group == "Script-krohnkite" or key == "krohnkiteEnabled"):
                    changed_scripts.add("krohnkite")
                subprocess.run(["kwriteconfig6", *location, encoded], check=True)
                actual = subprocess.check_output(["kreadconfig6", *location], text=True).strip()
                if actual != encoded:
                    raise RuntimeError(f"KConfig did not retain {filename}/{group}/{key}.")
    reload_scripts(bus, sorted(changed_scripts))
    disable_desktop_effects(bus)
    api = dbus.Interface(bus.get_object("org.kde.kglobalaccel", "/kglobalaccel"), "org.kde.KGlobalAccel")

    # Waits for enabled KWin scripts to register their actions.
    for _ in range(100):
        actions = {str(action[1]): list(map(str, action)) for action in api.allActionsForComponent(["kwin", "", "KWin", ""])}
        if set(chords) <= set(actions):
            break
        time.sleep(0.1)
    else:
        raise RuntimeError(f"Missing installed shortcut actions {sorted(set(chords) - set(actions))}")

    for action, code in chords.items():
        owner = list(map(str, api.action(code)))
        if owner and owner[:2] != ["kwin", action]:
            remaining = [int(key) for key in api.shortcut(owner) if int(key) != code]
            print(f"Reassigning {shortcuts[action]} from {owner[0]}/{owner[1]}", flush=True)
            api.setForeignShortcut(owner, dbus.Array(remaining, signature="i"))
            if list(map(int, api.shortcut(owner))) != remaining:
                raise RuntimeError(f"KDE did not preserve alternate shortcuts for {owner[0]}/{owner[1]}.")
        api.setForeignShortcut(actions[action], dbus.Array([code], signature="i"))
        if list(map(int, api.shortcut(actions[action]))) != [code] or list(map(str, api.action(code)))[:2] != ["kwin", action]:
            raise RuntimeError(f"KDE did not assign {shortcuts[action]} to {action}.")
    print(f"Verified {len(chords)} shortcut bindings.", flush=True)

    plasma = dbus.Interface(bus.get_object("org.kde.plasmashell", "/PlasmaShell"), "org.kde.PlasmaShell")
    print(plasma.evaluateScript(panel_script, timeout=30))


if __name__ == "__main__":
    main()
