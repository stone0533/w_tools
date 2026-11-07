import pathlib
import sys
import unittest
from unittest import mock

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

import _release_baseline as mod


class BaselineTest(unittest.TestCase):
    def test_check_equal_warns(self):
        code, message = mod.baseline('ui', '7.0.0', mode='check')
        self.assertEqual(code, mod.WARN_EQUAL)
        self.assertIn('等于', message)

    def test_check_snapshot_ahead_fails(self):
        code, message = mod.baseline('ui', '6.0.0', mode='check')
        self.assertEqual(code, 1)
        self.assertIn('高于本地版本', message)

    def test_check_local_ahead_passes(self):
        code, message = mod.baseline('ui', '9.0.0', mode='check')
        self.assertEqual(code, 0)
        self.assertIn('低于本地', message)

    def test_publish_local_ahead_passes(self):
        code, message = mod.baseline('cli', '1.15.0', mode='publish')
        self.assertEqual(code, 0)
        self.assertIn('待发布', message)

    def test_publish_equal_without_pending_fails(self):
        code, message = mod.baseline('ui', '7.0.0', mode='publish')
        self.assertEqual(code, 1)
        self.assertIn('已经是快照基线', message)

    def test_publish_missing_snapshot_with_pending_passes(self):
        with (
            mock.patch.object(mod, 'snapshot_version', return_value=None),
            mock.patch.object(mod, 'pending_first_release', return_value={'demo'}),
        ):
            code, message = mod.baseline('demo', '1.0.0', mode='publish')
        self.assertEqual(code, 0)
        self.assertIn('新包首发', message)

    def test_publish_missing_snapshot_without_pending_fails(self):
        with (
            mock.patch.object(mod, 'snapshot_version', return_value=None),
            mock.patch.object(mod, 'pending_first_release', return_value=set()),
        ):
            code, message = mod.baseline('demo', '1.0.0', mode='publish')
        self.assertEqual(code, 1)
        self.assertIn('没有 API 快照', message)

    def test_publish_equal_snapshot_with_pending_passes(self):
        with (
            mock.patch.object(mod, 'snapshot_version', return_value='1.0.0'),
            mock.patch.object(mod, 'pending_first_release', return_value={'demo'}),
            mock.patch.object(mod, 'snapshot_path', return_value=pathlib.Path('x.txt')),
            mock.patch.object(mod, 'git_tracked', return_value=True),
        ):
            code, message = mod.baseline('demo', '1.0.0', mode='publish')
        self.assertEqual(code, 0)
        self.assertIn('新包首发', message)

    def test_publish_untracked_snapshot_fails(self):
        with (
            mock.patch.object(mod, 'snapshot_version', return_value='1.0.0'),
            mock.patch.object(mod, 'snapshot_path', return_value=pathlib.Path('x.txt')),
            mock.patch.object(mod, 'git_tracked', return_value=False),
        ):
            code, message = mod.baseline('demo', '1.1.0', mode='publish')
        self.assertEqual(code, 1)
        self.assertIn('未提交', message)


if __name__ == '__main__':
    unittest.main()
