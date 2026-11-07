import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from check_pr_scope import (
    declared_public_change,
    has_template_section,
    lib_packages,
    missing_package_changelogs,
    touches_changelog,
    touches_public_code,
)


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
        self.assertTrue(touches_changelog(['packages/ui/CHANGELOG.md', 'README.md']))

    def test_root_changelog_with_subpackage_code_is_not_enough(self):
        # 根包 CHANGELOG 不代表子包抬了版本；行为变化必须落到具体子包。
        self.assertFalse(touches_changelog(['CHANGELOG.md', 'packages/ui/lib/a.dart']))

    def test_root_changelog_with_root_lib_is_enough(self):
        self.assertTrue(touches_changelog(['CHANGELOG.md', 'lib/w_tools.dart']))

    def test_root_changelog_with_root_pubspec_is_enough(self):
        self.assertTrue(touches_changelog(['CHANGELOG.md', 'pubspec.yaml']))

    def test_root_changelog_alone_is_not_enough(self):
        self.assertFalse(touches_changelog(['CHANGELOG.md']))

    def test_unrelated_files(self):
        self.assertFalse(touches_changelog(['docs/releasing.md']))


class PathDerivationTest(unittest.TestCase):
    """CHANGELOG 必须属于被改的包；改了 lib/ 就必须带模板段。"""

    def test_lib_packages(self):
        self.assertEqual(
            lib_packages(['packages/ui/lib/a.dart', 'packages/form/lib/b.dart']),
            {'ui', 'form'},
        )

    def test_missing_package_changelog(self):
        changed = ['packages/ui/lib/a.dart', 'packages/form/lib/b.dart',
                   'packages/form/CHANGELOG.md']
        self.assertEqual(missing_package_changelogs(changed), ['ui'])

    def test_other_package_changelog_is_not_enough(self):
        changed = ['packages/ui/lib/a.dart', 'packages/form/CHANGELOG.md']
        self.assertEqual(missing_package_changelogs(changed), ['ui'])

    def test_public_code_paths(self):
        self.assertTrue(touches_public_code(['packages/ui/lib/a.dart']))
        self.assertTrue(touches_public_code(['lib/w_tools.dart']))
        self.assertFalse(touches_public_code(['scripts/check_docs.sh']))
        self.assertFalse(touches_public_code(['packages/ui/README.md']))

    def test_template_section(self):
        self.assertTrue(has_template_section('## 改动类型\n- [ ] 内部重构\n'))
        self.assertFalse(has_template_section('fix(ui): tweak padding'))


if __name__ == '__main__':
    unittest.main()
