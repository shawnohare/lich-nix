"""Run after `nix build .#saga-ruby`: python3 tests/test_saga_ruby.py.

Launcher regression checks run without Nix on the executable search path:

These cover Ruby version probes, missing-install diagnostics, desktop path
configuration, argument forwarding, exit status, and GTK runtime asset paths.
Packaged native gems are loaded with an empty home and stale Bundler settings
to prove the launcher does not depend on a user's bundle installation.
Saga login and extended gameplay remain separate manual checks.
"""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


LAUNCHER = Path(os.environ.get(
    "SAGA_RUBY", str(Path(__file__).resolve().parents[1] / "result/bin/saga-ruby")
))


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
        self.assertIn(str(self.home / ".local/share/lich-5"), result.stderr)

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
        self.assertNotIn("BUNDLE_PATH", env)
        self.assertTrue(env["BUNDLE_GEMFILE"].startswith("/nix/store/"))
        self.assertTrue(env["GEM_HOME"].startswith("/nix/store/"))
        self.assertEqual(env["GEM_HOME"], env["GEM_PATH"])
        self.assertTrue(Path(env["FONTCONFIG_FILE"]).is_file())
        self.assertTrue(Path(env["GDK_PIXBUF_MODULE_FILE"]).is_file())
        self.assertTrue(any(
            (Path(p) / "Atk-1.0.typelib").is_file()
            for p in env["GI_TYPELIB_PATH"].split(":")
        ))

    def test_checkout_environment_override(self):
        checkout = self.install_fixture(self.home / "custom checkout")
        self.env["LICH_SRC_HOME"] = str(checkout)
        result = self.run_ruby("-e", 'puts Dir.pwd')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), str(checkout.resolve()))

    def test_packaged_native_gems_with_empty_home_and_stale_config(self):
        checkout = self.install_fixture()
        (checkout / ".bundle").mkdir()
        (checkout / ".bundle/config").write_text(
            'BUNDLE_PATH: "/missing"\nBUNDLE_WITHOUT: "gtk:profanity"\n'
        )
        self.env.update({
            "BUNDLE_GEMFILE": "/missing/Gemfile",
            "BUNDLE_PATH": "/missing/bundle",
            "GEM_HOME": "/missing/gems",
            "GEM_PATH": "/missing/gems",
            "BUNDLE_WITHOUT": "gtk:profanity",
            "BUNDLE_WITH": "development:vscode",
        })
        result = self.run_ruby("-e", '''
require "sqlite3"
require "curses"
require "openssl"
require "ffi"
require "yaml"
require "zlib"
require "glib2"
require "gobject-introspection"
require "gtk3"
# Load GTK's typelib and shared libraries without opening a display/window.
GObjectIntrospection::Repository.default.require("Gtk", "3.0")
db = SQLite3::Database.new(":memory:")
raise "SQLite failed" unless db.get_first_value("select 42") == 42
names = %w[sqlite3 curses openssl ffi yaml zlib glib2 gobject-introspection gtk3]
raise "external gem loaded" unless names.all? { |name|
  Gem.loaded_specs.fetch(name).full_gem_path.start_with?("/nix/store/")
}
puts "packaged native gems loaded"
''')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("packaged native gems loaded", result.stdout)


if __name__ == "__main__":
    unittest.main()
