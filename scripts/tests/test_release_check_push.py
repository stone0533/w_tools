import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class ReleaseCheckPushTest(unittest.TestCase):
    def test_strict_checks_upstream_sync(self):
        text = (ROOT / 'scripts/release_check.sh').read_text()
        self.assertIn('@{u}', text)
        self.assertIn('rev-list --count', text)


if __name__ == '__main__':
    unittest.main()
