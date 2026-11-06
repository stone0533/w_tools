import contextlib
import io
import pathlib
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

import release_status as mod
from release_status import changelog_first, classify, version_tuple


class ReleaseStatusTest(unittest.TestCase):
    def test_published(self):
        self.assertEqual(classify('1.2.3', '1.2.3'), '已发布')

    def test_pending(self):
        self.assertEqual(classify('1.3.0', '1.2.3'), '待发布')

    def test_behind(self):
        self.assertEqual(classify('1.2.3', '1.3.0'), '落后')

    def test_unknown_without_online(self):
        self.assertEqual(classify('1.2.3', None), '未核对')

    def test_version_tuple_ignores_prerelease_suffix(self):
        self.assertEqual(version_tuple('7.0.0'), (7, 0, 0))
        self.assertEqual(version_tuple('1.0.0-dev.1'), (1, 0, 0, 1))

    def test_changelog_first_skips_title_and_unreleased(self):
        with tempfile.TemporaryDirectory() as temp:
            path = pathlib.Path(temp) / 'CHANGELOG.md'
            path.write_text('# Changelog\n\n## Unreleased\n\n- wip\n\n## 1.2.3\n\n- done\n')
            self.assertEqual(changelog_first(path), '1.2.3')

    def test_all_unreachable_returns_2_instead_of_failing(self):
        """网络全挂不是发布事故：--check 应返回 2（周检按跳过处理），而不是 1。"""
        old_urlopen = mod.urllib.request.urlopen
        old_sleep = mod.time.sleep
        old_argv = sys.argv

        def offline(*args, **kwargs):
            raise mod.urllib.error.URLError('offline')

        mod.urllib.request.urlopen = offline
        mod.time.sleep = lambda *_: None
        sys.argv = ['release_status.py', '--online', '--check']
        try:
            with contextlib.redirect_stdout(io.StringIO()):
                with contextlib.redirect_stderr(io.StringIO()):
                    self.assertEqual(mod.main(), 2)
        finally:
            mod.urllib.request.urlopen = old_urlopen
            mod.time.sleep = old_sleep
            sys.argv = old_argv

    def test_offline_check_without_online_or_require_returns_2(self):
        """没有可核对的目标时不能打印「状态正常」。"""
        old_argv = sys.argv
        sys.argv = ['release_status.py', '--check']
        try:
            with contextlib.redirect_stdout(io.StringIO()):
                with contextlib.redirect_stderr(io.StringIO()):
                    self.assertEqual(mod.main(), 2)
        finally:
            sys.argv = old_argv

    def test_snapshot_version_picks_the_latest(self):
        with tempfile.TemporaryDirectory() as temp:
            snapshots = pathlib.Path(temp)
            (snapshots / 'w_tools_ui-7.0.0.txt').write_text('# 7.0.0\n')
            (snapshots / 'w_tools_ui-10.0.0.txt').write_text('# 10.0.0\n')
            (snapshots / 'w_tools_ui-9.0.0.txt').write_text('# 9.0.0\n')
            old = mod.SNAPSHOTS
            mod.SNAPSHOTS = snapshots
            try:
                self.assertEqual(mod.snapshot_version('ui'), '10.0.0')
            finally:
                mod.SNAPSHOTS = old

    def test_git_tracked_distinguishes_tracked_file(self):
        self.assertTrue(mod.git_tracked(mod.ROOT / 'scripts/release_status.py'))
        self.assertFalse(mod.git_tracked(mod.ROOT / 'scripts/__not_a_real_file__.txt'))


if __name__ == '__main__':
    unittest.main()
