import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class PublishSnapshotTest(unittest.TestCase):
    def test_publish_script_updates_api_snapshot(self):
        text = (ROOT / 'scripts/publish_package.sh').read_text()
        self.assertIn('check_public_api_diff.py', text)
        self.assertIn('--snapshot-from', text)
        self.assertIn('--version', text)


if __name__ == '__main__':
    unittest.main()
