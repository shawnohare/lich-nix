"""Check first-launch initialization against a local Git repository, offline."""
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest


class PackagedPreparation(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name).resolve()
        self.source = self.root / 'upstream with spaces'
        self.git('init', '-b', 'main', str(self.source))
        (self.source / 'lich.rbw').write_text('pinned release\n')
        (self.source / 'Gemfile').write_text('# fixture\n')
        self.git('-C', str(self.source), 'add', '.')
        self.git('-C', str(self.source), 'commit', '-m', 'release')
        self.pin = self.git('-C', str(self.source), 'rev-parse', 'HEAD').stdout.strip()
        (self.source / 'lich.rbw').write_text('default branch\n')
        self.git('-C', str(self.source), 'commit', '-am', 'newer default branch')
        self.tip = self.git('-C', str(self.source), 'rev-parse', 'HEAD').stdout.strip()
        self.data_root = self.root / 'data with spaces'
        self.checkout = self.data_root / 'packaged/lich-5'
        self.env = dict(os.environ, LICHNIX_DATA_HOME=str(self.data_root),
                        LICHNIX_WRITEABLE_SRC_HOME='/missing/writeable')
        template_path = os.environ.get('PACKAGED_TEMPLATE',
            str(Path(__file__).resolve().parents[1] / 'nix/ensure-packaged.sh'))
        self.template = Path(template_path).read_text()

    def git(self, *args):
        return subprocess.run(['git', '-c', 'user.name=Fixture', '-c',
                               'user.email=fixture@example.test', *args],
                              check=True, text=True, capture_output=True)

    def initialize(self, pin=None):
        script = self.root / 'initialize'
        script.write_text(self.template.replace('@lichRev@', pin or self.pin)
            .replace('https://github.com/elanthia-online/lich-5.git', shlex.quote(str(self.source))))
        return subprocess.run(['bash', str(script)], env=self.env,
                              text=True, capture_output=True)

    def test_missing_checkout_uses_pin_and_repeat_needs_no_upstream(self):
        result = self.initialize()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.git('-C', str(self.checkout), 'rev-parse', 'HEAD').stdout.strip(), self.pin)
        self.assertEqual(self.git('-C', str(self.checkout), 'rev-parse', '--abbrev-ref', 'HEAD').stdout.strip(), 'HEAD')
        self.source.rename(self.root / 'unavailable upstream')
        result = self.initialize()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, '')

    def test_empty_destination_can_be_initialized(self):
        self.checkout.mkdir(parents=True)
        result = self.initialize()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.checkout / '.git').exists())

    def test_existing_checkout_keeps_branch_revision_and_edits(self):
        self.checkout.parent.mkdir(parents=True)
        self.git('clone', str(self.source), str(self.checkout))
        (self.checkout / 'lich.rbw').write_text('local changes\n')
        result = self.initialize()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.git('-C', str(self.checkout), 'rev-parse', 'HEAD').stdout.strip(), self.tip)
        self.assertEqual(self.git('-C', str(self.checkout), 'branch', '--show-current').stdout.strip(), 'main')
        self.assertEqual((self.checkout / 'lich.rbw').read_text(), 'local changes\n')

    def test_worktree_is_an_existing_checkout(self):
        self.checkout.parent.mkdir(parents=True)
        self.git('-C', str(self.source), 'worktree', 'add', '--detach', str(self.checkout), self.tip)
        result = self.initialize()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.git('-C', str(self.checkout), 'rev-parse', 'HEAD').stdout.strip(), self.tip)

    def test_nonempty_non_repository_destination_is_preserved(self):
        self.checkout.mkdir(parents=True)
        marker = self.checkout / 'user-data'
        marker.write_text('keep me')
        result = self.initialize()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(marker.read_text(), 'keep me')
        self.assertFalse((self.checkout / '.git').exists())

    def test_failed_checkout_is_not_published_and_can_be_retried(self):
        result = self.initialize(pin='0' * 40)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.checkout.exists())
        self.assertEqual(list(self.checkout.parent.glob('.lich-5.*')), [])
        result = self.initialize()
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == '__main__':
    unittest.main()
