from __future__ import annotations

import contextlib
import io
import os
import pathlib
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

import check_pr_scope as mod
from check_pr_scope import (
    changelog_policy_error_for,
    declared_public_change,
    has_checked_box,
    has_template_section,
    lib_packages,
    missing_package_changelogs,
    missing_root_changelog,
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
        self.assertTrue(
            touches_changelog(['packages/ui/lib/a.dart', 'packages/ui/CHANGELOG.md'])
        )

    def test_root_changelog_with_subpackage_code_is_not_enough(self):
        # 根包 CHANGELOG 不代表子包抬了版本；行为变化必须落到具体子包。
        self.assertFalse(touches_changelog(['CHANGELOG.md', 'packages/ui/lib/a.dart']))

    def test_root_changelog_with_root_lib_is_enough(self):
        self.assertTrue(touches_changelog(['CHANGELOG.md', 'lib/w_tools.dart']))

    def test_root_changelog_with_root_pubspec_is_enough(self):
        self.assertTrue(touches_changelog(['CHANGELOG.md', 'pubspec.yaml']))

    def test_root_changelog_alone_is_not_enough(self):
        self.assertFalse(touches_changelog(['CHANGELOG.md']))
    def test_root_lib_with_unrelated_package_changelog_is_not_enough(self):
        # 根包改动只能由根 CHANGELOG 证明；任意子包 CHANGELOG 不能算。
        self.assertFalse(
            touches_changelog(['lib/w_tools.dart', 'packages/toast/CHANGELOG.md'])
        )

    def test_package_change_with_other_package_changelog_is_not_enough(self):
        # 改 ui 却只改 toast 的 CHANGELOG，不能算 ui 的记录。
        self.assertFalse(
            touches_changelog(['packages/ui/lib/a.dart', 'packages/toast/CHANGELOG.md'])
        )


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

    def _main(
        self,
        body: str,
        changed: list[str],
        *,
        pr_context: bool = True,
        snapshot=None,
        version: str = '2.0.0',
        changelog: str | None = None,
        online: bool = False,
        published: str | None = '2.0.0',
    ) -> int:
        env = {'PR_BODY': body}
        if pr_context:
            env['PR_CONTEXT'] = '1'
        argv = ['check_pr_scope.py', '--base', 'HEAD']
        if online:
            argv.append('--online')
        patches = [
            mock.patch.object(mod, 'changed_files', return_value=changed),
            mock.patch.object(mod, 'latest_snapshot_version', return_value=snapshot),
            mock.patch.object(mod, 'package_version', return_value=version),
            mock.patch.dict(os.environ, env, clear=True),
            mock.patch.object(sys, 'argv', argv),
            contextlib.redirect_stdout(io.StringIO()),
            contextlib.redirect_stderr(io.StringIO()),
        ]
        if online:
            patches.append(mock.patch.object(mod, 'published_baseline', return_value=published))
        with contextlib.ExitStack() as stack:
            if changelog is not None:
                temp = stack.enter_context(tempfile.TemporaryDirectory())
                root = pathlib.Path(temp)
                (root / 'packages' / 'toast').mkdir(parents=True)
                (root / 'packages' / 'toast' / 'CHANGELOG.md').write_text(changelog)
                stack.enter_context(mock.patch.object(mod, 'ROOT', root))
            for patch in patches:
                stack.enter_context(patch)
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
    def test_root_public_change_with_unrelated_changelog_fails(self):
        body = '## 改动类型\n\n- [x] 公开变化（API / 行为 / 新组件）\n'
        changed = ['lib/w_tools.dart', 'packages/toast/CHANGELOG.md']
        self.assertEqual(self._main(body, changed), 1)
    def test_mixed_root_and_package_change_still_requires_root_changelog(self):
        body = '## 改动类型\n\n- [x] 公开变化（API / 行为 / 新组件）\n'
        changed = [
            'lib/w_tools.dart',
            'packages/toast/lib/src/toast.dart',
            'packages/toast/CHANGELOG.md',
        ]
        self.assertEqual(self._main(body, changed), 1)

    def test_published_version_only_old_changelog_section_fails(self):
        # 本地版本 / 最新快照都是 2.0.0，CHANGELOG 里没有 Unreleased；
        # 把行为变化追加到已发布的 2.0.0 段不能算“当前版本段”。
        body = '## 改动类型\n\n- [x] 公开变化（API / 行为 / 新组件）\n'
        changed = ['packages/toast/lib/src/toast.dart', 'packages/toast/CHANGELOG.md']
        self.assertEqual(
            self._main(
                body,
                changed,
                snapshot='2.0.0',
                version='2.0.0',
                changelog='## 2.0.0\n\n- old\n',
            ),
            1,
        )

    def test_unpublished_version_with_old_changelog_section_passes(self):
        body = '## 改动类型\n\n- [x] 公开变化（API / 行为 / 新组件）\n'
        changed = ['packages/toast/lib/src/toast.dart', 'packages/toast/CHANGELOG.md']
        self.assertEqual(
            self._main(
                body,
                changed,
                snapshot='1.9.0',
                version='2.0.0',
                changelog='## 2.0.0\n\n- old\n',
            ),
            0,
        )

    def test_bumped_version_with_old_changelog_section_passes(self):
        # 这项用例不依赖 toast 的真实 pubspec 版本：固定 2.0.1 / 快照 2.0.0，
        # 否则下次 toast 抬版本时，整个 CHANGELOG 策略测试会在无关 PR 上变红。
        body = '## 改动类型\n\n- [x] 公开变化（API / 行为 / 新组件）\n'
        changed = ['packages/toast/lib/src/toast.dart', 'packages/toast/CHANGELOG.md']
        self.assertEqual(
            self._main(
                body,
                changed,
                snapshot='2.0.0',
                version='2.0.1',
                changelog='## 2.0.0\n\n- old\n',
            ),
            0,
        )

    def test_online_baseline_does_not_trust_stale_snapshot(self):
        # 发布成功后、快照 PR 合入前：快照仍 1.9.0，但 pub.dev 已经是 2.0.0。
        # 此时往已发布的 2.0.0 段追加行为变化必须失败，不能把快照当已发布基线。
        body = '## 改动类型\n\n- [x] 公开变化（API / 行为 / 新组件）\n'
        changed = ['packages/toast/lib/src/toast.dart', 'packages/toast/CHANGELOG.md']
        self.assertEqual(
            self._main(
                body,
                changed,
                snapshot='1.9.0',
                version='2.0.0',
                changelog='## 2.0.0\n\n- old\n',
                online=True,
                published='2.0.0',
            ),
            1,
        )

    def test_online_baseline_falls_back_when_pubdev_missing(self):
        # published_version 取不到时回退快照；这里用 None 模拟“回退后仍无基线”，
        # 策略应跳过而不是崩溃。
        body = '## 改动类型\n\n- [x] 公开变化（API / 行为 / 新组件）\n'
        changed = ['packages/toast/lib/src/toast.dart', 'packages/toast/CHANGELOG.md']
        self.assertEqual(
            self._main(
                body,
                changed,
                snapshot='1.9.0',
                version='2.0.0',
                changelog='## 2.0.0\n\n- old\n',
                online=True,
                published=None,
            ),
            0,
        )

    def test_deletion_requires_changelog(self):
        body = '## 改动类型\n\n- [x] 删除 / 废弃\n'
        self.assertEqual(self._main(body, ['packages/ui/lib/a.dart']), 1)

    def test_docs_only_with_public_category_passes(self):
        # 只改 README 却勾了「公开变化」：没有公开代码变化，不该要求 CHANGELOG。
        body = '## 改动类型\n\n- [x] 公开变化（API / 行为 / 新组件）\n'
        self.assertEqual(self._main(body, ['packages/ui/README.md']), 0)

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


class ChangelogPolicyTest(unittest.TestCase):
    def test_published_version_without_unreleased_fails(self):
        self.assertIsNotNone(
            changelog_policy_error_for(
                'toast',
                '2.0.0',
                '2.0.0',
                '## 2.0.0\n\n### Fixed\n- old note\n',
            )
        )

    def test_newer_version_passes(self):
        self.assertIsNone(
            changelog_policy_error_for(
                'toast',
                '2.0.1',
                '2.0.0',
                '## 2.0.1\n\n### Fixed\n- new note\n',
            )
        )

    def test_unreleased_entry_passes(self):
        self.assertIsNone(
            changelog_policy_error_for(
                'toast',
                '2.0.0',
                '2.0.0',
                '## Unreleased\n\n- fix\n\n## 2.0.0\n',
            )
        )

    def test_empty_unreleased_does_not_count(self):
        self.assertIsNotNone(
            changelog_policy_error_for(
                'toast',
                '2.0.0',
                '2.0.0',
                '## Unreleased\n\n## 2.0.0\n',
            )
        )

    def test_missing_snapshot_skips(self):
        self.assertIsNone(
            changelog_policy_error_for('toast', '2.0.0', None, '## 2.0.0\n')
        )

    def test_missing_root_changelog(self):
        self.assertTrue(missing_root_changelog(['lib/w_tools.dart']))
        self.assertFalse(missing_root_changelog(['lib/w_tools.dart', 'CHANGELOG.md']))


if __name__ == '__main__':
    unittest.main()
