#!/usr/bin/env python3
"""PR 的「改动类型」勾选与改动内容是否自洽。

`check_version_bump.py` 只看公开 API 表面，纯行为变化（默认值、交互、修 bug）
在 API 不变时它看不到。这类改动是否抬版本 / 写 CHANGELOG 只能由 PR 自己声明——
PR 模板里勾了公开类别（公开变化 / 删除废弃 / 新增包）时，这里要求 PR 至少改一个
**被改包**的 CHANGELOG：

- 子包：`packages/<pkg>/CHANGELOG.md`，且 `<pkg>` 必须是本次改了公开代码的包
  （`lib/` / `bin/` / CLI 的 `templates/` / `catalog/` / `schema/`）；
- 根包：改根 `lib/` / `pubspec.yaml` 时用根 `CHANGELOG.md`。

另外，改了公开代码的 PR 必须带「## 改动类型」段，并且至少勾选一项：
`gh pr create --fill` 的空 body、或模板段但四类全空，都会让门禁静默跳过
（二轮审计 P2-2、三轮审计 P1-1）。

用法：
    PR_BODY="$(gh pr view --json body -q .body)" PR_CONTEXT=1 \
        python3 scripts/check_pr_scope.py --base origin/main

CI 里由 `.github/workflows/ci.yml` 的 `api-bump` job 传入 PR body、PR_CONTEXT 与 base sha。

退出码：
    0  通过，或没有 PR 上下文（本地 preflight 不判），或 PR 未改 lib 且 body 为空
    1  空 body / 全未勾选 / 勾了公开类别但没有改相关 CHANGELOG
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
# 勾选这三类都意味着「有公开影响」：删除 / 废弃、新增包同样必须写 CHANGELOG。
PUBLIC_CHANGE_MARKS = ('公开变化', '删除 / 废弃', '新增包')
SECTION_HEADING = re.compile(r'(?m)^##\s+改动类型(?:\s*$|\s*[（(].*$)')
CHECKED_BOX = re.compile(r'^\s*[-*]\s*\[[xX]\]\s*(.*)$', re.MULTILINE)
PACKAGE_CHANGELOG = re.compile(r'^packages/[^/]+/CHANGELOG\.md$')
PACKAGE_LIB = re.compile(r'^packages/([^/]+)/lib/')
# 公开行为不只在 lib/：CLI 的 bin/、templates/、catalog/、schema/ 同样会改变消费方看到的内容。
PACKAGE_PUBLIC = re.compile(r'^packages/([^/]+)/(?:lib|bin|templates|catalog|schema)/')
PUBLIC_PATH = re.compile(
    r'^(?:packages/[^/]+/(?:lib|bin)/|packages/cli/(?:templates|catalog|schema)/|lib/)'
)
ROOT_CHANGELOG = 'CHANGELOG.md'


def type_section(pr_body: str) -> str:
    """只取「## 改动类型」到下一个二级标题之间的内容。

    模板后面还有「命名」「教学同步」「版本 / 发布物料」「自检」等勾选；不能把那些
    `[x]` 当成改动类型，也不能跨段匹配「公开变化」。
    """
    match = SECTION_HEADING.search(pr_body)
    if not match:
        return ''
    rest = pr_body[match.end():]
    following = re.search(r'(?m)^##\s+', rest)
    return rest[:following.start()] if following else rest


def checked_categories(pr_body: str) -> list[str]:
    """「## 改动类型」段里被勾选的条目（只取 [x] 行）。"""
    return [
        line.strip()
        for line in CHECKED_BOX.findall(type_section(pr_body))
        if line.strip()
    ]


def has_checked_box(pr_body: str) -> bool:
    """「## 改动类型」段是否存在一个有效勾选。

    模板默认四类全空；`gh pr create --fill` 也可能留下空段。全空不能当成
    「内部重构」，否则行为变化会静默跳过 CHANGELOG（三轮审计 P1-1）。
    """
    return bool(checked_categories(pr_body))


def in_pr_context() -> bool:
    """CI 的 PR 事件。本地 preflight 没有 PR body，不应误判。"""
    return (
        os.environ.get('PR_CONTEXT') == '1'
        or os.environ.get('GITHUB_EVENT_NAME') == 'pull_request'
    )


def declared_public_change(pr_body: str) -> bool:
    """PR 模板的「## 改动类型」段里是否勾选了任一公开类别。"""
    for line in checked_categories(pr_body):
        if any(mark in line for mark in PUBLIC_CHANGE_MARKS):
            return True
    return False


def has_template_section(pr_body: str) -> bool:
    return bool(SECTION_HEADING.search(pr_body))


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


def public_packages(changed: list[str]) -> set[str]:
    """本次改了公开代码（lib / bin / templates / catalog / schema）的包集合。"""
    packages = set()
    for path in changed:
        match = PACKAGE_PUBLIC.match(path)
        if match:
            packages.add(match.group(1))
    return packages


def missing_package_changelogs(changed: list[str]) -> list[str]:
    """改了公开代码却没有改对应包 CHANGELOG 的包（升序）。"""
    return sorted(
        package
        for package in public_packages(changed)
        if f'packages/{package}/CHANGELOG.md' not in changed
    )


def touches_changelog(changed: list[str]) -> bool:
    """勾了公开类别时，是否改到了相关 CHANGELOG。

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
        if not in_pr_context():
            print('没有 PR body 上下文（本地 / 非 PR 事件），跳过改动类型检查')
            return 0
        if not args.base:
            print('--base 是必需的（PR 上下文即使 body 为空也要检查改动范围）', file=sys.stderr)
            return 2
        changed = changed_files(args.base)
        if touches_public_code(changed):
            print(
                '✗ PR body 为空：这个 PR 改了公开代码，但没有声明改动类型。\n'
                '  空 body 会让 check_pr_scope 静默跳过（三轮审计 P1-1）。\n'
                '  用仓库的 PR 模板，或 `gh pr edit --body` 补上「## 改动类型」并勾选一项。',
                file=sys.stderr,
            )
            return 1
        print('PR body 为空（本次改动不涉及 lib/），跳过改动类型检查')
        return 0
    if not args.base:
        print('--base 是必需的（CI 传 PR base sha）', file=sys.stderr)
        return 2

    changed = changed_files(args.base)

    if not has_template_section(pr_body):
        if touches_public_code(changed):
            print(
                '✗ PR body 里没有「## 改动类型」段：这个 PR 改了公开代码，'
                '但没有按模板声明改动类型，CHANGELOG 门禁会整条失效。\n'
                '  用仓库的 PR 模板，或 `gh pr edit --body` 补上四类勾选。',
                file=sys.stderr,
            )
            return 1
        print('PR body 没有改动类型段（本次改动不涉及 lib/），跳过')
        return 0

    if touches_public_code(changed) and not has_checked_box(pr_body):
        print(
            '✗ PR body 有「## 改动类型」段，但四类勾选一个都没有：\n'
            '  模板默认全空；不勾选不能当成「内部重构」（三轮审计 P1-1）。\n'
            '  至少勾选「内部重构」或一个公开类别（公开变化 / 删除废弃 / 新增包）。',
            file=sys.stderr,
        )
        return 1

    if not declared_public_change(pr_body):
        print('PR 未勾选公开类别（公开变化 / 删除废弃 / 新增包），跳过 CHANGELOG 检查')
        return 0

    missing = missing_package_changelogs(changed)
    if missing:
        print(
            '✗ 勾选了公开类别，但以下包改了公开代码却没改对应 CHANGELOG：'
            f'{", ".join(missing)}。\n'
            '  子包：写 packages/<pkg>/CHANGELOG.md 的当前版本段；\n'
            '  根包：改 lib/ 或 pubspec.yaml 时写根 CHANGELOG.md。',
            file=sys.stderr,
        )
        return 1
    if public_packages(changed):
        print('✓ 勾选了公开类别，且每个被改的包都改了 CHANGELOG')
        return 0
    if touches_changelog(changed):
        print('✓ 勾选了公开类别，且改动了相关 CHANGELOG')
        return 0

    print(
        '✗ PR 勾选了公开类别（公开变化 / 删除废弃 / 新增包），但没有改动相关 CHANGELOG。\n'
        '  子包：写 packages/<pkg>/CHANGELOG.md 的当前版本段；\n'
        '  根包：改 lib/ 或 pubspec.yaml 时写根 CHANGELOG.md。\n'
        '  行为变化没有公开 API diff，不会被 check_version_bump / api diff 拦住；\n'
        '  请抬版本并写当前版本 CHANGELOG 段，或把勾选改成「内部重构」。',
        file=sys.stderr,
    )
    return 1


if __name__ == '__main__':
    raise SystemExit(main())
