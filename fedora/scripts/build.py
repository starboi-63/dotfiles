#!/usr/bin/env python3
"""Builds Plasma packages without modifying desktop configuration."""

from pathlib import Path
import hashlib
import json
import math
import shutil
import subprocess
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / ".build"
PACKAGES = {
    "shortcuts.kwinscript": ROOT / "kwin/shortcuts",
    "bar.plasmoid": ROOT / "plasma/bar",
    "dock.plasmoid": ROOT / "plasma/dock",
}


def read_style():
    """Validates configured appearance values before compilation."""
    style = json.loads((ROOT / "style.json").read_text())
    fixture = BUILD / "style-check.ts"
    fixture.write_text("const configuredStyle: PanelStyle = " + json.dumps(style) + ";\n")
    subprocess.run(["tsc", "--noEmit", "--strict", "--lib", "ES2017",
                    str(ROOT / "plasma/style.d.ts"), str(fixture)], check=True)
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
    return style


def patch_krohnkite():
    """Packages pinned tiler with column minimum size handling."""
    source = BUILD / "krohnkite.kwinscript"
    if not source.exists():
        print("Download pinned Krohnkite archive and rebuild to prepare patched tiler.")
        return
    dependency = json.loads((ROOT / "dependencies.json").read_text())["krohnkite"]
    if hashlib.sha256(source.read_bytes()).hexdigest() != dependency["sha256"]:
        raise ValueError("Krohnkite archive does not match pinned checksum.")
    replacements = {
        "this.parts.apply(area, columnTileables, gap).forEach((geometry, i) => {":
            "fitColumnMinimums(this.parts.apply(area, columnTileables, gap), "
            "columnTileables.map(tile => tile.minSize), this.parts.angle === 270, gap).forEach((geometry, i) => {",
        "return this._minSize;": "return this.window.minSize;",
    }
    target = BUILD / "krohnkite-patched.kwinscript"
    with ZipFile(source) as archive:
        script = archive.read("contents/code/script.js").decode()
        for original, replacement in replacements.items():
            if script.count(original) != 1:
                raise ValueError("Krohnkite patch requires exactly one matching source location.")
            script = script.replace(original, replacement)
        script += "\n" + (BUILD / "kwin/krohnkite/minimums.js").read_text()
        (BUILD / "kwin/krohnkite/script.js").write_text(script)
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


def package_component(filename, source_dir):
    """Archives runtime files with reproducible ordering and metadata."""
    sources = {
        source.relative_to(source_dir).as_posix(): source
        for source in [source_dir / "metadata.json", *sorted((source_dir / "contents").rglob("*"))]
        if source.is_file() and source.suffix != ".ts"
    }
    if filename == "shortcuts.kwinscript":
        sources["contents/code/main.js"] = BUILD / "kwin/shortcuts/contents/code/main.js"
    target = BUILD / filename
    with ZipFile(target, "w", compression=ZIP_DEFLATED) as archive:
        for name, source in sorted(sources.items()):
            entry = ZipInfo(name)
            entry.compress_type = ZIP_DEFLATED
            entry.external_attr = 0o100644 << 16
            archive.writestr(entry, source.read_bytes())
    print(target)


def main():
    """Compiles configured runtime packages."""
    BUILD.mkdir(exist_ok=True)
    for filename in (*PACKAGES, "krohnkite-patched.kwinscript", "kwin/krohnkite/script.js"):
        (BUILD / filename).unlink(missing_ok=True)
    style = read_style()
    for project in ("kwin/shortcuts", "kwin/krohnkite", "plasma"):
        subprocess.run(["tsc", "--project", str(ROOT / project)], check=True)
    patch_krohnkite()

    panels = BUILD / "plasma/panels.js"
    panels.write_text("(() => { const style = " + json.dumps(style) + ";\n" + panels.read_text() + "\n})();\n")
    shortcuts = BUILD / "kwin/shortcuts/contents/code/main.js"
    toggle = (BUILD / "plasma/toggle.js").read_text()
    shortcuts.write_text("const panelToggleScript = " + json.dumps(toggle) + ";\n" + shortcuts.read_text())

    bar = BUILD / "plasma/bar"
    if bar.exists():
        shutil.rmtree(bar)
    shutil.copytree(PACKAGES["bar.plasmoid"], bar)
    (bar / "contents/ui/Style.js").write_text(".pragma library\nvar config = " + json.dumps(style) + ";\n")
    for filename, source in PACKAGES.items():
        package_component(filename, bar if filename == "bar.plasmoid" else source)


if __name__ == "__main__":
    main()
