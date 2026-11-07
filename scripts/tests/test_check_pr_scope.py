import contextlib
import io
import os
import pathlib
import sys
import unittest
from unittest import mock

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

import check_pr_scope as mod
from check_pr_scope import (
    declared_public_change,
    has_checked_box,
    has_template_section,
    lib_packages,
    missing_package_changelogs,
    touches_changelog,
    touches_public_code,
)


class PrScopeTest(unittest.TestCase):
    def test_checked_public_change_is_detected(self):
        body = '## 改动类型\n\n- [x] 公开变化（API / 行为 / 新组件）\n- [ ] 内部重构\n'
        self.assertTrue(declared_public_change(body))

    def test_unchecked_public_change_is_not_detected(self):
        body = '## 改动类型\n\n- [ ] 公开变化（API / 行为 / 新组件）\n- [x] 内部重构\n'
        self.assertFalse(declared_public_change(body))

    def test_checked_deletion_is_public_change(self):
        self.assertTrue(declared_public_change('## 改动类型\n\n- [x] 删除 / 废弃\n'))

    def test_checked_new_package_is_public_change(self):
        self.assertTrue(declared_public_change('## 改动类型\n\n- [x] 新增包\n'))

    def test_all_unchecked_has_no_box(self):
        body = '## 改动类型\n\n- [ ] 内部重构\n- [ ] 公开变化（API / 行为 / 新组件）\n'
        self.assertFalse(has_checked_box(body))

    def test_checked_internal_has_box(self):
        body = '## 改动类型\n\n- [x] 内部重构（公开 API / 默认行为不变）\n'
        self.assertTrue(has_checked_box(body))

    def test_checked_box_outside_section_is_ignored(self):
        body = (
            '## 改动类型\n\n'
            '- [ ] 内部重构（公开 API / 默认行为不变）\n\n'
            '## 命名\n\n'
            '- [x] 新增 Config 已登记 naming_baseline.yaml\n'
        )
        self.assertFalse(has_checked_box(body))
        self.assertFalse(declared_public_change(body))

    def test_missing_template_skips(self):
        self.assertFalse(declared_public_change(''))
        self.assertFalse(has_checked_box(''))

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

    def test_template_change_needs_cli_changelog(self):
        changed = ['packages/cli/templates/agents/zh/core.md']
        self.assertEqual(missing_package_changelogs(changed), ['cli'])

    def test_bin_change_needs_package_changelog(self):
        changed = ['packages/cli/bin/w_tools.dart']
        self.assertEqual(missing_package_changelogs(changed), ['cli'])

    def test_other_package_changelog_is_not_enough(self):
        changed = ['packages/ui/lib/a.dart', 'packages/form/CHANGELOG.md']
        self.assertEqual(missing_package_changelogs(changed), ['ui'])

    def test_public_code_paths(self):
        self.assertTrue(touches_public_code(['packages/ui/lib/a.dart']))
        self.assertTrue(touches_public_code(['lib/w_tools.dart']))
        self.assertTrue(touches_public_code(['packages/cli/bin/w_tools.dart']))
        self.assertTrue(
            touches_public_code(['packages/cli/templates/agents/zh/core.md'])
        )
        self.assertTrue(touches_public_code(['packages/cli/catalog/components.yaml']))
        self.assertFalse(touches_public_code(['scripts/check_docs.sh']))
        self.assertFalse(touches_public_code(['packages/ui/README.md']))

    def test_template_section(self):
        self.assertTrue(has_template_section('## 改动类型\n- [ ] 内部重构\n'))
        self.assertTrue(has_template_section('## 改动类型（必填）\n- [ ] 内部重构\n'))
        self.assertFalse(has_template_section('## 改动类型说明\n- [ ] 内部重构\n'))
        self.assertFalse(has_template_section('fix(ui): tweak padding'))


class MainTest(unittest.TestCase):
    """空 body / 全未勾选不能静默跳过（三轮审计 P1-1）。"""

    def _main(self, body: str, changed: list[str], *, pr_context: bool = True) -> int:
        env = {'PR_BODY': body}
        if pr_context:
            env['PR_CONTEXT'] = '1'
        with (
            mock.patch.object(mod, 'changed_files', return_value=changed),
            mock.patch.dict(os.environ, env, clear=True),
            mock.patch.object(sys, 'argv', ['check_pr_scope.py', '--base', 'HEAD']),
            contextlib.redirect_stdout(io.StringIO()),
            contextlib.redirect_stderr(io.StringIO()),
        ):
            return mod.main()

    def test_empty_body_with_lib_fails_in_pr_context(self):
        self.assertEqual(self._main('', ['packages/ui/lib/a.dart']), 1)

    def test_empty_body_without_lib_skips_in_pr_context(self):
        self.assertEqual(self._main('', ['scripts/check_docs.sh']), 0)

    def test_empty_body_skips_locally(self):
        self.assertEqual(self._main('', ['packages/ui/lib/a.dart'], pr_context=False), 0)

    def test_all_unchecked_with_lib_fails(self):
        body = (
            '## 改动类型\n\n'
            '- [ ] 内部重构（公开 API / 默认行为不变）\n'
            '- [ ] 公开变化（API / 行为 / 新组件）\n'
        )
        self.assertEqual(self._main(body, ['packages/ui/lib/a.dart']), 1)

    def test_checked_internal_with_lib_passes(self):
        body = '## 改动类型\n\n- [x] 内部重构（公开 API / 默认行为不变）\n'
        self.assertEqual(self._main(body, ['packages/ui/lib/a.dart']), 0)

    def test_public_change_without_changelog_fails(self):
        body = '## 改动类型\n\n- [x] 公开变化（API / 行为 / 新组件）\n'
        self.assertEqual(self._main(body, ['packages/ui/lib/a.dart']), 1)

    def test_public_change_with_changelog_passes(self):
        body = '## 改动类型\n\n- [x] 公开变化（API / 行为 / 新组件）\n'
        changed = ['packages/ui/lib/a.dart', 'packages/ui/CHANGELOG.md']
        self.assertEqual(self._main(body, changed), 0)

    def test_deletion_requires_changelog(self):
        body = '## 改动类型\n\n- [x] 删除 / 废弃\n'
        self.assertEqual(self._main(body, ['packages/ui/lib/a.dart']), 1)

    def test_new_package_requires_changelog(self):
        body = '## 改动类型\n\n- [x] 新增包\n'
        self.assertEqual(self._main(body, ['packages/ui/lib/a.dart']), 1)

    def test_empty_body_with_cli_template_fails_in_pr_context(self):
        self.assertEqual(
            self._main('', ['packages/cli/templates/agents/zh/core.md']), 1
        )

    def test_cli_template_public_without_changelog_fails(self):
        body = '## 改动类型\n\n- [x] 公开变化（API / 行为 / 新组件）\n'
        self.assertEqual(
            self._main(body, ['packages/cli/templates/agents/zh/core.md']), 1
        )

    def test_cli_template_public_with_changelog_passes(self):
        body = '## 改动类型\n\n- [x] 公开变化（API / 行为 / 新组件）\n'
        changed = [
            'packages/cli/templates/agents/zh/core.md',
            'packages/cli/CHANGELOG.md',
        ]
        self.assertEqual(self._main(body, changed), 0)

    def test_cli_template_internal_passes(self):
        body = '## 改动类型\n\n- [x] 内部重构（公开 API / 默认行为不变）\n'
        self.assertEqual(
            self._main(body, ['packages/cli/templates/agents/zh/core.md']), 0
        )


if __name__ == '__main__':
    unittest.main()
