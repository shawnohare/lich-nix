"""Run after `nix build .#saga-ruby`: python3 tests/test_saga_ruby.py.

Launcher regression checks run without Nix on the executable search path:

These cover Ruby version probes, missing-install diagnostics, desktop path
configuration, argument forwarding, exit status, and GTK runtime asset paths.
Loading the existing GTK, SQLite, and curses gems was also verified with a
minimal environment. Saga login from Spotlight was confirmed manually;
extended gameplay remains a separate manual check.
"""

import json
from pathlib import Path
import subprocess
import tempfile
import unittest


LAUNCHER = Path(__file__).resolve().parents[1] / "result/bin/saga-ruby"


class LauncherTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="saga-ruby-")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.env = {"HOME": str(self.home), "PATH": "/usr/bin:/bin"}

    def run_ruby(self, *args):
        return subprocess.run(
            [str(LAUNCHER), *args],
            env=self.env,
            cwd="/",
            capture_output=True,
            text=True,
            timeout=30,
        )

    def install_fixture(self, checkout=None):
        checkout = checkout or self.home / ".local/share/lich-5"
        checkout.mkdir(parents=True)
        (checkout / "Gemfile").write_text('source "https://rubygems.org"\n')
        return checkout

    def test_version_without_nix_or_checkout(self):
        for option in ("--version", "-v"):
            result = self.run_ruby(option)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("ruby 4.0.", result.stdout)

    def test_missing_arguments_and_checkout(self):
        self.assertEqual(self.run_ruby().returncode, 2)
        result = self.run_ruby("lich.rbw")
        self.assertEqual(result.returncode, 1)
        self.assertIn(str(self.home / ".local/share/lich-5/Gemfile"), result.stderr)

    def test_arguments_environment_and_exit_status(self):
        checkout = self.install_fixture()
        script = checkout / "script with spaces.rb"
        script.write_text(
            'require "json"\n'
            'puts JSON.generate([ARGV, Dir.pwd, ENV.to_h])\n'
            'exit 17\n'
        )
        result = self.run_ruby(str(script), "argument with spaces", "--no-gtk")
        self.assertEqual(result.returncode, 17, result.stderr)
        args, cwd, env = json.loads(result.stdout.splitlines()[-1])
        self.assertEqual(args, ["argument with spaces", "--no-gtk"])
        self.assertEqual(cwd, str(checkout.resolve()))
        self.assertEqual(env["BUNDLE_PATH"], str(self.home / ".local/share/lich-nix/bundle"))
        self.assertTrue(Path(env["FONTCONFIG_FILE"]).is_file())
        self.assertTrue(Path(env["GDK_PIXBUF_MODULE_FILE"]).is_file())
        self.assertTrue(any(
            (Path(p) / "Atk-1.0.typelib").is_file()
            for p in env["GI_TYPELIB_PATH"].split(":")
        ))

    def test_desktop_configuration_overrides_environment(self):
        checkout = self.install_fixture(self.home / "custom checkout")
        config = self.home / "custom config/lich-nix"
        config.mkdir(parents=True)
        (config / "runtime.sh").write_text(f'export LICH_SRC_HOME="{checkout}"\n')
        self.env.update({
            "XDG_CONFIG_HOME": str(config.parent),
            "LICH_SRC_HOME": "/missing",
        })
        result = self.run_ruby("-e", 'puts ENV.fetch("BUNDLE_GEMFILE")')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(str(checkout / "Gemfile"), result.stdout)


if __name__ == "__main__":
    unittest.main()
