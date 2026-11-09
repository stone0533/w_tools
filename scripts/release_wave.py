#!/usr/bin/env python3
"""发布波次：plan 只读计划；run 执行已批准的计划（dry-run → publish → 快照 PR → 根包 → 验证）。

`plan` 只读：谁需要发、按什么顺序、有哪些阻断项。命令多、顺序容易漏的问题用一张表收敛。

`run` 只接受 `plan` 产出的计划文件（相当于人工批准的那份），并逐包复用现有 fail-closed
脚本：`publish_package.sh` / `apply_snapshots.sh` / `gh`。它不会改版本、不会写
CHANGELOG、不会 `--force`；失败会保存 state，可用 `run --resume` 从断点继续，已发布的包不重发。

用法：
    python3 scripts/release_wave.py plan --all
    python3 scripts/release_wave.py plan --all --check
    python3 scripts/release_wave.py plan --all --json > .w_tools/release-plan.json
    python3 scripts/release_wave.py run --plan .w_tools/release-plan.json --dry-run
    python3 scripts/release_wave.py run --plan .w_tools/release-plan.json --yes
    python3 scripts/release_wave.py run --resume --yes
    python3 scripts/release_wave.py status

退出码：plan 0 生成（--check 有阻断时 1）；run 0 成功，2 前置不满足，3 发布失败，
4 快照 PR 失败，5 验证失败，6 等 pub.dev 超时。
"""
from __future__ import annotations

import argparse
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import datetime, timezone

ROOT = pathlib.Path(__file__).resolve().parent.parent
SCHEMA = 'w_tools.release_plan/1'
STATE_SCHEMA = 'w_tools.release_wave_state/1'
TOOL_PACKAGES = {'cli', 'figma', 'device', 'e2e'}
VERSIONS_DART = ROOT / 'packages' / 'cli' / 'lib' / 'src' / 'init' / 'versions.dart'
SNAPSHOT_DIR = ROOT / '.w_tools' / 'release-snapshots'
STATE_FILE = ROOT / '.w_tools' / 'release-wave-state.json'
LOCK_FILE = ROOT / '.w_tools' / 'release-wave.lock'

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
            'path': row['path'],
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
        'requires': [],
    }
    if root_action == 'blocked':
        _add(blockers, 'root', root_reason)
    if root_action == 'publish':
        if candidates:
            # 正常波次的顺序要求，不是阻断：子包发完、快照 PR 合入后再发根包。
            root['requires'].append('先发布子包并合入快照 PR')
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
    if root['requires']:
        print(f"根包前置: {'；'.join(root['requires'])}")
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


class RunFailed(Exception):
    def __init__(self, message: str, code: int = 3) -> None:
        super().__init__(message)
        self.code = code


def _cmd(
    args: list[str],
    *,
    capture: bool = False,
    check: bool = True,
    code: int = 3,
) -> subprocess.CompletedProcess:
    print(f"==> {' '.join(args)}", flush=True)
    result = subprocess.run(
        args,
        cwd=ROOT,
        text=True,
        capture_output=capture,
        env={**os.environ, 'CI': 'true'},
    )
    if result.returncode != 0 and check:
        if capture:
            sys.stderr.write(result.stdout or '')
            sys.stderr.write(result.stderr or '')
        raise RunFailed(f'命令失败（exit {result.returncode}）：{" ".join(args)}', code)
    return result


def _write_json(path: pathlib.Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(path.suffix + '.tmp')
    temp.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
    temp.replace(path)


def _load_plan(path: pathlib.Path) -> dict:
    if not path.is_file():
        raise RunFailed(f'找不到计划文件：{path}', 2)
    try:
        plan = json.loads(path.read_text())
    except json.JSONDecodeError as error:
        raise RunFailed(f'计划文件不是合法 JSON：{error}', 2) from error
    if plan.get('schema') != SCHEMA:
        raise RunFailed(f'计划 schema 不是 {SCHEMA}', 2)
    return plan


def _load_state() -> dict | None:
    if not STATE_FILE.is_file():
        return None
    try:
        state = json.loads(STATE_FILE.read_text())
    except json.JSONDecodeError as error:
        raise RunFailed(f'state 不是合法 JSON：{error}', 2) from error
    if state.get('schema') != STATE_SCHEMA:
        raise RunFailed(f'state schema 不是 {STATE_SCHEMA}', 2)
    return state


def _save_state(state: dict) -> None:
    state['updated_at'] = datetime.now(timezone.utc).isoformat(timespec='seconds')
    _write_json(STATE_FILE, state)


def _acquire_lock() -> int:
    LOCK_FILE.parent.mkdir(parents=True, exist_ok=True)
    try:
        fd = os.open(LOCK_FILE, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o644)
    except FileExistsError as error:
        raise RunFailed(
            f'已有发布进程持有 {LOCK_FILE}；确认没有别的发布后再删掉它',
            2,
        ) from error
    os.write(fd, f'{os.getpid()} {datetime.now(timezone.utc).isoformat()}\n'.encode())
    return fd


def _release_lock(fd: int) -> None:
    try:
        os.close(fd)
    except OSError:
        pass
    try:
        LOCK_FILE.unlink()
    except OSError:
        pass


def _gh_ready() -> tuple[bool, str]:
    if shutil.which('gh') is None:
        return False, '找不到 gh；快照 PR 需要 gh'
    result = subprocess.run(
        ['gh', 'auth', 'status'],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return False, 'gh 未登录；先 gh auth login（快照 PR 需要）'
    return True, ''


def validate_run_plan(
    plan: dict,
    *,
    rows: list[dict[str, str]] | None = None,
    git: dict[str, object] | None = None,
    gh_ready: bool | None = None,
) -> list[str]:
    """run 前的只读校验：计划仍是当前 main 上那份，且没有阻断。"""
    errors: list[str] = []
    if plan.get('schema') != SCHEMA:
        errors.append(f'计划 schema 不是 {SCHEMA}')
    if plan.get('blockers'):
        errors.append('计划还有阻断项：' + '；'.join(str(item) for item in plan['blockers']))

    current_git = git or git_state()
    expected_git = plan.get('git') or {}
    if current_git.get('dirty'):
        errors.append('工作区有未提交改动')
    if current_git.get('branch') != 'main':
        errors.append(f'当前分支是 {current_git.get("branch")}，发布只允许 main')
    if not current_git.get('origin_main'):
        errors.append('找不到 origin/main')
    elif current_git.get('head') != current_git.get('origin_main'):
        errors.append('HEAD != origin/main，先 git pull --ff-only')
    if expected_git.get('head') and current_git.get('head') != expected_git.get('head'):
        errors.append('当前 HEAD 与计划生成时的 HEAD 不一致；重新 plan')
    if expected_git.get('origin_main') and current_git.get('origin_main') != expected_git.get('origin_main'):
        errors.append('origin/main 与计划生成时不一致；重新 plan')

    plan_rows = rows if rows is not None else _rows()
    by_short = {row['short']: row for row in plan_rows}
    order = [str(item) for item in (plan.get('order') or [])]
    publish_shorts = [
        str(package['short'])
        for package in plan.get('packages', [])
        if package.get('action') == 'publish'
    ]
    if sorted(order) != sorted(publish_shorts):
        errors.append(f'计划顺序 {order} 与待发布包 {publish_shorts} 不一致')

    for package in plan.get('packages', []):
        short = str(package.get('short'))
        action = package.get('action')
        if action == 'blocked':
            errors.append(f'{short}: 计划里是 blocked')
            continue
        if action != 'publish':
            continue
        row = by_short.get(short)
        if row is None:
            errors.append(f'{short}: 不在 packages.manifest')
            continue
        path = package.get('path') or row['path']
        local = version_of(ROOT / str(path) / 'pubspec.yaml')
        version = package.get('version')
        if local != version:
            errors.append(f'{short}: 本地版本 {local} 与计划 {version} 不一致')
        if not changelog_has_version(ROOT / str(path) / 'CHANGELOG.md', version):
            errors.append(f'{short}: CHANGELOG 缺 ## {version} 段')

    root = plan.get('root') or {}
    if root.get('action') == 'blocked':
        errors.append('root: 计划里是 blocked')
    if root.get('action') == 'publish':
        local_root = version_of(ROOT / 'pubspec.yaml')
        if local_root != root.get('version'):
            errors.append(f'root: 本地版本 {local_root} 与计划 {root.get("version")} 不一致')
        if not changelog_has_version(ROOT / 'CHANGELOG.md', root.get('version')):
            errors.append(f'root: CHANGELOG 缺 ## {root.get("version")} 段')

    if plan.get('snapshots_required'):
        if gh_ready is None:
            gh_ready = _gh_ready()[0]
        if not gh_ready:
            errors.append('快照 PR 需要 gh 且已登录；先 gh auth login')
    return errors


def _publish_package(package: dict, *, dry_run: bool) -> None:
    short = str(package['short'])
    path = str(package.get('path') or f'packages/{short}')
    _cmd(['bash', 'scripts/release_check.sh', '--strict', '--package', short], code=3)
    _cmd(['bash', 'scripts/publish_package.sh', path, '--dry-run'], code=3)
    if not dry_run:
        _cmd(['bash', 'scripts/publish_package.sh', path, '--yes'], code=3)


def _wait_versions(state: dict, wait_minutes: int) -> None:
    published = state.get('published') or {}
    if not published:
        return
    deadline = time.time() + max(0, wait_minutes) * 60
    pending = {short: info['version'] for short, info in published.items()}
    while pending:
        for short, version in list(pending.items()):
            try:
                online = fetch_latest(f'w_tools_{short}')
            except PackageNotFound:
                online = None
            if online == version:
                print(f'  ✓ {short} {version} 已在 pub.dev 可见')
                pending.pop(short, None)
        if not pending:
            return
        if time.time() > deadline:
            raise RunFailed(
                f'等待 pub.dev 可见超时：{", ".join(f"{k} {v}" for k, v in pending.items())}',
                6,
            )
        print(f'  … 等待 pub.dev 可见：{", ".join(pending)}')
        time.sleep(10)


def _snapshot_step(state: dict, plan: dict) -> None:
    if state.get('snapshots') == 'merged':
        return
    state['phase'] = 'snapshots'
    _save_state(state)
    _cmd(['bash', 'scripts/apply_snapshots.sh'], code=4)
    changed = _git('status', '--porcelain', 'scripts/api_snapshots').stdout.strip()
    if not changed:
        state['snapshots'] = 'none'
        _save_state(state)
        return

    branch = state.get('snapshot_branch')
    pr = state.get('snapshot_pr')
    if not pr:
        branch = branch or f"chore/release-snapshots-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
        exists = _git('show-ref', '--verify', '--quiet', f'refs/heads/{branch}').returncode == 0
        if exists:
            _cmd(['git', 'switch', branch], code=4)
        else:
            _cmd(['git', 'switch', '-c', branch], code=4)
        _cmd(['git', 'add', 'scripts/api_snapshots'], code=4)
        versions = ', '.join(
            f"{short} {info['version']}" for short, info in (state.get('published') or {}).items()
        )
        message = f'chore(release): {versions} API 基线' if versions else 'chore(release): API 基线'
        _cmd(['git', 'commit', '-m', message], code=4)
        _cmd(['git', 'push', '-u', 'origin', 'HEAD'], code=4)
        created = _cmd(['gh', 'pr', 'create', '--fill'], capture=True, code=4)
        print(created.stdout.strip())
        number = _cmd(
            ['gh', 'pr', 'view', '--json', 'number', '--jq', '.number'],
            capture=True,
            code=4,
        ).stdout.strip()
        pr = int(number)
        state['snapshot_branch'] = branch
        state['snapshot_pr'] = pr
        _save_state(state)

    _cmd(['gh', 'pr', 'checks', str(pr), '--required', '--watch'], code=4)
    _cmd(['gh', 'pr', 'merge', str(pr), '--merge'], code=4)
    _cmd(['git', 'switch', 'main'], code=4)
    _cmd(['git', 'pull', '--ff-only'], code=4)
    if branch:
        _git('branch', '-d', branch)
    state['snapshots'] = 'merged'
    _save_state(state)


def _root_step(state: dict, plan: dict, wait_minutes: int) -> None:
    root = plan.get('root') or {}
    if root.get('action') != 'publish':
        state['root'] = 'skipped'
        _save_state(state)
        return
    state['phase'] = 'root'
    _save_state(state)
    _wait_versions(state, wait_minutes)
    _cmd(['bash', 'scripts/release_check.sh', '--strict'], code=3)
    _cmd(['bash', 'scripts/publish_package.sh', '.', '--dry-run'], code=3)
    _cmd(['bash', 'scripts/publish_package.sh', '.', '--yes'], code=3)
    state['root'] = 'published'
    _save_state(state)


def _verify_step(state: dict, wait_minutes: int) -> None:
    state['phase'] = 'verifying'
    _save_state(state)
    deadline = time.time() + max(0, wait_minutes) * 60
    while True:
        result = _cmd(
            [sys.executable, 'scripts/release_status.py', '--online', '--check'],
            check=False,
            code=5,
        )
        if result.returncode == 0:
            break
        if time.time() > deadline:
            raise RunFailed('release_status --online --check 未通过（等待超时）', 5)
        print('  … 线上状态未稳定，稍后重试')
        time.sleep(15)
    drift = _cmd(
        [sys.executable, 'scripts/check_publish_drift.py', '--check'],
        check=False,
        code=5,
    )
    if drift.returncode == 1:
        raise RunFailed('check_publish_drift 报 CODE DRIFT；已发布版本不能重发，只能 fix-forward', 5)
    if drift.returncode == 2:
        print('  ! check_publish_drift 网络不可用，未完成归档核对', file=sys.stderr)
    state['phase'] = 'done'
    _save_state(state)


def _audit_drift() -> None:
    """run 前的归档核对：同版本 CODE DRIFT 必须为零，网络不可用时 fail fast。"""
    result = _cmd(
        [sys.executable, 'scripts/check_publish_drift.py', '--check'],
        check=False,
        code=3,
    )
    if result.returncode == 1:
        raise RunFailed('check_publish_drift 报 CODE DRIFT；先抬版本，不能带着漂移发布', 3)
    if result.returncode == 2:
        raise RunFailed('check_publish_drift 网络不可用，发布前无法核对归档', 2)


def _dry_run(plan: dict) -> int:
    errors = validate_run_plan(plan, gh_ready=True)
    if errors:
        for error in errors:
            print(f'✗ {error}', file=sys.stderr)
        return 2
    try:
        _audit_drift()
    except RunFailed as error:
        print(f'✗ {error}', file=sys.stderr)
        return error.code
    packages = {package['short']: package for package in plan.get('packages', [])}
    try:
        for short in plan.get('order', []):
            package = packages.get(str(short))
            if package is None:
                raise RunFailed(f'计划顺序里的 {short} 不在 packages 里', 2)
            _publish_package(package, dry_run=True)
    except RunFailed as error:
        print(f'✗ {error}', file=sys.stderr)
        return error.code
    print('\n[dry-run] 未发布。真实执行会继续：')
    if plan.get('snapshots_required'):
        print('  apply_snapshots.sh → 快照 PR → 等 checks → gh pr merge --merge → git pull')
    if (plan.get('root') or {}).get('action') == 'publish':
        print('  等子包在 pub.dev 可见 → release_check --strict → publish_package.sh . --dry-run → . --yes')
    print('  最后 release_status --online --check + check_publish_drift --check')
    return 0


def _run(args) -> int:
    resume = bool(args.resume or args.command == 'resume')
    if not args.dry_run and not args.yes:
        print('计划确认后才执行：加 --yes（或先加 --dry-run 只预演）', file=sys.stderr)
        return 2

    if resume:
        state = _load_state()
        if state is None:
            print(f'✗ 找不到 {STATE_FILE}；没有可恢复的发布', file=sys.stderr)
            return 2
        plan = state.get('plan')
        if not isinstance(plan, dict):
            print('✗ state 里没有计划，无法恢复', file=sys.stderr)
            return 2
    else:
        if not args.plan_file:
            print('✗ run 需要 --plan（先运行 plan 生成计划）', file=sys.stderr)
            return 2
        plan = _load_plan(pathlib.Path(args.plan_file))
        if STATE_FILE.exists():
            print(f'✗ 已存在 {STATE_FILE}；用 --resume 继续，或先删掉它再开新波次', file=sys.stderr)
            return 2
        state = {
            'schema': STATE_SCHEMA,
            'plan_path': str(pathlib.Path(args.plan_file)),
            'plan': plan,
            'phase': 'publishing',
            'published': {},
            'snapshots': 'pending',
            'root': 'pending',
            'snapshot_branch': None,
            'snapshot_pr': None,
            'error': None,
        }

    errors = validate_run_plan(plan)
    if errors:
        for error in errors:
            print(f'✗ {error}', file=sys.stderr)
        return 2

    if args.dry_run:
        return _dry_run(plan)

    if state.get('phase') == 'done':
        print('这一波已经完成（state.phase=done）')
        return 0

    fd = _acquire_lock()
    try:
        _save_state(state)
        _audit_drift()
        packages = {package['short']: package for package in plan.get('packages', [])}
        for short in plan.get('order', []):
            short = str(short)
            if short in state.get('published', {}):
                print(f'  - {short} 已发布，跳过')
                continue
            package = packages.get(short)
            if package is None:
                raise RunFailed(f'计划顺序里的 {short} 不在 packages 里', 2)
            print(f'\n== 发布 {short} {package["version"]}')
            _publish_package(package, dry_run=False)
            state['published'][short] = {
                'version': package['version'],
                'at': datetime.now(timezone.utc).isoformat(timespec='seconds'),
            }
            _save_state(state)

        if plan.get('snapshots_required'):
            print('\n== 快照 PR')
            _snapshot_step(state, plan)

        print('\n== 根包')
        _root_step(state, plan, args.wait_minutes)

        print('\n== 发布后验证')
        _verify_step(state, args.wait_minutes)
        state['phase'] = 'done'
        _save_state(state)
        print(f'\n✓ 发布波次完成；state: {STATE_FILE}')
        return 0
    except RunFailed as error:
        state['phase'] = 'failed'
        state['error'] = str(error)
        _save_state(state)
        print(f'\n✗ {error}', file=sys.stderr)
        print(f'  state 已保存：{STATE_FILE}；修复后用 run --resume --yes 继续', file=sys.stderr)
        return error.code
    finally:
        _release_lock(fd)


def _status(args) -> int:
    state = _load_state()
    if state is None:
        print(f'没有发布 state：{STATE_FILE}')
        return 0
    if getattr(args, 'json', False):
        print(json.dumps(state, ensure_ascii=False, indent=2))
        return 0
    print(f"波次计划: {state.get('plan_path')}")
    print(f"phase: {state.get('phase')}")
    print(f"snapshots: {state.get('snapshots')}  root: {state.get('root')}")
    if state.get('snapshot_pr'):
        print(f"snapshot PR: #{state['snapshot_pr']}")
    published = state.get('published') or {}
    if published:
        print('\n已发布:')
        for short, info in published.items():
            print(f"  ✓ {short} {info.get('version')}")
    else:
        print('\n已发布: 无')
    if state.get('error'):
        print(f"\n最后错误: {state['error']}")
    return 0


def _plan_command(args) -> int:
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
        plan['blockers'] = [
            blocker for blocker in plan['blockers'] if not str(blocker).startswith('root:')
        ]
        plan['root']['action'] = 'skip'
        plan['root']['reason'] = '未在 --packages 中选择 root'
        plan['root']['requires'] = []
        plan['summary']['root'] = 'skip'

    if args.out:
        out = pathlib.Path(args.out)
        _write_json(out, plan)
        print(f'计划已写入 {out}（只读生成，未发布）')
    if args.json:
        print(json.dumps(plan, ensure_ascii=False, indent=2))
    else:
        print_human(plan)
    if args.check and plan['blockers']:
        return 1
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description='发布波次 plan / run / status')
    parser.add_argument('command', choices=['plan', 'run', 'resume', 'status'])
    parser.add_argument('--all', action='store_true', help='plan：所有 manifest 包 + 根包（默认）')
    parser.add_argument('--packages', help='plan：只计划这些包（逗号分隔；root 用 root）')
    parser.add_argument('--out', help='plan：把 JSON 计划写到文件')
    parser.add_argument('--json', action='store_true', help='plan/status：输出 JSON')
    parser.add_argument('--check', action='store_true', help='plan：有阻断时退出 1')
    parser.add_argument('--no-drift', action='store_true', help='plan：跳过同版本归档 CODE DRIFT 核对')
    parser.add_argument('--fetch', action='store_true', help='plan：先 git fetch origin main')
    parser.add_argument('--plan', dest='plan_file', help='run：plan 生成的 JSON 文件')
    parser.add_argument('--yes', action='store_true', help='run：确认执行（不可逆）')
    parser.add_argument('--dry-run', action='store_true', help='run：只跑 dry-run，不发布')
    parser.add_argument('--resume', action='store_true', help='run：从 state 断点继续')
    parser.add_argument('--wait-minutes', type=int, default=15, help='run：等 pub.dev 可见 / 验证超时（默认 15）')
    args = parser.parse_args()

    if args.command == 'plan':
        return _plan_command(args)
    if args.command == 'status':
        return _status(args)
    if args.command == 'resume':
        args.resume = True
    return _run(args)


if __name__ == '__main__':
    raise SystemExit(main())
