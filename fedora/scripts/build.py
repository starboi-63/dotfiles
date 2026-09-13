#!/usr/bin/env python3
"""Packages workspace components inside repository."""

from pathlib import Path
import json
import subprocess
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo


def main():
    """Compiles scripts and packages workspace components without installing them."""
    fedora_dir = Path(__file__).resolve().parents[1]
    build_dir = fedora_dir / ".build"
    packages = {
        "workspaces.kwinscript": fedora_dir / "kwin/workspaces",
        "workspaces.plasmoid": fedora_dir / "plasma/workspaces",
    }
    build_dir.mkdir(exist_ok=True)

    for filename in packages:
        (build_dir / filename).unlink(missing_ok=True)
    for project in ("kwin/workspaces", "plasma"):
        subprocess.run(["tsc", "--project", str(fedora_dir / project)], check=True)

    script = build_dir / "kwin/workspaces/contents/code/main.js"
    toggle = (build_dir / "plasma/toggle.js").read_text()
    script.write_text("const panelToggleScript = " + json.dumps(toggle) + ";\n" + script.read_text())

    for filename, source_dir in packages.items():
        sources = {
            source.relative_to(source_dir).as_posix(): source
            for source in [source_dir / "metadata.json", *sorted((source_dir / "contents").rglob("*"))]
            if source.is_file() and source.suffix != ".ts"
        }
        if filename == "workspaces.kwinscript":
            sources["contents/code/main.js"] = build_dir / "kwin/workspaces/contents/code/main.js"

        with ZipFile(build_dir / filename, "w", compression=ZIP_DEFLATED) as archive:
            for name, source in sorted(sources.items()):
                entry = ZipInfo(name)
                entry.compress_type = ZIP_DEFLATED
                entry.external_attr = 0o100644 << 16
                archive.writestr(entry, source.read_bytes())
        print(build_dir / filename)


if __name__ == "__main__":
    main()
