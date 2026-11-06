import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class ReleaseCheckPushTest(unittest.TestCase):
    def test_strict_checks_upstream_sync(self):
        sync = (ROOT / 'scripts/check_git_sync.sh').read_text()
        self.assertIn('@{u}', sync)
        self.assertIn('rev-list --count', sync)
        release = (ROOT / 'scripts/release_check.sh').read_text()
        self.assertIn('check_git_sync.sh', release)


if __name__ == '__main__':
    unittest.main()
