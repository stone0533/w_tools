#!/usr/bin/env python3
"""发布状态总表：本地版本 / 线上版本 / API 快照 / 结论。

回答两个问题：

- 哪些包待发布（本地 > 线上）——正常状态，不算错误；
- 哪些包异常（本地 < 线上、快照与线上不一致、缺快照）——`--check` 时失败。

离线结构检查（不查 pub.dev）：
    python3 scripts/release_status.py --quiet --check --require-tracked --require-local
用于发布前确认「每个包的最新快照已提交，且版本等于本地 pubspec」。

用法：
    python3 scripts/release_status.py                 # 离线，只读 pubspec / 快照 / CHANGELOG
    python3 scripts/release_status.py --online        # 再查 pub.dev
    python3 scripts/release_status.py --online --check  # CI / weekly：异常时退出 1

退出码：
    0  通过（「待发布」是正常状态；网络失败只提示）
    1  「落后 / 快照与线上不一致 / 缺快照 / pub.dev 404」（--check 时）
    2  线上一个包都没取到（网络不可达）；周检按「本次跳过」处理，不判发布事故
    3  用法错误：`--check` 没带 `--online` / `--require-*`（没有可核对的目标）
"""
from __future__ import annotations

import argparse
import json
import pathlib
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
MANIFEST = ROOT / 'scripts/packages.manifest'
SNAPSHOTS = ROOT / 'scripts/api_snapshots'
PUB_API = 'https://pub.dev/api/packages/'

# `w_tools_<pkg>-<version>.txt`；版本允许预发布后缀（`8.0.0-dev.1`）。
SNAPSHOT_NAME = re.compile(
    r'^w_tools_(?P<package>.+?)-(?P<version>\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?)\.txt$'
)


class PackageNotFound(Exception):
    """pub.dev 明确返回 404：包名拼错 / 改名 / 从未发布（不是网络问题）。"""


def read_manifest(path: pathlib.Path | None = None) -> list[tuple[str, str, str]]:
    """(包名, 目录, root_aggregate)。第三列决定 `--require-local` 是否适用。"""
    manifest = path or MANIFEST
    rows: list[tuple[str, str, str]] = []
    for raw in manifest.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        fields = line.split('|')
        aggregate = fields[3] if len(fields) > 3 else '-'
        rows.append((fields[0], fields[1], aggregate))
    return rows


def version_of(path: pathlib.Path) -> str | None:
    if not path.exists():
        return None
    match = re.search(r'(?m)^version:\s*(\S+)', path.read_text())
    return match.group(1) if match else None


def changelog_first(path: pathlib.Path) -> str | None:
    """第一个版本段（跳过 `## Unreleased` 与标题）。"""
    if not path.exists():
        return None
    for line in path.read_text().splitlines():
        match = re.match(r'^##\s+(\S+)', line)
        if match:
            if match.group(1).lower() == 'unreleased':
                continue
            return match.group(1)
    return None


def version_tuple(text: str) -> tuple[int, ...]:
    return tuple(int(part) for part in re.findall(r'\d+', text))


def snapshot_version_of(path: pathlib.Path) -> str:
    match = SNAPSHOT_NAME.match(path.name)
    return match.group('version') if match else path.stem.rsplit('-', 1)[-1]


def snapshot_path(package: str) -> pathlib.Path | None:
    """最新快照文件（按版本号排序取最大）；没有返回 None。"""
    candidates = sorted(
        SNAPSHOTS.glob(f'w_tools_{package}-*.txt'),
        key=lambda path: version_tuple(snapshot_version_of(path)),
    )
    return candidates[-1] if candidates else None


def snapshot_version(package: str) -> str | None:
    path = snapshot_path(package)
    return snapshot_version_of(path) if path is not None else None


def git_tracked(path: pathlib.Path) -> bool:
    """快照文件是否已被 git 跟踪（untracked 的文件会在 reset/clean 后丢失）。"""
    result = subprocess.run(
        ['git', 'ls-files', '--error-unmatch', '--', str(path.relative_to(ROOT))],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    return result.returncode == 0


def fetch_latest(name: str) -> str | None:
    """取 pub.dev 最新版本；网络抖动重试，仍失败返回 None（由调用方决定如何降级）。

    404 单独抛 PackageNotFound：包名拼错 / 改名不是网络问题，不能按「未核对」跳过。
    """
    last_error: Exception | None = None
    for attempt in range(2):
        try:
            with urllib.request.urlopen(PUB_API + name, timeout=5) as response:
                return json.load(response)['latest']['version']
        except urllib.error.HTTPError as error:
            if error.code == 404:
                raise PackageNotFound(name) from error
            last_error = error
        except (urllib.error.URLError, TimeoutError, KeyError, json.JSONDecodeError, OSError) as error:
            last_error = error
        if attempt < 1:
            time.sleep(1)
    if last_error is not None:
        print(f'  （{name}: 取 pub.dev 失败：{last_error}）', file=sys.stderr)
    return None


def published_version(package: str) -> str | None:
    return fetch_latest(f'w_tools_{package}')


def root_constraints() -> dict[str, str]:
    text = (ROOT / 'pubspec.yaml').read_text()
    return {
        name: value.strip()
        for name, value in re.findall(
            r'(?m)^\s+(w_tools_[a-z_]+):\s*(\S+)\s*$', text
        )
    }


def classify(local: str, published: str | None) -> str:
    if published is None:
        return '未核对'
    if version_tuple(local) > version_tuple(published):
        return '待发布'
    if version_tuple(local) < version_tuple(published):
        return '落后'
    return '已发布'


def local_snapshot_errors(
    package: str, aggregate: str, snapshot: str, local: str
) -> list[str]:
    """`--require-local` 的判定：只有根聚合包必须快照 == 本地版本。

    工具包 / 不聚合的包允许领先快照（待发布），否则一次 cli / qr 的版本抬升
    会把下一次根包发布卡住（二轮审计 P2-4）。
    """
    if version_tuple(snapshot) == version_tuple(local):
        return []
    if aggregate == 'root':
        return [
            f'{package}: API 快照 {snapshot} ≠ 本地版本 {local}——'
            '先发布子包并提交快照，再发根包'
        ]
    if version_tuple(snapshot) > version_tuple(local):
        return [
            f'{package}: API 快照 {snapshot} 高于本地版本 {local}——'
            '快照比代码新，检查是否回退过版本'
        ]
    return []


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--online', action='store_true', help='查 pub.dev 的线上版本')
    parser.add_argument('--check', action='store_true', help='异常（落后 / 快照不一致）时退出 1')
    parser.add_argument('--fail-pending', action='store_true', help='把「待发布」也算失败')
    parser.add_argument('--quiet', action='store_true', help='只在异常时输出，不打印状态表')
    parser.add_argument(
        '--require-tracked',
        action='store_true',
        help='离线检查：最新快照必须已被 git 跟踪（发布根包前用）',
    )
    parser.add_argument(
        '--require-local',
        action='store_true',
        help='离线检查：根聚合包的最新快照版本必须等于本地 pubspec 版本（工具包 / 不聚合的包不参与）',
    )
    args = parser.parse_args()

    structural = args.require_tracked or args.require_local
    if args.check and not args.online and not structural:
        print(
            '✗ --check 需要 --online（线上核对），'
            '或加 --require-tracked / --require-local 做离线快照检查',
            file=sys.stderr,
        )
        return 3

    constraints = root_constraints()
    rows: list[tuple[str, str, str | None, str | None, str]] = []
    errors: list[str] = []
    warnings: list[str] = []
    unreachable: list[str] = []
    not_found: list[str] = []
    online_ok = 0

    for name, path, aggregate in read_manifest():
        package = name.removeprefix('w_tools_')
        package_dir = ROOT / path
        local = version_of(package_dir / 'pubspec.yaml') or '?'
        snapshot_file = snapshot_path(package)
        snapshot = snapshot_version_of(snapshot_file) if snapshot_file else None
        published = None
        if args.online:
            try:
                published = published_version(package)
            except PackageNotFound:
                not_found.append(package)
        status = classify(local, published)
        rows.append((package, local, published, snapshot, status))

        # 结构检查不依赖线上版本：网络不可达时也要能验证「快照存在 / 已提交 / 版本一致」。
        if snapshot is None:
            errors.append(f'{package}: 缺 API 快照（scripts/api_snapshots）')
        else:
            if args.require_tracked and not git_tracked(snapshot_file):
                errors.append(
                    f'{package}: API 快照 {snapshot_file.name} 未提交——'
                    '先合入快照 PR（untracked 快照会被 reset / clean 丢掉）'
                )
            if args.require_local:
                errors.extend(local_snapshot_errors(package, aggregate, snapshot, local))
            if published is not None and version_tuple(snapshot) != version_tuple(published):
                errors.append(
                    f'{package}: API 快照 {snapshot} ≠ 线上 {published}——发布后记得提交快照'
                )

        if args.online and published is None:
            if package in not_found:
                continue  # 404 已单独记错误，不再算「环境不可用」
            # 网络问题不是发布事故：每周 CI 不因此发失败邮件（全部取不到时由退出码 2 说明）。
            unreachable.append(package)
            continue
        if args.online:
            online_ok += 1
        if status == '落后':
            errors.append(f'{package}: 仓库 {local} < 线上 {published}，仓库落后')
        if status == '待发布' and args.fail_pending:
            errors.append(f'{package}: 仓库 {local} > 线上 {published}，待发布')
        first = changelog_first(package_dir / 'CHANGELOG.md')
        if first != local:
            warnings.append(f'{package}: CHANGELOG 首段是 {first}，pubspec 是 {local}')
        constraint = constraints.get(name)
        if constraint and constraint.startswith('^'):
            lower = constraint[1:]
            if version_tuple(local) > version_tuple(lower):
                warnings.append(
                    f'{package}: 根约束 {constraint} 下界低于子包 {local}（--strict 会失败）'
                )

    for package in not_found:
        errors.append(
            f'{package}: pub.dev 没有 w_tools_{package}（404）——包名拼错 / 改名 / 从未发布'
        )

    root_local = version_of(ROOT / 'pubspec.yaml') or '?'
    root_published = None
    root_missing = False
    if args.online:
        try:
            root_published = fetch_latest('w_tools')
        except PackageNotFound:
            root_missing = True
            errors.append('w_tools: pub.dev 上没有这个包（404）——包名拼错 / 从未发布')
    if args.online and root_published is None and not root_missing:
        unreachable.append('w_tools')
    if root_published is not None:
        online_ok += 1
    rows.append(('w_tools(root)', root_local, root_published, '-', classify(root_local, root_published)))
    if args.online and root_published is not None and version_tuple(root_local) < version_tuple(root_published):
        errors.append(f'w_tools: 仓库 {root_local} < 线上 {root_published}，仓库落后')

    header = ('包', '本地', '线上', '快照', '结论')
    if not args.quiet:
        print('  '.join(header))
        for row in rows:
            print('  '.join('-' if value is None else str(value) for value in row))

        pending = [row[0] for row in rows if row[4] == '待发布']
        if pending:
            print(f'\n待发布（正常）：{" ".join(pending)}')
        if unreachable:
            print(f'\n未核对（取不到 pub.dev，按环境问题处理）：{" ".join(unreachable)}')
        if warnings:
            print('\n提醒：')
            for warning in warnings:
                print(f'  ! {warning}')
    if errors:
        print('\n异常：', file=sys.stderr)
        for error in errors:
            print(f'  ✗ {error}', file=sys.stderr)
        if args.check:
            return 1
    if args.online and online_ok == 0:
        print(
            '\n✗ 一个包都没取到 pub.dev 版本，本次线上核对没有执行（退出码 2）',
            file=sys.stderr,
        )
        return 2
    if args.check and not args.quiet:
        print('\n状态正常' if args.online else '\n离线快照检查通过（线上未核对）')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
