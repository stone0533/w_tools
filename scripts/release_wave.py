#!/usr/bin/env python3
"""发布波次计划（只读）：谁需要发、按什么顺序、有哪些阻断项。

为什么需要它：K-1M 目前要人 / AI 逐包跑 drift、release_status、release_check，自己
拼一张表再排序；命令多、顺序容易漏。这个脚本只做「读 + 算 + 打印」，不发布、不改文件。

输出：
- 每包本地 / pub.dev / 最新快照 / 动作 / 原因；
- 发布顺序（契约包先于实现包；CLI 在它 init 约束指向的子包之后；根包最后）；
- 快照 PR 是否必需；
- 阻断项（工作区 / 分支 / 版本 / CHANGELOG / 约束 / 根包快照 / drift）。

用法：
    python3 scripts/release_wave.py plan --all
    python3 scripts/release_wave.py plan --all --check
    python3 scripts/release_wave.py plan --packages app_getx,map_google,cli,root --json
    python3 scripts/release_wave.py plan --all --no-drift   # 跳过归档 CODE DRIFT 核对

退出码：0 生成了计划（有阻断也返回 0，除非 --check）；1 --check 且有阻断；2 参数 / 读取错误。
"""
from __future__ import annotations

import argparse
import json
import pathlib
import re
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone

ROOT = pathlib.Path(__file__).resolve().parent.parent
SCHEMA = 'w_tools.release_plan/1'
TOOL_PACKAGES = {'cli', 'figma', 'device', 'e2e'}
VERSIONS_DART = ROOT / 'packages' / 'cli' / 'lib' / 'src' / 'init' / 'versions.dart'
SNAPSHOT_DIR = ROOT / '.w_tools' / 'release-snapshots'

sys.path.insert(0, str(ROOT / 'scripts'))
from release_status import (  # noqa: E402
    PackageNotFound,
    fetch_latest,
    pending_first_release,
    read_manifest,
    snapshot_version,
    version_of,
    version_tuple,
)


@dataclass
class PlanData:
    rows: list[dict[str, str]]
    published: dict[str, str]
    not_found: set[str]
    unreachable: set[str]
    drift: dict[str, str]
    snapshots: dict[str, str | None]
    pending: set[str]
    pending_snapshots: bool
    root_version: str | None
    root_published: str | None
    root_not_found: bool
    root_unreachable: bool
    root_changelog_ok: bool
    changelog: dict[str, bool]
    git: dict[str, object]
    check_errors: list[str]
    release_errors: list[str]
    audit_drift: bool


def _git(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        ['git', *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )


def git_state() -> dict[str, object]:
    dirty = bool(_git('status', '--porcelain').stdout.strip())
    branch = _git('rev-parse', '--abbrev-ref', 'HEAD').stdout.strip()
    head = _git('rev-parse', 'HEAD').stdout.strip()
    origin = _git('rev-parse', '--verify', '--quiet', 'origin/main')
    origin_main = origin.stdout.strip() if origin.returncode == 0 else None
    ahead = behind = None
    if origin_main:
        counts = _git('rev-list', '--left-right', '--count', 'origin/main...HEAD')
        if counts.returncode == 0:
            parts = counts.stdout.split()
            if len(parts) == 2:
                behind, ahead = int(parts[0]), int(parts[1])
    return {
        'dirty': dirty,
        'branch': branch,
        'head': head,
        'origin_main': origin_main,
        'ahead': ahead,
        'behind': behind,
    }


def changelog_has_version(path: pathlib.Path, version: str | None) -> bool:
    if not version or not path.is_file():
        return False
    return bool(re.search(rf'(?m)^##\s+{re.escape(version)}(?:\s|$)', path.read_text()))


def versions_dart_constraints() -> dict[str, str]:
    text = VERSIONS_DART.read_text()
    match = re.search(
        r'const\s+subpackageConstraints\s*=\s*<String,\s*String>\{(.*?)\};',
        text,
        re.S,
    )
    return dict(re.findall(r"'([^']+)'\s*:\s*'([^']+)'", match.group(1))) if match else {}


def drift_status(package: str) -> str:
    """ok / code / unknown；调用 check_publish_drift 只关心 code drift。"""
    result = subprocess.run(
        [sys.executable, str(ROOT / 'scripts' / 'check_publish_drift.py'), '--package', package, '--check'],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if result.returncode == 1:
        return 'code'
    if result.returncode == 2:
        return 'unknown'
    return 'ok'


def check_versions_errors() -> list[str]:
    result = subprocess.run(
        [sys.executable, str(ROOT / 'scripts' / 'check_versions.py')],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if result.returncode == 0:
        return []
    return [line for line in (result.stdout + result.stderr).splitlines() if line.strip()]


def release_check_errors() -> list[str]:
    result = subprocess.run(
        ['bash', str(ROOT / 'scripts' / 'release_check.sh')],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if result.returncode == 0:
        return []
    lines = [line for line in (result.stdout + result.stderr).splitlines() if '✗' in line]
    return lines or ['release_check.sh 失败（运行 bash scripts/release_check.sh 查看）']


def _rows() -> list[dict[str, str]]:
    rows = []
    for name, path, aggregate in read_manifest():
        short = name.removeprefix('w_tools_')
        pubspec = ROOT / path / 'pubspec.yaml'
        rows.append(
            {
                'name': name,
                'short': short,
                'path': path,
                'aggregate': aggregate,
                'version': version_of(pubspec) or '',
                'changelog': changelog_has_version(ROOT / path / 'CHANGELOG.md', version_of(pubspec)),
            }
        )
    return rows


def collect_data(rows: list[dict[str, str]], *, audit_drift: bool) -> PlanData:
    published: dict[str, str] = {}
    not_found: set[str] = set()
    unreachable: set[str] = set()
    for row in rows:
        short = row['short']
        try:
            value = fetch_latest(row['name'])
        except PackageNotFound:
            not_found.add(short)
            continue
        if value is None:
            unreachable.add(short)
        else:
            published[short] = value

    root_version = version_of(ROOT / 'pubspec.yaml')
    root_published: str | None = None
    root_not_found = False
    root_unreachable = False
    try:
        root_published = fetch_latest('w_tools')
    except PackageNotFound:
        root_not_found = True
    if root_published is None and not root_not_found:
        root_unreachable = True

    drift: dict[str, str] = {}
    if audit_drift:
        for row in rows:
            if published.get(row['short']) == row['version']:
                drift[row['short']] = drift_status(row['short'])
        if root_version and root_published == root_version:
            drift['root'] = drift_status('w_tools')

    snapshots = {row['short']: snapshot_version(row['short']) for row in rows}
    return PlanData(
        rows=rows,
        published=published,
        not_found=not_found,
        unreachable=unreachable,
        drift=drift,
        snapshots=snapshots,
        pending=pending_first_release(),
        pending_snapshots=any(SNAPSHOT_DIR.glob('w_tools_*.txt')) if SNAPSHOT_DIR.is_dir() else False,
        root_version=root_version,
        root_published=root_published,
        root_not_found=root_not_found,
        root_unreachable=root_unreachable,
        root_changelog_ok=changelog_has_version(ROOT / 'CHANGELOG.md', root_version),
        changelog={row['short']: bool(row['changelog']) for row in rows},
        git=git_state(),
        check_errors=check_versions_errors(),
        release_errors=release_check_errors(),
        audit_drift=audit_drift,
    )


def classify(local: str, published: str | None, *, pending: bool, unreachable: bool, not_found: bool) -> tuple[str, str]:
    if unreachable:
        return 'blocked', '取不到 pub.dev 版本，无法判断'
    if not_found:
        if pending:
            return 'publish', '首发（pub.dev 404，已在 pending_first_release）'
        return 'blocked', 'pub.dev 404 且不在 pending_first_release（包名拼错 / 改名？）'
    if published is None:
        return 'blocked', '取不到 pub.dev 版本，无法判断'
    if version_tuple(local) > version_tuple(published):
        return 'publish', f'本地 {local} > 线上 {published}'
    if version_tuple(local) < version_tuple(published):
        return 'blocked', f'本地 {local} < 线上 {published}（仓库落后）'
    return 'skip', '版本已发布'


def _add(blockers: list[str], package: str, reason: str) -> None:
    blockers.append(f'{package}: {reason}')


def order_candidates(candidates: list[str], deps: dict[str, list[str]]) -> tuple[list[str], str | None]:
    """稳定拓扑排序；返回 (order, error)。"""
    result: list[str] = []
    state: dict[str, int] = {}

    def visit(node: str) -> str | None:
        status = state.get(node, 0)
        if status == 1:
            return f'依赖环：{node}'
        if status == 2:
            return None
        state[node] = 1
        for dep in deps.get(node, []):
            if dep in candidates:
                error = visit(dep)
                if error:
                    return error
        state[node] = 2
        result.append(node)
        return None

    for candidate in candidates:
        error = visit(candidate)
        if error:
            return [], error
    return result, None


def build_plan(data: PlanData) -> dict[str, object]:
    blockers: list[str] = []
    warnings: list[str] = []
    packages: list[dict[str, object]] = []
    by_short: dict[str, dict[str, object]] = {}

    for row in data.rows:
        short = row['short']
        local = row['version']
        published = data.published.get(short)
        action, reason = classify(
            local,
            published,
            pending=short in data.pending,
            unreachable=short in data.unreachable,
            not_found=short in data.not_found,
        )
        if action == 'publish' and not data.changelog.get(short, False):
            action = 'blocked'
            reason = f'CHANGELOG 缺 ## {local} 段'
        drift = data.drift.get(short)
        if action == 'skip' and drift == 'code':
            action = 'blocked'
            reason = '同版本 CODE DRIFT（内容变了但版本没抬）'
        elif action == 'skip' and drift == 'unknown':
            warnings.append(f'{short}: code drift 未核对（网络 / 工具不可用）')
        package = {
            'name': row['name'],
            'short': short,
            'version': local,
            'published': published,
            'snapshot': data.snapshots.get(short),
            'action': action,
            'reason': reason,
        }
        packages.append(package)
        by_short[short] = package
        if action == 'blocked':
            _add(blockers, short, reason)

    candidates = [row['short'] for row in data.rows if by_short[row['short']]['action'] == 'publish']
    if not data.audit_drift:
        warnings.append('所有包：未核对 code drift（--no-drift）；发布前请跑 check_publish_drift.py')

    # 依赖：契约包先于实现包；CLI 在它 init 约束指向的子包之后。
    deps: dict[str, list[str]] = {'app_getx': ['app'], 'map_google': ['map']}
    if 'cli' in candidates:
        init_constraints = versions_dart_constraints()
        deps['cli'] = [
            name.removeprefix('w_tools_')
            for name in init_constraints
            if name.removeprefix('w_tools_') in candidates
        ]
    for row in data.rows:
        if by_short[row['short']]['action'] == 'publish':
            for dep in deps.get(row['short'], []):
                if dep not in by_short:
                    _add(blockers, row['short'], f'依赖 {dep} 未在本次计划中选择；请加入 --packages 或先确认已发布')
                elif by_short[dep]['action'] != 'publish' and data.published.get(dep) is None:
                    _add(blockers, row['short'], f'依赖 {dep} 还没发布')

    order, order_error = order_candidates(candidates, deps)
    if order_error:
        _add(blockers, 'order', order_error)

    # 根包
    root_version = data.root_version
    if not root_version:
        root_action, root_reason = 'blocked', '根 pubspec 缺 version'
    else:
        root_action, root_reason = classify(
            root_version,
            data.root_published,
            pending=False,
            unreachable=data.root_unreachable,
            not_found=data.root_not_found,
        )
    if root_action == 'publish' and not data.root_changelog_ok:
        root_action = 'blocked'
        root_reason = f'根 CHANGELOG 缺 ## {root_version} 段'
    root_drift = data.drift.get('root')
    if root_action == 'skip' and root_drift == 'code':
        root_action = 'blocked'
        root_reason = '根包同版本 CODE DRIFT'
    elif root_action == 'skip' and root_drift == 'unknown':
        warnings.append('root: code drift 未核对')
    root = {
        'name': 'w_tools',
        'version': root_version,
        'published': data.root_published,
        'action': root_action,
        'reason': root_reason,
    }
    if root_action == 'blocked':
        _add(blockers, 'root', root_reason)
    if root_action == 'publish':
        if data.pending_snapshots:
            _add(blockers, 'root', '.w_tools/release-snapshots 还有未应用快照')
        for row in data.rows:
            if row['aggregate'] != 'root':
                continue
            short = row['short']
            if by_short[short]['action'] == 'publish':
                continue
            if data.snapshots.get(short) != row['version']:
                _add(
                    blockers,
                    'root',
                    f'{short} 快照 {data.snapshots.get(short) or "缺失"} != 本地 {row["version"]}；先发布它',
                )
        if candidates:
            _add(blockers, 'root', '先发布子包并合入快照 PR，再发根包')

    if root_action == 'skip' and data.pending_snapshots:
        warnings.append('root: 还有未应用的快照；如果要发根包，先走快照 PR')

    # Git / 既有门禁
    git = data.git
    if git.get('dirty'):
        _add(blockers, 'git', '工作区有未提交改动')
    if git.get('branch') != 'main':
        _add(blockers, 'git', f'当前分支是 {git.get("branch")}，发布只允许 main')
    if not git.get('origin_main'):
        _add(blockers, 'git', '找不到 origin/main，先 git fetch')
    elif git.get('head') != git.get('origin_main'):
        _add(blockers, 'git', 'HEAD != origin/main，先 git pull --ff-only')
    if git.get('ahead') or git.get('behind'):
        _add(blockers, 'git', f'ahead={git.get("ahead")} behind={git.get("behind")}')
    for error in data.check_errors:
        _add(blockers, 'versions', error)
    for error in data.release_errors:
        _add(blockers, 'release_check', error)

    return {
        'schema': SCHEMA,
        'created_at': datetime.now(timezone.utc).isoformat(timespec='seconds'),
        'git': git,
        'packages': packages,
        'order': order,
        'root': root,
        'snapshots_required': bool(candidates),
        'pending_snapshots': data.pending_snapshots,
        'blockers': blockers,
        'warnings': warnings,
        'summary': {
            'publish': len(candidates),
            'skip': sum(1 for p in packages if p['action'] == 'skip'),
            'blocked': sum(1 for p in packages if p['action'] == 'blocked'),
            'root': root_action,
        },
    }


def _selected_rows(all_rows: list[dict[str, str]], packages: str | None) -> tuple[list[dict[str, str]], bool]:
    """返回 (rows, include_root)。packages=None 表示全部。"""
    if not packages:
        return all_rows, True
    wanted = {part.strip().removeprefix('w_tools_') for part in packages.split(',') if part.strip()}
    known = {row['short'] for row in all_rows}
    unknown = wanted - known - {'root'}
    if unknown:
        raise ValueError(f'未知包：{", ".join(sorted(unknown))}（可选：{", ".join(sorted(known))}, root）')
    include_root = 'root' in wanted
    wanted.discard('root')
    # 依赖自动带上：计划可能只点一个包，但发布顺序 / 根包快照依赖仍要完整。
    if 'app_getx' in wanted:
        wanted.add('app')
    if 'map_google' in wanted:
        wanted.add('map')
    if 'cli' in wanted:
        wanted.update(
            name.removeprefix('w_tools_') for name in versions_dart_constraints()
        )
    if include_root:
        wanted.update(row['short'] for row in all_rows if row['aggregate'] == 'root')
    return [row for row in all_rows if row['short'] in wanted], include_root


def print_human(plan: dict[str, object]) -> None:
    git = plan['git']
    print('=== 发布波次计划（只读） ===')
    print(f"base: {git.get('branch')}@{str(git.get('head'))[:8]}  clean={not git.get('dirty')}")
    print()
    print('| 包 | 本地 | 线上 | 快照 | 动作 | 说明 |')
    print('|---|---|---|---|---|---|')
    for package in plan['packages']:
        print(
            f"| {package['short']} | {package['version']} | {package['published'] or '-'} | "
            f"{package['snapshot'] or '-'} | {package['action']} | {package['reason']} |",
        )
    root = plan['root']
    print(
        f"| root | {root['version'] or '-'} | {root['published'] or '-'} | - | "
        f"{root['action']} | {root['reason']} |",
    )
    print()
    order = plan['order']
    print(f"发布顺序: {' -> '.join(order) if order else '（无子包待发布）'}")
    print(f"快照 PR: {'需要' if plan['snapshots_required'] else '不需要'}"
          f"{'（已有未应用快照）' if plan['pending_snapshots'] else ''}")
    if plan['blockers']:
        print('\n阻断:')
        for blocker in plan['blockers']:
            print(f'  ✗ {blocker}')
    else:
        print('\n阻断: 无')
    if plan['warnings']:
        print('\n提醒:')
        for warning in plan['warnings']:
            print(f'  ! {warning}')


def main() -> int:
    parser = argparse.ArgumentParser(description='发布波次计划（只读）')
    parser.add_argument('command', choices=['plan'])
    parser.add_argument('--all', action='store_true', help='计划所有 manifest 包 + 根包（默认）')
    parser.add_argument('--packages', help='只计划这些包（逗号分隔；root 用 root）')
    parser.add_argument('--json', action='store_true', help='输出 JSON')
    parser.add_argument('--check', action='store_true', help='有阻断时退出 1')
    parser.add_argument('--no-drift', action='store_true', help='跳过同版本归档 CODE DRIFT 核对')
    parser.add_argument('--fetch', action='store_true', help='先 git fetch origin main')
    args = parser.parse_args()

    if args.fetch:
        fetched = _git('fetch', 'origin', 'main')
        if fetched.returncode != 0:
            print(f'✗ git fetch origin main 失败：{fetched.stderr.strip()}', file=sys.stderr)
            return 2

    all_rows = _rows()
    try:
        rows, include_root = _selected_rows(all_rows, args.packages)
    except ValueError as error:
        print(f'✗ {error}', file=sys.stderr)
        return 2
    if not rows and not include_root:
        print('✗ 没有选中任何包', file=sys.stderr)
        return 2

    data = collect_data(rows, audit_drift=not args.no_drift)
    plan = build_plan(data)
    if not include_root:
        # 不计划根包时，不把根包状态算进阻断；仍保留字段便于阅读。
        plan['blockers'] = [
            blocker for blocker in plan['blockers'] if not str(blocker).startswith('root:')
        ]
        plan['root']['action'] = 'skip'
        plan['root']['reason'] = '未在 --packages 中选择 root'
        plan['summary']['root'] = 'skip'

    if args.json:
        print(json.dumps(plan, ensure_ascii=False, indent=2))
    else:
        print_human(plan)
    if args.check and plan['blockers']:
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
