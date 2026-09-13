"""Checks window rule registration through native KConfig commands."""

from pathlib import Path
import os
import subprocess
import sys
from tempfile import TemporaryDirectory

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from configure import register_window_rules


def main():
    """Verifies rule ordering, repeat registration, and preservation of unrelated settings."""
    previous = os.environ.get("XDG_CONFIG_HOME")
    try:
        with TemporaryDirectory(prefix="workspace-rules-") as directory:
            os.environ["XDG_CONFIG_HOME"] = directory
            location = ["--file", "kwinrulesrc", "--group", "General", "--key", "rules"]
            register_window_rules(["initial-tiling"])
            assert subprocess.check_output(["kreadconfig6", *location], text=True).strip() == "initial-tiling"
            subprocess.run(["kwriteconfig6", *location, "existing-first,existing-second"], check=True)
            subprocess.run(["kwriteconfig6", "--file", "kwinrulesrc", "--group", "existing-first",
                            "--key", "Description", "Preserved window rule"], check=True)
            register_window_rules(["initial-tiling"])
            assert subprocess.check_output(["kreadconfig6", *location], text=True).strip() == "existing-first,existing-second,initial-tiling"
            path = Path(directory) / "kwinrulesrc"
            applied = path.read_bytes()
            register_window_rules(["initial-tiling"])
            assert path.read_bytes() == applied
            assert b"Description=Preserved window rule" in applied
            print("Passed new registration, existing rule precedence, and byte-identical repeat registration")
    finally:
        if previous is None:
            os.environ.pop("XDG_CONFIG_HOME", None)
        else:
            os.environ["XDG_CONFIG_HOME"] = previous


if __name__ == "__main__":
    main()
