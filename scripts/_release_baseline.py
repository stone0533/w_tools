#!/usr/bin/env python3
"""单包发布前的 API 快照基线检查。

两个入口共用同一份判定，避免 `release_check --package` 与 `publish_package.sh`
各写一套后语义漂移：

- `--mode check`：给 `release_check --package` 用。快照高于本地 → 1；
  等于 / 缺失 → 10 / 11（调用方按 warn 处理）；低于本地 → 0。
- `--mode publish`：给 `publish_package.sh` 用。只有「本地高于快照」或
  「新包首发（无快照且在 pending_first_release.txt）」放行；其余 1。

退出码 10 / 11 是「警告但不算失败」，方便 shell 调用方区分 ok / warn / fail。
"""
from __future__ import annotations

import argparse
import sys

from release_status import (
    git_tracked,
    pending_first_release,
    snapshot_path,
    snapshot_version,
    version_tuple,
)

WARN_EQUAL = 10
WARN_MISSING = 11


def baseline(package: str, local_version: str, *, mode: str) -> tuple[int, str]:
    """返回 (退出码, 一行说明)。不打印，方便单测。"""
    latest = snapshot_version(package)
    pending = package in pending_first_release()

    if latest is None:
        if mode == 'publish':
            if pending:
                return 0, f'{package}: 新包首发，暂无 API 快照（publish 守卫放行）'
            return 1, (
                f'{package}: 没有 API 快照，也不在 scripts/pending_first_release.txt；'
                '已有包说明基线丢失，新包首发请先登记'
            )
        return WARN_MISSING, (
            f'{package}: 没有 API 快照——新包首发请确认 scripts/pending_first_release.txt；'
            'publish 脚本会 fail-closed'
        )

    latest_parts = version_tuple(latest)
    local_parts = version_tuple(local_version)
    if latest_parts > local_parts:
        return 1, (
            f'{package}: API 快照 {latest} 高于本地版本 {local_version}'
            '（版本回退 / 基线异常）'
        )

    if mode == 'publish':
        path = snapshot_path(package)
        if path is None or not git_tracked(path):
            return 1, (
                f'{package}: 最新 API 快照未提交（scripts/api_snapshots）——'
                'untracked 快照会在 reset --hard 后丢失'
            )
        if latest_parts == local_parts and not pending:
            return 1, (
                f'{package}: 本地版本 {local_version} 已经是快照基线'
                '（通常是已发布版本）；请抬版本，或确认是否误操作'
            )
        if latest_parts == local_parts:
            return 0, f'{package}: 新包首发且已有快照，放行'
        return 0, f'{package}: API 快照 {latest} 低于本地 {local_version}（待发布）'

    if latest_parts == local_parts:
        return WARN_EQUAL, (
            f'{package}: API 快照已等于本地版本 {local_version}'
            '（可能已发布；重发会被 publish 守卫拦住）'
        )
    return 0, f'{package}: API 快照 {latest} 低于本地 {local_version}（待发布）'


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--package', required=True, help='manifest 裸名，如 ui')
    parser.add_argument('--version', required=True, help='本地 pubspec 版本')
    parser.add_argument('--mode', choices=('check', 'publish'), default='check')
    args = parser.parse_args()
    code, message = baseline(args.package, args.version, mode=args.mode)
    if code in (0, WARN_EQUAL, WARN_MISSING):
        print(message)
    else:
        print(message, file=sys.stderr)
    return code


if __name__ == '__main__':
    raise SystemExit(main())
