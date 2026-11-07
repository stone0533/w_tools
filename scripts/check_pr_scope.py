#!/usr/bin/env python3
"""PR 的「改动类型」勾选与改动内容是否自洽。

`check_version_bump.py` 只看公开 API 表面，纯行为变化（默认值、交互、修 bug）
在 API 不变时它看不到。这类改动是否抬版本 / 写 CHANGELOG 只能由 PR 自己声明——
PR 模板里勾了「公开变化」时，这里要求 PR 至少改一个**被改包**的 CHANGELOG：

- 子包：`packages/<pkg>/CHANGELOG.md`，且 `<pkg>` 必须是本次改了 `lib/` 的包；
- 根包：改根 `lib/` / `pubspec.yaml` 时用根 `CHANGELOG.md`。

另外，改了 `lib/` 的 PR 必须带「## 改动类型」段：`gh pr create --fill` 这类不带模板的
PR body 会让整条门禁静默跳过（二轮审计 P2-2）。

用法：
    PR_BODY="$(gh pr view --json body -q .body)" \
        python3 scripts/check_pr_scope.py --base origin/main

CI 里由 `.github/workflows/ci.yml` 的 `api-bump` job 传入 PR body 与 base sha。

退出码：
    0  通过，或没有 PR 上下文（本地 preflight 不判）
    1  勾了「公开变化」但没有改相关 CHANGELOG / 改了 lib 但 body 没有改动类型段
    2  参数 / git 错误
"""
from __future__ import annotations

import argparse
import os
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PUBLIC_CHANGE_MARK = '公开变化'
TEMPLATE_SECTION = '## 改动类型'
CHECKED_BOX = re.compile(r'^\s*[-*]\s*\[[xX]\]\s*(.*)$', re.MULTILINE)
PACKAGE_CHANGELOG = re.compile(r'^packages/[^/]+/CHANGELOG\.md$')
PACKAGE_LIB = re.compile(r'^packages/([^/]+)/lib/')
PUBLIC_PATH = re.compile(r'^(?:packages/[^/]+/lib/|lib/)')
ROOT_CHANGELOG = 'CHANGELOG.md'


def declared_public_change(pr_body: str) -> bool:
    """PR 模板里「公开变化（API / 行为 / 新组件）」是否被勾选。"""
    for line in CHECKED_BOX.findall(pr_body):
        if PUBLIC_CHANGE_MARK in line:
            return True
    return False


def has_template_section(pr_body: str) -> bool:
    return TEMPLATE_SECTION in pr_body


def touches_public_code(changed: list[str]) -> bool:
    return any(PUBLIC_PATH.match(path) for path in changed)


def lib_packages(changed: list[str]) -> set[str]:
    """本次改了 `packages/<pkg>/lib/` 的包集合。"""
    packages = set()
    for path in changed:
        match = PACKAGE_LIB.match(path)
        if match:
            packages.add(match.group(1))
    return packages


def missing_package_changelogs(changed: list[str]) -> list[str]:
    """改了 lib 却没有改对应包 CHANGELOG 的包（升序）。"""
    return sorted(
        package
        for package in lib_packages(changed)
        if f'packages/{package}/CHANGELOG.md' not in changed
    )


def touches_changelog(changed: list[str]) -> bool:
    """勾了「公开变化」时，是否改到了相关 CHANGELOG。

    - 子包：任意 `packages/<pkg>/CHANGELOG.md` 被改即算；
    - 根包：只有同时改了根 `lib/` 或根 `pubspec.yaml` 时，根 `CHANGELOG.md` 才算，
      避免「改子包代码 + 顺手改根 CHANGELOG」绕过子包 CHANGELOG 要求。
    """
    if any(PACKAGE_CHANGELOG.match(path) for path in changed):
        return True
    if ROOT_CHANGELOG not in changed:
        return False
    return any(path == 'pubspec.yaml' or path.startswith('lib/') for path in changed)


def changed_files(base: str) -> list[str]:
    merge_base = subprocess.run(
        ['git', 'merge-base', base, 'HEAD'],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if merge_base.returncode != 0:
        raise SystemExit(f'无法计算 merge-base（{base}）：{merge_base.stderr.strip()}')
    diff = subprocess.run(
        ['git', 'diff', '--name-only', merge_base.stdout.strip(), 'HEAD'],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if diff.returncode != 0:
        raise SystemExit(f'git diff 失败：{diff.stderr.strip()}')
    return [line for line in diff.stdout.splitlines() if line]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--base', help='PR 的 base sha / 分支（CI 传 base.sha）')
    args = parser.parse_args()

    pr_body = os.environ.get('PR_BODY', '')
    if not pr_body.strip():
        print('没有 PR body 上下文（本地 / 非 PR 事件），跳过改动类型检查')
        return 0
    if not args.base:
        print('--base 是必需的（CI 传 PR base sha）', file=sys.stderr)
        return 2

    changed = changed_files(args.base)

    if not has_template_section(pr_body):
        if touches_public_code(changed):
            print(
                '✗ PR body 里没有「## 改动类型」段：这个 PR 改了 lib/，'
                '但没有按模板声明改动类型，CHANGELOG 门禁会整条失效。\n'
                '  用仓库的 PR 模板，或 `gh pr edit --body` 补上四类勾选。',
                file=sys.stderr,
            )
            return 1
        print('PR body 没有改动类型段（本次改动不涉及 lib/），跳过')
        return 0

    if not declared_public_change(pr_body):
        print('PR 未勾选「公开变化」，跳过 CHANGELOG 检查')
        return 0

    missing = missing_package_changelogs(changed)
    if missing:
        print(
            '✗ 勾选了「公开变化」，但以下包改了 lib/ 却没改对应 CHANGELOG：'
            f'{", ".join(missing)}。\n'
            '  子包：写 packages/<pkg>/CHANGELOG.md 的当前版本段；\n'
            '  根包：改 lib/ 或 pubspec.yaml 时写根 CHANGELOG.md。',
            file=sys.stderr,
        )
        return 1
    if lib_packages(changed):
        print('✓ 勾选了「公开变化」，且每个被改的包都改了 CHANGELOG')
        return 0
    if touches_changelog(changed):
        print('✓ 勾选了「公开变化」，且改动了相关 CHANGELOG')
        return 0

    print(
        '✗ PR 勾选了「公开变化（API / 行为 / 新组件）」，但没有改动相关 CHANGELOG。\n'
        '  子包：写 packages/<pkg>/CHANGELOG.md 的当前版本段；\n'
        '  根包：改 lib/ 或 pubspec.yaml 时写根 CHANGELOG.md。\n'
        '  行为变化没有公开 API diff，不会被 check_version_bump / api diff 拦住；\n'
        '  请抬版本并写当前版本 CHANGELOG 段，或把勾选改成「内部重构」。',
        file=sys.stderr,
    )
    return 1


if __name__ == '__main__':
    raise SystemExit(main())
