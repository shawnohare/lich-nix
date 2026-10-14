"""Offline state seeding and package switching; never modify real user state."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


class PackagedPreparation(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name).resolve()
        self.source = self.root / 'package with spaces'
        self.source.mkdir()
        for directory in ('lib', 'scripts', 'data'):
            (self.source / directory).mkdir()
        (self.source / 'lich.rbw').write_text('# packaged entry\n')
        (self.source / 'scripts/example.lic').write_text('initial script')
        (self.source / 'data/example.xml').write_text('initial data')
        self.data_root = self.root / 'data with spaces'
        self.home = self.data_root / 'runtime'
        self.env = dict(os.environ, LICHNIX_DATA_HOME=str(self.data_root))
        self.helper = os.environ.get('PACKAGED_STATE', str(
            Path(__file__).resolve().parents[1] / 'nix/packaged-state.rb'))

    def initialize(self, source=None):
        return subprocess.run(['ruby', self.helper, str(source or self.source)],
                              env=self.env, text=True, capture_output=True)

    def test_first_launch_seeds_writable_copies_and_repeats(self):
        for _ in range(2):
            result = self.initialize()
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.home / 'scripts/example.lic').read_text(), 'initial script')
        self.assertFalse((self.home / 'scripts/example.lic').is_symlink())
        self.assertTrue(os.access(self.home / 'scripts/example.lic', os.W_OK))
        self.assertEqual((self.home / 'lich.rbw').resolve(), self.source / 'lich.rbw')
        self.assertEqual((self.home / 'lib').resolve(), self.source / 'lib')
        self.assertTrue((self.home / 'scripts/custom').is_dir())

    def test_upgrade_preserves_user_files_and_switches_core(self):
        self.assertEqual(self.initialize().returncode, 0)
        script = self.home / 'scripts/example.lic'
        script.write_text('user edit')
        db = self.home / 'data/lich.db3'
        db.write_bytes(b'user database')
        newer = self.root / 'new package'
        newer.mkdir()
        (newer / 'scripts').mkdir()
        (newer / 'scripts/example.lic').write_text('new upstream script')
        (newer / 'scripts/added.lic').write_text('new seed')
        (newer / 'lich.rbw').write_text('# new core')
        (newer / 'lib').mkdir()
        result = self.initialize(newer)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(script.read_text(), 'user edit')
        self.assertEqual(db.read_bytes(), b'user database')
        self.assertEqual((self.home / 'scripts/added.lic').read_text(), 'new seed')
        self.assertEqual((self.home / 'lich.rbw').resolve(), newer / 'lich.rbw')
        self.assertEqual(self.initialize().returncode, 0)  # rollback core only
        self.assertEqual(script.read_text(), 'user edit')

    def test_existing_legacy_checkout_is_untouched(self):
        old = self.data_root / 'packaged/lich-5'
        old.mkdir(parents=True)
        (old / 'lich.rbw').write_text('old source')
        (old / 'data').mkdir()
        (old / 'data/entry.dat').write_text('saved login')
        self.assertEqual(self.initialize().returncode, 0)
        self.assertEqual((old / 'lich.rbw').read_text(), 'old source')
        self.assertEqual((old / 'data/entry.dat').read_text(), 'saved login')

    def test_unmanaged_entry_is_preserved(self):
        self.home.mkdir(parents=True)
        entry = self.home / 'lich.rbw'
        entry.write_text('user code')
        result = self.initialize()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('refusing to replace unmanaged', result.stderr)
        self.assertEqual(entry.read_text(), 'user code')

    def test_seeding_does_not_follow_user_symlinks(self):
        self.home.mkdir(parents=True)
        elsewhere = self.root / 'elsewhere'
        elsewhere.mkdir()
        (self.home / 'data').symlink_to(elsewhere)
        result = self.initialize()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(list(elsewhere.iterdir()), [])


if __name__ == '__main__':
    unittest.main()
