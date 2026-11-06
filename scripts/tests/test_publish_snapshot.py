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

    def test_publish_script_fails_closed_before_publishing(self):
        text = (ROOT / 'scripts/publish_package.sh').read_text()
        # 正式发布前必须自己守住「干净 main + release_check」，不能只靠操作者记得跑。
        self.assertIn('release_check.sh', text)
        self.assertIn('origin/main', text)
        self.assertIn('--force', text)
        # 批量发布：允许上一次发布写出的未提交快照，其它未跟踪文件仍然阻止。
        self.assertIn("'^scripts/api_snapshots/'", text)
        # --strict 要求完全干净，会和批量发布冲突；不能出现在发布保护里。
        self.assertNotIn('release_check.sh" --strict', text)


if __name__ == '__main__':
    unittest.main()
