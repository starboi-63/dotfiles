#!/usr/bin/env python3
"""Links shared and platform configuration into user directories."""

import argparse
import os
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]


def configuration_files(platform):
    """Returns source files indexed by their home directory paths."""
    files = {}
    for directory in (ROOT / "shared/home", ROOT / platform / "home"):
        for source in sorted(directory.rglob("*")):
            if not source.is_file():
                continue
            relative = source.relative_to(directory)
            if relative in files:
                raise ValueError(f"Duplicate configuration path {relative}.")
            files[relative] = source
    return files


def main():
    """Checks destination conflicts before creating missing configuration links."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("platform", choices=("fedora", "macos"))
    parser.add_argument("--target", type=Path, help="Stage files in another home directory.")
    parser.add_argument("--check", action="store_true", help="Report changes without creating links.")
    arguments = parser.parse_args()
    target = (arguments.target or Path.home()).absolute()
    config = target / ".config" if arguments.target else Path(os.environ.get("XDG_CONFIG_HOME", target / ".config"))
    pending = []
    conflicts = set()

    for relative, source in configuration_files(arguments.platform).items():
        destination = config / relative.relative_to(".config") if relative.parts[0] == ".config" else target / relative
        if destination.resolve() == source.resolve():
            continue
        if destination.exists() or destination.is_symlink():
            conflicts.add(destination)
        for parent in destination.parents:
            if (parent.exists() or parent.is_symlink()) and not parent.is_dir():
                conflicts.add(parent)
        pending.append((source, destination))

    if conflicts:
        for path in sorted(conflicts):
            print(f"Existing path requires relocation: {path}", file=sys.stderr)
        return 1
    if arguments.check:
        print(f"{len(pending)} links ready to create.")
        return 0

    for source, destination in pending:
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.symlink_to(source)
    print(f"Created {len(pending)} links for {arguments.platform}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
