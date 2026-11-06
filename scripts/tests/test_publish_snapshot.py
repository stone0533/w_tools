import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class PublishSnapshotTest(unittest.TestCase):
    def test_publish_script_updates_api_snapshot(self):
        text = (ROOT / 'scripts/publish_package.sh').read_text()
        self.assertIn('check_public_api_diff.py', text)
        self.assertIn('--snapshot-from', text)
        self.assertIn('--version', text)
        self.assertIn('exit 1', text)
        self.assertIn('stage_only=1', text)
        self.assertIn('release-snapshots', text)
        self.assertIn('apply_snapshots.sh', text)
        self.assertIn('--output-dir', text)
        self.assertIn('compgen -G', text)

    def test_publish_script_fails_closed_before_publishing(self):
        text = (ROOT / 'scripts/publish_package.sh').read_text()
        # 正式发布前必须自己守住「干净 main + release_check --strict」，不能只靠操作者记得跑。
        self.assertIn('release_check.sh', text)
        self.assertIn('--strict', text)
        self.assertIn('origin/main', text)
        self.assertIn('git -C "$repo_root" fetch', text)
        self.assertIn('--force', text)


if __name__ == '__main__':
    unittest.main()
