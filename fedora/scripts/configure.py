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
    if key != "Space" and (len(key) != 1 or key not in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*("):
        raise ValueError(f"Unsupported shortcut key {key}")
    code = ord(" " if key == "Space" else key)
    for modifier in parts:
        code |= MODIFIERS[modifier]
    return code


def shortcut_codes(shortcuts):
    """Encodes shortcut chords and rejects duplicate assignments."""
    chords = {}
    for action, sequence in shortcuts.items():
        if not isinstance(sequence, str):
            raise ValueError(f"Shortcut {action} must be a string.")
        chords[action] = [key_code(sequence)] if sequence else []
    assigned = [code for codes in chords.values() for code in codes]
    if len(set(assigned)) != len(assigned):
        raise ValueError("Shortcut chords must be unique.")
    return chords


def disable_desktop_transitions(bus):
    """Unloads desktop transitions that remain active after configuration changes."""
    effects = dbus.Interface(bus.get_object("org.kde.KWin", "/Effects"), "org.kde.kwin.Effects")
    for name in ("slide", "fadedesktop"):
        if effects.isEffectLoaded(name):
            effects.unloadEffect(name)
        if effects.isEffectLoaded(name):
            raise RuntimeError(f"KWin did not unload desktop effect {name}.")


def reload_shortcuts(bus):
    """Reloads workspace shortcuts without restarting tiler."""
    plugin = "workspace-shortcuts"
    scripts = dbus.Interface(bus.get_object("org.kde.KWin", "/Scripting"), "org.kde.kwin.Scripting")
    if scripts.isScriptLoaded(plugin) and not scripts.unloadScript(plugin):
        raise RuntimeError("KWin refused to unload workspace shortcuts.")

    # Waits for deferred script destruction before creating another instance.
    for _ in range(100):
        if not scripts.isScriptLoaded(plugin):
            break
        time.sleep(0.1)
    else:
        raise RuntimeError("KWin did not finish unloading workspace shortcuts.")
    bus.call_blocking("org.kde.KWin", "/KWin", "org.kde.KWin", "reconfigure", "", ())


def register_window_rules(names):
    """Registers initial window rules after existing user rules without duplication."""
    location = ["--file", "kwinrulesrc", "--group", "General", "--key", "rules"]
    existing = subprocess.check_output(["kreadconfig6", *location], text=True).strip()
    registered = existing.split(",") if existing else []
    registered.extend(name for name in names if name not in registered)
    encoded = ",".join(registered)
    subprocess.run(["kwriteconfig6", *location, encoded], check=True)
    if subprocess.check_output(["kreadconfig6", *location], text=True).strip() != encoded:
        raise RuntimeError("KConfig did not retain window rule order.")


def main():
    """Configures installed workspace components and checks native readbacks."""
    bus = dbus.SessionBus()
    if not all(bus.name_has_owner(name) for name in ("org.kde.KWin", "org.kde.plasmashell", "org.kde.kglobalaccel")):
        raise RuntimeError("Run configuration inside an active Plasma session.")
    panel_script = (ROOT / ".build/plasma/panels.js").read_text()
    style = json.loads((ROOT / "style.json").read_text())
    packages = [("KWin/Script", "krohnkite"), ("KWin/Script", "workspace-shortcuts"),
                ("Plasma/Applet", "com.starboi.workspaces")]
    if style["dock"]["matchBarOpacity"]:
        packages.append(("Plasma/Applet", "com.starboi.dockappearance"))
    for structure, plugin in packages:
        subprocess.run(["kpackagetool6", "--type", structure, "--show", plugin], check=True, stdout=subprocess.DEVNULL)
    shortcuts = json.loads((ROOT / "shortcuts.json").read_text())
    chords = shortcut_codes(shortcuts)

    settings = json.loads((ROOT / "settings.json").read_text())
    settings["kwinrc"]["Script-krohnkite"].update({
        "screenGap" + edge: style["bar"]["padding"] for edge in ("Left", "Right", "Top", "Between", "Bottom")
    })
    tiler_changed = False
    for filename, groups in settings.items():
        for group, entries in groups.items():
            for key, value in entries.items():
                encoded = str(value).lower() if isinstance(value, bool) else str(value)
                location = ["--file", filename, "--group", group, "--key", key]
                previous = subprocess.check_output(["kreadconfig6", *location], text=True).strip()
                if previous != encoded and (group == "Script-krohnkite" or key == "krohnkiteEnabled"):
                    tiler_changed = True
                subprocess.run(["kwriteconfig6", *location, encoded], check=True)
                actual = subprocess.check_output(["kreadconfig6", *location], text=True).strip()
                if actual != encoded:
                    raise RuntimeError(f"KConfig did not retain {filename}/{group}/{key}.")
    register_window_rules(settings["kwinrulesrc"])
    if tiler_changed:
        print("Krohnkite settings changed. Log out and back in to load them without live script reloads.", flush=True)
    reload_shortcuts(bus)
    disable_desktop_transitions(bus)
    api = dbus.Interface(bus.get_object("org.kde.kglobalaccel", "/kglobalaccel"), "org.kde.KGlobalAccel")

    # Waits for enabled KWin scripts to register their actions.
    for _ in range(100):
        actions = {str(action[1]): list(map(str, action)) for action in api.allActionsForComponent(["kwin", "", "KWin", ""])}
        if set(chords) <= set(actions):
            break
        time.sleep(0.1)
    else:
        raise RuntimeError(f"Missing installed shortcut actions {sorted(set(chords) - set(actions))}")

    for action, codes in chords.items():
        for code in codes:
            owner = list(map(str, api.action(code)))
            if owner and owner[:2] != ["kwin", action]:
                remaining = [int(key) for key in api.shortcut(owner) if int(key) != code]
                print(f"Reassigning shortcut for {action} from {owner[0]}/{owner[1]}", flush=True)
                api.setForeignShortcut(owner, dbus.Array(remaining, signature="i"))
                if list(map(int, api.shortcut(owner))) != remaining:
                    raise RuntimeError(f"KDE did not preserve alternate shortcuts for {owner[0]}/{owner[1]}.")
        api.setForeignShortcut(actions[action], dbus.Array(codes, signature="i"))
        if list(map(int, api.shortcut(actions[action]))) != codes or any(
            list(map(str, api.action(code)))[:2] != ["kwin", action] for code in codes
        ):
            raise RuntimeError(f"KDE did not assign {shortcuts[action]} to {action}.")
    print(f"Verified {sum(map(len, chords.values()))} shortcut bindings.", flush=True)

    plasma = dbus.Interface(bus.get_object("org.kde.plasmashell", "/PlasmaShell"), "org.kde.PlasmaShell")
    print(plasma.evaluateScript(panel_script, timeout=30))
    bus.call_blocking("org.kde.KWin", "/KWin", "org.kde.KWin", "reconfigure", "", ())


if __name__ == "__main__":
    main()
