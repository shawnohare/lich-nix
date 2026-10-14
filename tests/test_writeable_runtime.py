"""Verify writable RubyGems and inherited raw-Ruby child behavior, offline."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


class WriteableRuntime(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name).resolve()
        self.checkout = self.root / 'checkout with spaces'
        self.checkout.mkdir()
        self.env = dict(os.environ, HOME=str(self.root), LICHNIX_WRITEABLE_SRC_HOME=str(self.checkout))
        for key in ('LICHNIX_GEM_HOME', 'RUBYOPT', 'GEM_HOME', 'GEM_PATH'):
            self.env.pop(key, None)

    def ruby(self, *args):
        return subprocess.run([os.environ['RUBY_LICH'], *args], env=self.env,
                              cwd=self.root, text=True, capture_output=True)

    def test_ruby_semantics_and_stale_bundle_configuration(self):
        self.env.update(BUNDLE_PATH='/nonexistent', BUNDLE_FROZEN='1',
                        GEM_HOME='/nonexistent', GEM_PATH='/nonexistent')
        result = self.ruby('-e', 'require "json"; puts JSON.generate([Dir.pwd, ARGV, Gem.dir, Gem.user_dir])', 'hello world')
        self.assertEqual(result.returncode, 0, result.stderr)
        cwd, args, home, user = json.loads(result.stdout)
        self.assertEqual(cwd, str(self.root))
        self.assertEqual(args, ['hello world'])
        self.assertEqual(home, user)
        self.assertTrue(home.startswith(str(self.checkout / '.bundle')))
        self.assertEqual(self.ruby('-e', 'exit 17').returncode, 17)

    def test_writeable_default_and_shared_data_root(self):
        self.env.pop('LICHNIX_WRITEABLE_SRC_HOME')
        self.env.pop('LICHNIX_DATA_HOME', None)
        self.env.pop('XDG_DATA_HOME', None)
        for data_root in (None, self.root / 'custom data root'):
            if data_root is not None:
                self.env['LICHNIX_DATA_HOME'] = str(data_root)
            expected = (data_root or self.root / '.local/share/lichnix') / 'src/lich-5'
            result = self.ruby('-e', 'puts ENV.fetch("LICHNIX_WRITEABLE_SRC_HOME"); puts Gem.dir')
            self.assertEqual(result.returncode, 0, result.stderr)
            source, gems = result.stdout.splitlines()
            self.assertEqual(source, str(expected))
            self.assertTrue(gems.startswith(str(expected / '.bundle')))

    def test_user_install_and_fresh_raw_ruby_child(self):
        code = r'''
require "rubygems/package"
require "fileutils"
FileUtils.mkdir_p("lib")
FileUtils.mkdir_p("ext/lich_probe_native")
File.write("ext/lich_probe_native/extconf.rb", 'require "mkmf"; abort "missing Nix zlib headers/libraries" unless have_header("zlib.h") && have_library("z", "zlibVersion"); create_makefile("lich_probe_native")')
File.write("ext/lich_probe_native/probe.c", '#include "ruby.h"
void Init_lich_probe_native(void) { rb_define_const(rb_cObject, "LICH_NATIVE_PROBE", INT2NUM(43)); }
')
File.write("lib/lich_probe.rb", "LICH_PROBE = 42\n")
spec = Gem::Specification.new do |s|
  s.name = "lich-probe"; s.version = "1.0.0"
  s.summary = "offline launcher probe"; s.authors = ["test"]
  s.files = ["lib/lich_probe.rb", "ext/lich_probe_native/extconf.rb", "ext/lich_probe_native/probe.c"]
  s.extensions = ["ext/lich_probe_native/extconf.rb"]
end
path = Gem::Package.build(spec)
Gem::DependencyInstaller.new(user_install: true, document: []).install(path)
exit(system(Gem.ruby, "-e", 'require "lich_probe"; require "lich_probe_native"; exit(LICH_PROBE == 42 && LICH_NATIVE_PROBE == 43 && Gem.user_dir == ENV.fetch("LICHNIX_GEM_HOME") ? 0 : 1)') ? 0 : 1)
'''
        # DependencyInstaller must be explicitly required, as upstream does.
        result = self.ruby('-rrubygems/dependency_installer', '-e', code)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_lich_checkout_and_arguments(self):
        (self.checkout / 'lich.rbw').write_text('puts Dir.pwd; puts ARGV; exit 13\n')
        result = subprocess.run([os.environ['LICH'], '--example'], env=self.env,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 13, result.stderr)
        self.assertEqual(result.stdout.splitlines(), [str(self.checkout), '--example'])


if __name__ == '__main__':
    unittest.main()
