#!/usr/bin/env python3
"""发布状态总表：本地版本 / 线上版本 / API 快照 / 结论。

回答两个问题：

- 哪些包待发布（本地 > 线上）——正常状态，不算错误；
- 哪些包异常（本地 < 线上、快照与线上不一致、缺快照）——`--check` 时失败。

用法：
    python3 scripts/release_status.py                 # 离线，只读 pubspec / 快照 / CHANGELOG
    python3 scripts/release_status.py --online        # 再查 pub.dev
    python3 scripts/release_status.py --online --check  # CI / weekly：异常时退出 1

退出码：
    0  通过（「待发布」是正常状态；网络失败只提示）
    1  「落后 / 快照与线上不一致 / 缺快照」（--check 时）
    2  线上一个包都没取到（网络不可达）；周检按「本次跳过」处理，不判发布事故
"""
from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys
import time
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
MANIFEST = ROOT / 'scripts/packages.manifest'
SNAPSHOTS = ROOT / 'scripts/api_snapshots'
PUB_API = 'https://pub.dev/api/packages/'


def read_manifest() -> list[tuple[str, str]]:
    rows: list[tuple[str, str]] = []
    for raw in MANIFEST.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        fields = line.split('|')
        rows.append((fields[0], fields[1]))
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


def snapshot_version(package: str) -> str | None:
    candidates = sorted(
        SNAPSHOTS.glob(f'w_tools_{package}-*.txt'),
        key=lambda path: version_tuple(path.stem.rsplit('-', 1)[-1]),
    )
    if not candidates:
        return None
    return candidates[-1].stem.rsplit('-', 1)[-1]


def fetch_latest(name: str) -> str | None:
    """取 pub.dev 最新版本；网络抖动重试 3 次，仍失败返回 None（由调用方决定如何降级）。"""
    last_error: Exception | None = None
    for attempt in range(3):
        try:
            with urllib.request.urlopen(PUB_API + name, timeout=10) as response:
                return json.load(response)['latest']['version']
        except (urllib.error.URLError, TimeoutError, KeyError, json.JSONDecodeError, OSError) as error:
            last_error = error
            if attempt < 2:
                time.sleep(1 + attempt)
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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--online', action='store_true', help='查 pub.dev 的线上版本')
    parser.add_argument('--check', action='store_true', help='异常（落后 / 快照不一致）时退出 1')
    parser.add_argument('--fail-pending', action='store_true', help='把「待发布」也算失败')
    args = parser.parse_args()

    constraints = root_constraints()
    rows: list[tuple[str, str, str | None, str | None, str]] = []
    errors: list[str] = []
    warnings: list[str] = []
    unreachable: list[str] = []
    online_ok = 0

    for name, path in read_manifest():
        package = name.removeprefix('w_tools_')
        package_dir = ROOT / path
        local = version_of(package_dir / 'pubspec.yaml') or '?'
        snapshot = snapshot_version(package)
        published = published_version(package) if args.online else None
        status = classify(local, published)
        rows.append((package, local, published, snapshot, status))

        if args.online and published is None:
            # 网络问题不是发布事故：每周 CI 不因此发失败邮件（全部取不到时由退出码 2 说明）。
            unreachable.append(package)
            continue
        if args.online:
            online_ok += 1
        if status == '落后':
            errors.append(f'{package}: 仓库 {local} < 线上 {published}，仓库落后')
        if status == '待发布' and args.fail_pending:
            errors.append(f'{package}: 仓库 {local} > 线上 {published}，待发布')
        if snapshot is None:
            errors.append(f'{package}: 缺 API 快照（scripts/api_snapshots）')
        elif published is not None and version_tuple(snapshot) != version_tuple(published):
            errors.append(
                f'{package}: API 快照 {snapshot} ≠ 线上 {published}——发布后记得提交快照'
            )
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

    root_local = version_of(ROOT / 'pubspec.yaml') or '?'
    root_published = fetch_latest('w_tools') if args.online else None
    if args.online and root_published is None:
        unreachable.append('w_tools')
    if root_published is not None:
        online_ok += 1
    rows.append(('w_tools(root)', root_local, root_published, '-', classify(root_local, root_published)))
    if args.online and root_published is not None and version_tuple(root_local) < version_tuple(root_published):
        errors.append(f'w_tools: 仓库 {root_local} < 线上 {root_published}，仓库落后')

    header = ('包', '本地', '线上', '快照', '结论')
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
    print('\n状态正常' if args.check else '')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
