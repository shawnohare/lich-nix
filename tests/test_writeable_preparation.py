"""Exercise checkout creation with local Git repos and a mocked gem installer."""
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import unittest


class WriteablePreparation(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name).resolve()
        self.source = self.root / 'upstream source'
        self.git('init', '-b', 'main', str(self.source))
        (self.source / 'lich.rbw').write_text('pinned release\n')
        (self.source / 'Gemfile').write_text('source "https://rubygems.org"\n')
        self.git('-C', str(self.source), 'add', '.')
        self.git('-C', str(self.source), 'commit', '-m', 'pinned release')
        self.pin = self.git('-C', str(self.source), 'rev-parse', 'HEAD').stdout.strip()
        (self.source / 'lich.rbw').write_text('default branch\n')
        self.git('-C', str(self.source), 'commit', '-am', 'newer default branch')
        self.tip = self.git('-C', str(self.source), 'rev-parse', 'HEAD').stdout.strip()
        self.checkout = self.root / 'nested' / 'checkout with spaces'
        self.runtime = self.root / 'runtime'
        (self.runtime / 'bin').mkdir(parents=True)
        self.log = self.root / 'runtime-calls'
        ruby = self.runtime / 'bin/ruby-lich-w'
        ruby.write_text('''#!/usr/bin/env bash
set -eu
printf '%s\\n' "$*" >> "$TEST_RUNTIME_LOG"
if [[ ${1:-} == -e && ${2:-} == 'print Gem.dir' ]]; then
  printf '%s' "$LICHNIX_WRITEABLE_SRC_HOME/.bundle/test-gems"
fi
''')
        ruby.chmod(0o755)
        tools = self.root / 'tools'
        tools.mkdir()
        nix = tools / 'nix-store'
        nix.write_text('#!/usr/bin/env bash\nexit 0\n')
        nix.chmod(0o755)
        self.env = dict(os.environ, PATH=f"{tools}:{os.environ['PATH']}",
                        TEST_RUNTIME_LOG=str(self.log))
        self.template = Path(os.environ.get('PREPARE_TEMPLATE',
            str(Path(__file__).resolve().parents[1] / 'nix/prepare-writeable.sh'))).read_text()

    def git(self, *args):
        return subprocess.run(['git', '-c', 'user.name=Fixture', '-c',
                               'user.email=fixture@example.test', *args],
                              check=True, text=True, capture_output=True)

    def prepare(self, pin=None, explicit_path=True):
        script = self.root / 'prepare'
        script.write_text(self.template
            .replace('@runtime@', str(self.runtime))
            .replace('@bash@', shutil.which('bash'))
            .replace('@lichRev@', pin or self.pin)
            .replace('https://github.com/elanthia-online/lich-5.git', shlex.quote(str(self.source))))
        return subprocess.run(['bash', str(script)] + ([str(self.checkout)] if explicit_path else []),
                              env=self.env, text=True, capture_output=True)

    def test_new_clone_uses_pin_instead_of_default_branch(self):
        result = self.prepare()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.git('-C', str(self.checkout), 'rev-parse', 'HEAD').stdout.strip(), self.pin)
        self.assertEqual(self.git('-C', str(self.checkout), 'rev-parse', '--abbrev-ref', 'HEAD').stdout.strip(), 'HEAD')
        self.assertTrue((self.checkout / '.bundle/bin/ruby-lich-w').is_file())
        self.assertTrue((self.checkout / '.bundle/bin/lich-w').is_file())
        self.assertFalse((self.checkout / '.bundle/bin/ruby-lich').exists())
        self.assertFalse((self.checkout / '.bundle/bin/lich').exists())
        self.assertIn('-S bundle install', self.log.read_text())

    def test_default_writeable_location_uses_data_root(self):
        self.env.pop('LICHNIX_WRITEABLE_SRC_HOME', None)
        data_root = self.root / 'custom data root'
        self.env['LICHNIX_DATA_HOME'] = str(data_root)
        result = self.prepare(explicit_path=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        checkout = data_root / 'src/lich-5'
        self.assertEqual(self.git('-C', str(checkout), 'rev-parse', 'HEAD').stdout.strip(), self.pin)
        launcher = (checkout / '.bundle/bin/ruby-lich-w').read_text()
        self.assertIn('LICHNIX_WRITEABLE_SRC_HOME=', launcher)

    def test_existing_checkout_keeps_revision_and_edits(self):
        self.checkout.parent.mkdir()
        self.git('clone', str(self.source), str(self.checkout))
        (self.checkout / 'lich.rbw').write_text('local edits\n')
        result = self.prepare()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.git('-C', str(self.checkout), 'rev-parse', 'HEAD').stdout.strip(), self.tip)
        self.assertEqual((self.checkout / 'lich.rbw').read_text(), 'local edits\n')

    def test_existing_worktree_is_not_cloned_or_switched(self):
        self.checkout.parent.mkdir()
        self.git('-C', str(self.source), 'worktree', 'add', '--detach', str(self.checkout), self.tip)
        self.assertTrue((self.checkout / '.git').is_file())
        result = self.prepare()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.git('-C', str(self.checkout), 'rev-parse', 'HEAD').stdout.strip(), self.tip)

    def test_nonempty_destination_is_preserved(self):
        self.checkout.mkdir(parents=True)
        marker = self.checkout / 'user-data'
        marker.write_text('keep me')
        result = self.prepare()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(marker.read_text(), 'keep me')
        self.assertFalse(self.log.exists())

    def test_failed_pin_checkout_stops_before_gem_install(self):
        result = self.prepare(pin='0' * 40)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.log.exists())


if __name__ == '__main__':
    unittest.main()
