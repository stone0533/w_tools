import pathlib
import subprocess
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

ROOT = pathlib.Path(__file__).resolve().parents[2]

import check_version_bump as mod
from check_version_bump import (
    _parse_version,
    base_has_package,
    diff_surfaces,
    merge_base,
    published_version,
    release_parts,
    requires_bump,
)


class VersionBumpTest(unittest.TestCase):
    def test_added_symbol_is_a_change(self):
        changes = diff_surfaces({'WThing': 'class'}, {'WThing': 'class', 'WNew': 'class'})
        self.assertIn('WNew', changes)

    def test_removed_symbol_is_a_change(self):
        changes = diff_surfaces({'WThing': 'class'}, {})
        self.assertIn('WThing', changes)

    def test_signature_change_is_a_change(self):
        changes = diff_surfaces(
            {'WThing.run': 'void (int value)'},
            {'WThing.run': 'void (String value)'},
        )
        self.assertIn('WThing.run', changes)

    def test_identical_surfaces_have_no_changes(self):
        surface = {'WThing': 'class', 'WThing.run': 'void (int value)'}
        self.assertEqual(diff_surfaces(surface, dict(surface)), {})

    def test_parse_version(self):
        self.assertEqual(_parse_version('name: w_tools_ui\nversion: 7.0.0\n'), '7.0.0')
        self.assertIsNone(_parse_version('name: w_tools_ui\n'))


class RequiresBumpTest(unittest.TestCase):
    """判据是「版本是否已经领先已发布基线」，不是「本 PR 有没有改版本号」。

    背景：main 上可能已经有一个还没发布的版本（如 cli 1.13.0 / 快照 1.12.0）。
    同一个未发布版本里继续加 API 不需要再抬版本；而改了已发布版本必须抬。
    """

    def test_bumped_in_this_pr(self):
        self.assertFalse(requires_bump('7.1.0', '7.0.0', '7.0.0'))

    def test_unpublished_version_already_ahead(self):
        self.assertFalse(requires_bump('1.13.0', '1.13.0', '1.12.0'))

    def test_same_as_published_requires_bump(self):
        self.assertTrue(requires_bump('7.0.0', '7.0.0', '7.0.0'))

    def test_no_snapshot_requires_bump(self):
        self.assertTrue(requires_bump('7.0.0', '7.0.0', None))

    def test_prerelease_suffix_compares_numerically(self):
        self.assertFalse(requires_bump('1.1.0-dev.1', '1.1.0-dev.1', '1.0.0'))
        self.assertTrue(requires_bump('1.0.0', '1.0.0', '1.0.0'))

    def test_downgrade_requires_bump(self):
        self.assertTrue(requires_bump('1.9.0', '2.0.0', '2.0.0'))

    def test_bumped_to_an_already_published_version_requires_bump(self):
        self.assertTrue(requires_bump('7.0.0', '6.9.0', '7.0.0'))

    def test_bumped_past_published_is_allowed(self):
        self.assertFalse(requires_bump('7.1.0', '6.9.0', '7.0.0'))

    def test_release_parts_ignore_prerelease_suffix(self):
        self.assertEqual(release_parts('1.0.0-dev.1'), (1, 0, 0))
        self.assertEqual(release_parts('1.0.0'), (1, 0, 0))
        self.assertGreater(release_parts('1.0.1'), release_parts('1.0.0'))


class MergeBaseTest(unittest.TestCase):
    def test_merge_base_of_head_is_head(self):
        head = subprocess.check_output(
            ['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True
        ).strip()
        self.assertEqual(merge_base('HEAD'), head)

    def test_unknown_ref_returns_none(self):
        self.assertIsNone(merge_base('refs/heads/does-not-exist'))


class PublishedBaselineTest(unittest.TestCase):
    """已发布基线：离线用快照；--online 用 pub.dev（失败回退快照并提醒）。"""

    def test_base_package_presence_is_not_archive_success(self):
        self.assertTrue(base_has_package('HEAD', 'ui'))
        self.assertFalse(base_has_package('HEAD', 'not_a_real_package'))

    def test_offline_uses_latest_snapshot(self):
        warnings: list[str] = []
        self.assertEqual(published_version('ui', False, warnings), '7.0.0')
        self.assertEqual(warnings, [])

    def test_online_falls_back_to_snapshot_with_warning(self):
        old_urlopen = mod.urllib.request.urlopen

        def offline(*args, **kwargs):
            raise mod.urllib.error.URLError('offline')

        mod.urllib.request.urlopen = offline
        warnings: list[str] = []
        try:
            self.assertEqual(published_version('ui', True, warnings), '7.0.0')
        finally:
            mod.urllib.request.urlopen = old_urlopen
        self.assertEqual(len(warnings), 1)
        self.assertIn('pub.dev', warnings[0])


if __name__ == '__main__':
    unittest.main()
