#!/usr/bin/env python3
"""PR 的「改动类型」勾选与改动内容是否自洽。

`check_version_bump.py` 只看公开 API 表面，纯行为变化（默认值、交互、修 bug）
在 API 不变时它看不到。这类改动是否抬版本 / 写 CHANGELOG 只能由 PR 自己声明——
PR 模板里勾了公开类别（公开变化 / 删除废弃 / 新增包）时，这里要求：

- 子包：每个改了公开代码的包都要改自己的 `packages/<pkg>/CHANGELOG.md`
  （`lib/` / `bin/` / CLI 的 `templates/` / `catalog/` / `schema/`）；
- 根包：改根 `lib/` / `pubspec.yaml` 时用根 `CHANGELOG.md`；
- 版本：本地版本必须高于已发布基线（默认快照；CI 的 `--online` 用 pub.dev）；
  确实还没发版时，`CHANGELOG` 里要有非空 `## Unreleased` 段。
  只改文档 / 脚本的 PR 不要求 CHANGELOG。

另外，改了公开代码的 PR 必须带「## 改动类型」段，并且至少勾选一项：
`gh pr create --fill` 的空 body、或模板段但四类全空，都会让门禁静默跳过
（二轮审计 P2-2、三轮审计 P1-1）。

用法：
    PR_BODY="$(gh pr view --json body -q .body)" PR_CONTEXT=1 \
        python3 scripts/check_pr_scope.py --base origin/main

CI 里由 `.github/workflows/ci.yml` 的 `api-bump` job 传入 PR body、PR_CONTEXT 与 base sha。

退出码：
    0  通过，没有 PR 上下文（本地 preflight 不判），PR 未改公开代码且 body 为空，
       或只改文档 / 脚本
    1  空 body / 全未勾选 / 缺根包或子包 CHANGELOG /
       公开变化没有抬版本且没有 `## Unreleased`
    2  参数 / git 错误
"""
from __future__ import annotations

import argparse
import os
import pathlib
import re
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from check_public_api_diff import latest_snapshot_version  # noqa: E402
from check_version_bump import published_version as published_baseline  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
# 勾选这三类都意味着「有公开影响」：删除 / 废弃、新增包同样必须写 CHANGELOG。
PUBLIC_CHANGE_MARKS = ('公开变化', '删除 / 废弃', '新增包')
SECTION_HEADING = re.compile(r'(?m)^##\s+改动类型(?:\s*$|\s*[（(].*$)')
CHECKED_BOX = re.compile(r'^\s*[-*]\s*\[[xX]\]\s*(.*)$', re.MULTILINE)
PACKAGE_LIB = re.compile(r'^packages/([^/]+)/lib/')
# 公开行为不只在 lib/：CLI 的 bin/、templates/、catalog/、schema/ 同样会改变消费方看到的内容。
PACKAGE_PUBLIC = re.compile(r'^packages/([^/]+)/(?:lib|bin|templates|catalog|schema)/')
PUBLIC_PATH = re.compile(
    r'^(?:packages/[^/]+/(?:lib|bin)/|packages/cli/(?:templates|catalog|schema)/|lib/)'
)
ROOT_CHANGELOG = 'CHANGELOG.md'


def resolve_pr_body(body_file: str | None) -> str:
    """PR body：本地预检优先读文件，CI 走 `PR_BODY` 环境变量。"""
    if body_file:
        return pathlib.Path(body_file).read_text()
    return os.environ.get('PR_BODY', '')


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


def root_public_change(changed: list[str]) -> bool:
    """是否改了根包的公开面（`lib/` / `pubspec.yaml`）。"""
    return any(path == 'pubspec.yaml' or path.startswith('lib/') for path in changed)


def missing_root_changelog(changed: list[str]) -> bool:
    """改了根包公开面却没有改根 CHANGELOG。

    根包改动不能由任意子包 CHANGELOG 顶替；混在子包改动里也不行。
    """
    return root_public_change(changed) and ROOT_CHANGELOG not in changed


def touches_changelog(changed: list[str]) -> bool:
    """勾了公开类别时，是否改到了相关 CHANGELOG。

    - 子包：必须有被改包的 `packages/<pkg>/CHANGELOG.md`；
    - 根包：只有同时改了根 `lib/` 或根 `pubspec.yaml` 时，根 `CHANGELOG.md` 才算。
    """
    if public_packages(changed):
        return all(
            f'packages/{package}/CHANGELOG.md' in changed
            for package in public_packages(changed)
        )
    if ROOT_CHANGELOG not in changed:
        return False
    return root_public_change(changed)


def release_parts(raw: str) -> tuple[int, ...]:
    """major.minor.patch；pre-release / build 后缀不参与（与 check_version_bump 一致）。"""
    parts = [int(part) for part in re.findall(r'\d+', raw)[:3]]
    while len(parts) < 3:
        parts.append(0)
    return tuple(parts)


def changelog_section(text: str, heading: str) -> str:
    """返回 `## <heading>` 到下一个二级标题之间的正文。"""
    match = re.search(rf'(?m)^##\s+{re.escape(heading)}\s*$', text, re.IGNORECASE)
    if not match:
        return ''
    rest = text[match.end():]
    following = re.search(r'(?m)^##\s+', rest)
    return rest[:following.start()] if following else rest


def has_unreleased_entry(text: str) -> bool:
    """`## Unreleased` 段里是否有真实条目（只写标题不算）。"""
    body = changelog_section(text, 'Unreleased')
    return any(
        line.strip() and not line.strip().startswith('#')
        for line in body.splitlines()
    )


def package_version(package: str) -> str | None:
    path = ROOT / 'packages' / package / 'pubspec.yaml'
    if not path.is_file():
        return None
    match = re.search(r'(?m)^version:\s*(\S+)', path.read_text())
    return match.group(1) if match else None


def changelog_policy_error_for(
    package: str,
    current_version: str | None,
    published_version: str | None,
    changelog_text: str,
) -> str | None:
    """公开变化落在已发布版本段且没抬版本时返回错误。

    已发布基线由调用方给出（默认仓库快照；CI 的 `--online` 用 pub.dev）。
    当前版本高于它时属于未发布窗口，沿用当前版本段是允许的。基线与当前版本
    相等（或更旧）时，必须抬版本，或把变化写进 `## Unreleased`。
    """
    if not current_version or not published_version:
        return None
    if release_parts(current_version) > release_parts(published_version):
        return None
    if has_unreleased_entry(changelog_text):
        return None
    return (
        f'{package}: 本地版本 {current_version} 不高于已发布基线'
        f'（快照 {published_version}），但这次公开变化没有抬版本，'
        'CHANGELOG 里也没有 `## Unreleased` 条目；'
        '请抬版本，或把变化写进 `## Unreleased`，不要追加到已发布版本段'
    )


def changelog_policy_errors(
    changed: list[str],
    published_for=None,
) -> list[str]:
    """published_for 默认用仓库快照；CI 传 --online 时用 pub.dev（回退快照）。"""
    resolve = published_for or latest_snapshot_version
    errors: list[str] = []
    for package in sorted(public_packages(changed)):
        changelog_rel = f'packages/{package}/CHANGELOG.md'
        if changelog_rel not in changed:
            continue
        path = ROOT / changelog_rel
        text = path.read_text() if path.is_file() else ''
        error = changelog_policy_error_for(
            package,
            package_version(package),
            resolve(package),
            text,
        )
        if error:
            errors.append(error)
    return errors


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
    parser.add_argument(
        '--online',
        action='store_true',
        help='用 pub.dev 最新版本当已发布基线（取不到回退仓库快照并提醒）',
    )
    parser.add_argument('--body-file', help='从文件读 PR body（本地预检用；缺省读 PR_BODY）')
    args = parser.parse_args()

    pr_body = resolve_pr_body(args.body_file)
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

    if not public_packages(changed) and not root_public_change(changed):
        print('勾选了公开类别，但本次没有改公开代码；按文档改动跳过 CHANGELOG 检查')
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
    if missing_root_changelog(changed):
        print(
            '✗ 改了根包 lib/ 或 pubspec.yaml，但没有改根 CHANGELOG.md；'
            '子包 CHANGELOG 不能代替根包记录。',
            file=sys.stderr,
        )
        return 1
    warnings: list[str] = []

    def published_for(package: str) -> str | None:
        if args.online:
            return published_baseline(package, True, warnings)
        return latest_snapshot_version(package)

    policy_errors = changelog_policy_errors(changed, published_for)
    for warning in warnings:
        print(f'  ! {warning}')
    if policy_errors:
        print(
            '✗ 勾选了公开类别，但以下包的行为变化没有抬版本，也没写进 `## Unreleased`：',
            file=sys.stderr,
        )
        for error in policy_errors:
            print(f'  ✗ {error}', file=sys.stderr)
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
