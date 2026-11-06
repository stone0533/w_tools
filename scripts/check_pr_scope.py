#!/usr/bin/env python3
"""PR 的「改动类型」勾选与改动内容是否自洽。

`check_version_bump.py` 只看公开 API 表面，纯行为变化（默认值、交互、修 bug）
在 API 不变时它看不到。这类改动是否抬版本 / 写 CHANGELOG 只能由 PR 自己声明——
PR 模板里勾了「公开变化」时，这里要求 PR 至少改一个 `packages/*/CHANGELOG.md`。

用法：
    PR_BODY="$(gh pr view --json body -q .body)" \
        python3 scripts/check_pr_scope.py --base origin/main

CI 里由 `.github/workflows/ci.yml` 的 `api-bump` job 传入 PR body 与 base sha。

退出码：
    0  通过，或没有 PR 上下文（本地 preflight 不判）
    1  勾了「公开变化」但没有任何 `packages/*/CHANGELOG.md` 变更
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
CHECKED_BOX = re.compile(r'^\s*[-*]\s*\[[xX]\]\s*(.*)$', re.MULTILINE)
CHANGELOG = re.compile(r'^packages/[^/]+/CHANGELOG\.md$')


def declared_public_change(pr_body: str) -> bool:
    """PR 模板里「公开变化（API / 行为 / 新组件）」是否被勾选。"""
    for line in CHECKED_BOX.findall(pr_body):
        if PUBLIC_CHANGE_MARK in line:
            return True
    return False


def touches_package_changelog(changed: list[str]) -> bool:
    return any(CHANGELOG.match(path) for path in changed)


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
    if not declared_public_change(pr_body):
        print('PR 未勾选「公开变化」，跳过 CHANGELOG 检查')
        return 0

    changed = changed_files(args.base)
    if touches_package_changelog(changed):
        print('✓ 勾选了「公开变化」，且改动了子包 CHANGELOG')
        return 0

    print(
        '✗ PR 勾选了「公开变化（API / 行为 / 新组件）」，但没有改动任何 '
        '`packages/*/CHANGELOG.md`。\n'
        '  行为变化没有公开 API diff，不会被 check_version_bump / api diff 拦住；\n'
        '  请抬子包版本并写当前版本 CHANGELOG 段，或把勾选改成「内部重构」。',
        file=sys.stderr,
    )
    return 1


if __name__ == '__main__':
    raise SystemExit(main())
