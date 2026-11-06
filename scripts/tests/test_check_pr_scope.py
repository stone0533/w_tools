import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from check_pr_scope import declared_public_change, touches_package_changelog


class PrScopeTest(unittest.TestCase):
    def test_checked_public_change_is_detected(self):
        body = '- [x] 公开变化（API / 行为 / 新组件）\n- [ ] 内部重构\n'
        self.assertTrue(declared_public_change(body))

    def test_unchecked_public_change_is_not_detected(self):
        body = '- [ ] 公开变化（API / 行为 / 新组件）\n- [x] 内部重构\n'
        self.assertFalse(declared_public_change(body))

    def test_checked_other_category_is_not_public_change(self):
        self.assertFalse(declared_public_change('- [x] 删除 / 废弃\n'))

    def test_missing_template_skips(self):
        self.assertFalse(declared_public_change(''))

    def test_package_changelog_detected(self):
        self.assertTrue(touches_package_changelog(['packages/ui/CHANGELOG.md', 'README.md']))

    def test_root_changelog_only_is_not_enough(self):
        # 根包 CHANGELOG 不代表子包抬了版本；行为变化必须落到具体子包。
        self.assertFalse(touches_package_changelog(['CHANGELOG.md', 'packages/ui/lib/a.dart']))

    def test_unrelated_files(self):
        self.assertFalse(touches_package_changelog(['docs/releasing.md']))


if __name__ == '__main__':
    unittest.main()
