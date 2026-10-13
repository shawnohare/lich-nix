"""Exercise maintenance workflows with fake tools; never fetch/update gems."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT_BIN = Path(os.environ.get("LICHNIX_MAINTENANCE_BIN", str(ROOT / "bin")))
SCRIPTS = ("check-runtime", "update-gems", "update-lich-dependencies", "sync-lich-checkout")


class MaintenanceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="lich-maintenance-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.repo = self.base / "repository with spaces"
        (self.repo / "bin").mkdir(parents=True)
        (self.repo / "nix/gems").mkdir(parents=True)
        for name in SCRIPTS:
            shutil.copy(SCRIPT_BIN / name, self.repo / "bin" / name)
        self.source = self.base / "pinned source"
        self.source.mkdir()
        (self.source / "Gemfile").write_text("pinned upstream Gemfile\n")
        (self.source / "Gemfile").chmod(0o444)
        (self.source / "Gemfile.lock").write_text("pinned upstream lockfile\n")
        (self.source / "Gemfile.lock").chmod(0o444)
        self.data_root = self.base / "data root"
        self.checkout = self.data_root / "packaged/lich-5"
        self.checkout.mkdir(parents=True)
        (self.checkout / ".git").mkdir()
        self.log = self.base / "commands.jsonl"
        fake_bin = self.base / "tools"
        fake_bin.mkdir()
        mock = '''#!/usr/bin/env python3
import json, os, pathlib, subprocess, sys
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ["COMMAND_LOG"], "a") as log:
    log.write(json.dumps([name, args, os.getcwd()]) + "\\n")
if name == "nix":
    if args[0] == "eval":
        print(os.environ["PINNED_SOURCE"] if "outPath" in args[-1] else "pinned-revision")
    elif args[0] == "develop":
        sys.exit(subprocess.call(args[args.index("--command") + 1:]))
elif name == "bundix" and os.environ.get("FAIL_BUNDIX"):
    sys.exit(23)
elif name == "git":
    if args[0] == "clone":
        checkout = pathlib.Path(args[-1])
        checkout.mkdir(exist_ok=True)
        (checkout / ".git").mkdir()
    elif args[2:4] == ["rev-parse", "--show-toplevel"]:
        if not (pathlib.Path(args[1]) / ".git").is_dir():
            sys.exit(128)
        print(args[1])
    elif args[2] == "diff" and os.environ.get("DIRTY_CHECKOUT"):
        sys.exit(1)
'''
        for name in ("nix", "bundle", "bundix", "git"):
            tool = fake_bin / name
            tool.write_text(mock)
            tool.chmod(0o755)
        self.env = dict(os.environ, HOME=str(self.base),
                        PATH=f"{fake_bin}:{os.environ['PATH']}",
                        COMMAND_LOG=str(self.log), PINNED_SOURCE=str(self.source),
                        LICHNIX_DATA_HOME=str(self.data_root))

    def run_helper(self, name, *args):
        # Run from outside the repository to verify script-relative paths.
        return subprocess.run([str(self.repo / "bin" / name), *args],
                              cwd=self.base, env=self.env, capture_output=True,
                              text=True, timeout=30)

    def commands(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def test_regenerate_uses_upstream_files_without_resolving_versions(self):
        result = self.run_helper("update-gems")
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.commands()
        self.assertEqual([c[0] for c in calls],
                         ["nix", "nix", "bundix", "nix", "nix", "nix"])
        self.assertEqual(calls[2][1], [
            f"--gemfile={self.source}/Gemfile",
            f"--lockfile={self.source}/Gemfile.lock",
            f"--gemset={self.repo}/nix/gems/gemset.nix",
        ])
        self.assertEqual(calls[2][2], str(self.repo))
        self.assertEqual(calls[4][1], ["build", "--no-link", ".#lich-development-gems"])
        self.assertEqual(calls[5][1], ["flake", "check"])
        self.assertFalse((self.repo / "nix/gems/Gemfile").exists())
        self.assertEqual((self.source / "Gemfile.lock").read_text(),
                         "pinned upstream lockfile\n")

    def test_targeted_updates_are_rejected_before_running_tools(self):
        result = self.run_helper("update-gems", "sqlite3")
        self.assertEqual(result.returncode, 2)
        self.assertIn("pinned by upstream", result.stderr)
        self.assertFalse(self.log.exists())

    def test_release_updates_pin_then_regenerates_from_upstream_lock(self):
        result = self.run_helper("update-lich-dependencies")
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.commands()
        self.assertEqual(calls[0][1], ["flake", "update", "lich-src"])
        self.assertEqual(next(c[1] for c in calls if c[0] == "bundix")[1],
                         f"--lockfile={self.source}/Gemfile.lock")
        self.assertFalse(any(c[0] in ("bundle", "git") for c in calls))

    def test_failed_generation_stops_builds(self):
        self.env["FAIL_BUNDIX"] = "1"
        result = self.run_helper("update-gems")
        self.assertEqual(result.returncode, 23)
        self.assertEqual([c[0] for c in self.commands()], ["nix", "nix", "bundix"])

    def test_sync_checkout_preserves_application_data(self):
        self.env["LICHNIX_SRC_HOME"] = "/missing"
        data = self.checkout / "credentials.fixture"
        data.write_text("local application data")
        result = self.run_helper("sync-lich-checkout")
        self.assertEqual(result.returncode, 0, result.stderr)
        git_args = [c[1][2:] for c in self.commands() if c[0] == "git"]
        self.assertEqual(git_args[-2:], [["fetch", "--tags"],
                                        ["switch", "--detach", "pinned-revision"]])
        self.assertEqual(data.read_text(), "local application data")

    def test_dirty_checkout_stops_before_fetch_or_switch(self):
        self.env["DIRTY_CHECKOUT"] = "1"
        result = self.run_helper("sync-lich-checkout")
        self.assertEqual(result.returncode, 1)
        self.assertIn("Commit or stash", result.stderr)
        self.assertEqual([c[1][2] for c in self.commands()], ["rev-parse", "diff"])

    def test_sync_uses_data_root_ignoring_writeable_source(self):
        self.env["LICHNIX_WRITEABLE_SRC_HOME"] = "/missing/writeable"
        self.env["LICHNIX_SRC_HOME"] = "/missing/obsolete"
        result = self.run_helper("sync-lich-checkout")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.commands()[0][1][:2], ["-C", str(self.checkout)])

    def test_sync_clones_missing_or_empty_destination(self):
        for data_root in (self.base / "new parent", self.base / "empty root"):
            destination = data_root / "packaged/lich-5"
            with self.subTest(destination=destination):
                if data_root.name == "empty root":
                    destination.mkdir(parents=True)
                self.log.write_text("")
                # Relative paths are interpreted from the caller's working directory.
                self.env["LICHNIX_DATA_HOME"] = str(data_root.relative_to(self.base))
                result = self.run_helper("sync-lich-checkout")
                self.assertEqual(result.returncode, 0, result.stderr)
                calls = self.commands()
                self.assertEqual(calls[0][1], ["clone", "--",
                    "https://github.com/elanthia-online/lich-5.git", str(destination)])
                self.assertEqual(calls[-1][1][2:], ["switch", "--detach", "pinned-revision"])
                self.assertTrue((destination / ".git").is_dir())

    def test_sync_refuses_nonempty_directory_without_repository(self):
        self.env["LICHNIX_DATA_HOME"] = str(self.base / "existing data")
        destination = self.base / "existing data/packaged/lich-5"
        destination.mkdir(parents=True)
        data = destination / "credentials.fixture"
        data.write_text("keep this data")
        result = self.run_helper("sync-lich-checkout")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(data.read_text(), "keep this data")
        self.assertEqual(len(self.commands()), 1)
        self.assertEqual(self.commands()[0][1][2], "rev-parse")


if __name__ == "__main__":
    unittest.main()
