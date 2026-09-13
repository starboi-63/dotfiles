"""Checks shared configuration links and destination preservation."""

import contextlib
import importlib.util
import io
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("link", ROOT / "scripts/link.py")
LINK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(LINK)


class LinkTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.target = Path(self.directory.name) / "home"

    def configure(self, platform="fedora", *options):
        """Runs linker against isolated destinations."""
        arguments = ["link.py", platform, "--target", str(self.target), *options]
        with patch("sys.argv", arguments), contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            return LINK.main()

    def test_platform_links_remain_identical_after_reapplication(self):
        for platform in ("fedora", "macos"):
            with self.subTest(platform=platform):
                self.target = Path(self.directory.name) / platform
                self.assertEqual(self.configure(platform), 0)
                self.assertEqual((self.target / ".vimrc").resolve(), ROOT / "shared/home/.vimrc")
                self.assertEqual((self.target / ".zshrc").resolve(), ROOT / platform / "home/.zshrc")
                self.assertEqual(
                    (self.target / ".config/ghostty/platform.conf").resolve(),
                    ROOT / platform / "home/.config/ghostty/platform.conf",
                )
                links = {path: path.lstat().st_ino for path in self.target.rglob("*") if path.is_symlink()}
                self.assertTrue(all(path.exists() for path in links))
                self.assertEqual(self.configure(platform), 0)
                self.assertEqual(links, {path: path.lstat().st_ino for path in links})

    def test_preview_creates_no_paths(self):
        self.assertEqual(self.configure("fedora", "--check"), 0)
        self.assertFalse(self.target.exists())

    def test_conflicts_prevent_all_writes(self):
        for kind in ("file", "parent", "dangling"):
            with self.subTest(kind=kind):
                self.target = Path(self.directory.name) / kind
                self.target.mkdir()
                conflict = self.target / (".config" if kind == "parent" else ".zshrc")
                if kind == "dangling":
                    conflict.symlink_to("missing")
                else:
                    conflict.write_text("preserve")
                self.assertEqual(self.configure(), 1)
                self.assertEqual(list(self.target.iterdir()), [conflict])
                if kind == "dangling":
                    self.assertEqual(os.readlink(conflict), "missing")
                else:
                    self.assertEqual(conflict.read_text(), "preserve")

    def test_custom_config_directory_and_explicit_target(self):
        config = Path(self.directory.name) / "config"
        with patch.dict(os.environ, {"XDG_CONFIG_HOME": str(config)}), patch.object(Path, "home", return_value=self.target):
            with patch("sys.argv", ["link.py", "fedora"]), contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(LINK.main(), 0)
            self.assertTrue((config / "ghostty/config.ghostty").is_symlink())
            self.assertTrue((self.target / ".zshrc").is_symlink())
            self.assertFalse((self.target / ".config").exists())
            self.target = Path(self.directory.name) / "staged"
            self.assertEqual(self.configure(), 0)
            self.assertTrue((self.target / ".config/ghostty/config.ghostty").is_symlink())


if __name__ == "__main__":
    unittest.main()
