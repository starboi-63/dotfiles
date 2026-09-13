#!/usr/bin/env python3
"""Packages workspace components inside repository."""

from pathlib import Path
import hashlib
import json
import math
import shutil
import subprocess
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo


def patch_krohnkite(fedora_dir, build_dir):
    """Packages verified upstream tiler with column minimum size handling."""
    target = build_dir / "krohnkite-patched.kwinscript"
    target.unlink(missing_ok=True)
    (build_dir / "kwin/krohnkite/script.js").unlink(missing_ok=True)
    source = build_dir / "krohnkite.kwinscript"
    if not source.exists():
        print("Download pinned Krohnkite archive and rebuild to prepare patched tiler.")
        return
    dependency = json.loads((fedora_dir / "dependencies.json").read_text())["krohnkite"]
    if hashlib.sha256(source.read_bytes()).hexdigest() != dependency["sha256"]:
        raise ValueError("Krohnkite archive does not match pinned checksum.")
    replacements = {
        "this.parts.apply(area, columnTileables, gap).forEach((geometry, i) => {":
            "fitColumnMinimums(this.parts.apply(area, columnTileables, gap), "
            "columnTileables.map(tile => tile.minSize), this.parts.angle === 270, gap).forEach((geometry, i) => {",
        "return this._minSize;": "return this.window.minSize;",
    }
    with ZipFile(source) as archive:
        script = archive.read("contents/code/script.js").decode()
        for original, replacement in replacements.items():
            if script.count(original) != 1:
                raise ValueError("Krohnkite patch requires exactly one matching source location.")
            script = script.replace(original, replacement)
        script += "\n" + (build_dir / "kwin/krohnkite/minimums.js").read_text()
        (build_dir / "kwin/krohnkite/script.js").write_text(script)
        metadata = json.loads(archive.read("metadata.json"))
        metadata["KPlugin"]["Version"] += "+column-minimums.1"
        with ZipFile(target, "w", compression=ZIP_DEFLATED) as patched:
            for entry in archive.infolist():
                if entry.filename == "contents/code/script.js":
                    content = script.encode()
                elif entry.filename == "metadata.json":
                    content = (json.dumps(metadata, indent=2) + "\n").encode()
                else:
                    content = archive.read(entry)
                patched.writestr(entry, content)
    print(target)


def main():
    """Compiles scripts and packages workspace components without installing them."""
    fedora_dir = Path(__file__).resolve().parents[1]
    build_dir = fedora_dir / ".build"
    packages = {
        "workspaces.kwinscript": fedora_dir / "kwin/shortcuts",
        "workspaces.plasmoid": fedora_dir / "plasma/bar",
    }
    build_dir.mkdir(exist_ok=True)

    for filename in packages:
        (build_dir / filename).unlink(missing_ok=True)
    (build_dir / "krohnkite-patched.kwinscript").unlink(missing_ok=True)
    (build_dir / "kwin/krohnkite/script.js").unlink(missing_ok=True)
    style = json.loads((fedora_dir / "style.json").read_text())
    fixture = build_dir / "style-check.ts"
    fixture.write_text("const configuredStyle: PanelStyle = " + json.dumps(style) + ";\n")
    subprocess.run(["tsc", "--noEmit", "--strict", "--lib", "ES2017",
                    str(fedora_dir / "plasma/style.d.ts"), str(fixture)], check=True)
    for group, entries in style.items():
        for key, value in entries.items():
            if isinstance(value, (int, float)) and (value < 0 or not math.isfinite(value)):
                raise ValueError(f"Style value {group}.{key} must be finite and nonnegative.")
    if any(not isinstance(style["bar"][key], int) for key in ("height", "padding")):
        raise ValueError("Bar height and padding must use whole logical pixels.")
    if not 0 <= style["bar"]["opacity"] <= 100:
        raise ValueError("Bar opacity must be between zero and one hundred.")
    if style["bar"]["height"] < max(style["workspaces"]["height"], 2 * style["status"]["size"]):
        raise ValueError("Bar height must fit workspace buttons and status text.")
    for project in ("kwin/shortcuts", "kwin/krohnkite", "plasma"):
        subprocess.run(["tsc", "--project", str(fedora_dir / project)], check=True)
    patch_krohnkite(fedora_dir, build_dir)

    for filename in ("panels.js", "toggle.js"):
        path = build_dir / "plasma" / filename
        path.write_text("(() => { const style = " + json.dumps(style) + ";\n" + path.read_text() + "\n})();\n")

    script = build_dir / "kwin/shortcuts/contents/code/main.js"
    toggle = (build_dir / "plasma/toggle.js").read_text()
    script.write_text("const panelToggleScript = " + json.dumps(toggle) + ";\n" + script.read_text())

    widget_dir = build_dir / "plasma/bar"
    if widget_dir.exists():
        shutil.rmtree(widget_dir)
    shutil.copytree(packages["workspaces.plasmoid"], widget_dir)
    (widget_dir / "contents/ui/Style.js").write_text(".pragma library\nvar config = " + json.dumps(style) + ";\n")
    padding = style["bar"]["padding"]
    hints = [f'<rect id="floating-hint-{edge}-margin" width="{padding}" height="{padding}"/>'
             for edge in ("left", "right", "top", "bottom")]
    (widget_dir / "contents/icons/panel-margins.svg").write_text(
        '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64">'
        '<rect id="floating-center" width="1" height="1"/>' + "".join(hints) + '</svg>\n')
    packages["workspaces.plasmoid"] = widget_dir

    for filename, source_dir in packages.items():
        sources = {
            source.relative_to(source_dir).as_posix(): source
            for source in [source_dir / "metadata.json", *sorted((source_dir / "contents").rglob("*"))]
            if source.is_file() and source.suffix != ".ts"
        }
        if filename == "workspaces.kwinscript":
            sources["contents/code/main.js"] = build_dir / "kwin/shortcuts/contents/code/main.js"

        with ZipFile(build_dir / filename, "w", compression=ZIP_DEFLATED) as archive:
            for name, source in sorted(sources.items()):
                entry = ZipInfo(name)
                entry.compress_type = ZIP_DEFLATED
                entry.external_attr = 0o100644 << 16
                archive.writestr(entry, source.read_bytes())
        print(build_dir / filename)


if __name__ == "__main__":
    main()
