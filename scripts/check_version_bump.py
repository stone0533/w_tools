#!/usr/bin/env python3
"""公开 API 变了就必须抬版本。

对比 PR 的 **merge-base**（`git merge-base <base> HEAD`）与当前工作区的公开 API 表面
（barrel 导出的类型 / 成员 / 签名）：

- 有变化 + pubspec 版本没变 → 失败（补版本号 + CHANGELOG）；
- 有变化 + 版本已经领先已发布基线 → 通过（CHANGELOG 段 / semver 由 release_check 与
  api diff 继续把关）；
- 版本降级 / 版本不高于已发布基线 → 失败（已发布版本不可回滚）；
- 包在 merge-base 里不存在（新包）→ 跳过；
- 根包 `lib/w_tools.dart` 的 export 行有变化 → 根包版本必须高于 base（根包没有
  barrel 目录，单独检查；`--package w_tools` 可以只跑这一项）。

已发布基线默认取仓库快照；`--online` 时先查 pub.dev（CI 的 api-bump 用这个），
取不到才回退到快照并打印提醒 —— 快照可能滞后一个版本（批量发布窗口），
那时把「已发布版本」当成未发布会让删除线上 API 的改动通过。

只用于 PR 门禁（需要 base 全历史）；本地浅克隆缺 base 时返回 2。
"""
from __future__ import annotations

import argparse
import io
import json
import pathlib
import re
import subprocess
import sys
import tarfile
import tempfile
import urllib.error
import urllib.request

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from check_public_api_diff import NO_PUBLIC_API, api_surface, latest_snapshot_version  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
MANIFEST = ROOT / 'scripts/packages.manifest'


def manifest_packages() -> list[str]:
    packages: list[str] = []
    for raw in MANIFEST.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        packages.append(line.split('|')[0].removeprefix('w_tools_'))
    return packages


def _git_show(ref: str, path: str) -> str | None:
    result = subprocess.run(
        ['git', 'show', f'{ref}:{path}'],
        capture_output=True,
        text=True,
        cwd=ROOT,
    )
    return result.stdout if result.returncode == 0 else None


def base_version(ref: str, package: str) -> str | None:
    text = _git_show(ref, f'packages/{package}/pubspec.yaml')
    if text is None:
        return None
    return _parse_version(text)


def current_version(package: str) -> str | None:
    path = ROOT / 'packages' / package / 'pubspec.yaml'
    if not path.exists():
        return None
    return _parse_version(path.read_text())


def _parse_version(text: str) -> str | None:
    match = re.search(r'(?m)^version:\s*(\S+)', text)
    return match.group(1) if match else None


def merge_base(ref: str) -> str | None:
    """PR 真正的分叉点。

    不能用 `github.event.pull_request.base.sha` 直接当对比点：它是 base 分支的
    **当前 tip**，可能已经包含其它已合并 PR 的改动。拿它做 diff 会把别人的改动
    算到本 PR 头上（false positive），也可能因为 base 版本已经变了而漏掉本 PR
    该抬的版本（false negative，三轮审计 P1-2）。
    """
    result = subprocess.run(
        ['git', 'merge-base', ref, 'HEAD'],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return None
    return result.stdout.strip() or None


def base_has_package(ref: str, package: str) -> bool:
    """base 里到底有没有这个包。

    不能用 `base_surface(...) is None` 判断：archive 失败 / 浅克隆缺对象也会返回 None，
    那样会把已存在的包当成新包，版本门禁静默消失（二轮审计 P1-4）。
    """
    result = subprocess.run(
        ['git', 'cat-file', '-e', f'{ref}:packages/{package}/pubspec.yaml'],
        cwd=ROOT,
        capture_output=True,
    )
    return result.returncode == 0


def base_surface(ref: str, package: str) -> dict[str, str] | None:
    result = subprocess.run(
        ['git', 'archive', f'{ref}:packages/{package}'],
        capture_output=True,
        cwd=ROOT,
    )
    if result.returncode != 0 or not result.stdout:
        return None
    with tempfile.TemporaryDirectory() as temp:
        with tarfile.open(fileobj=io.BytesIO(result.stdout)) as archive:
            archive.extractall(temp)
        return api_surface(pathlib.Path(temp))


PUB_API = 'https://pub.dev/api/packages/'


def published_version(package: str, online: bool, warnings: list[str]) -> str | None:
    """已发布版本：默认用仓库快照；`--online` 时以 pub.dev 为准（取不到回退快照）。"""
    snapshot = latest_snapshot_version(package)
    if not online:
        return snapshot
    try:
        with urllib.request.urlopen(PUB_API + f'w_tools_{package}', timeout=5) as response:
            return json.load(response)['latest']['version']
    except (urllib.error.URLError, TimeoutError, OSError, KeyError, json.JSONDecodeError) as error:
        warnings.append(
            f'{package}: 取不到 pub.dev 版本（{error}），'
            f'按仓库快照 {snapshot or "无"} 判断（快照可能滞后）'
        )
        return snapshot


def diff_surfaces(
    base: dict[str, str], current: dict[str, str]
) -> dict[str, tuple[str | None, str | None]]:
    changes: dict[str, tuple[str | None, str | None]] = {}
    for key in set(base) | set(current):
        old = base.get(key)
        new = current.get(key)
        if old != new:
            changes[key] = (old, new)
    return changes


def release_parts(raw: str) -> tuple[int, ...]:
    """major.minor.patch，忽略 pre-release / build 后缀。

    不能复用 `_version_tuple` 的数字列表：`1.0.0-dev.1` 会变成 `(1, 0, 0, 1)`，
    比 `1.0.0` 还大。这里只比较 release 段，pre-release → release 不会被误判为降级。
    """
    parts = [int(part) for part in re.findall(r'\d+', raw)[:3]]
    while len(parts) < 3:
        parts.append(0)
    return tuple(parts)


def requires_bump(
    new_version: str,
    base_version: str,
    published_version: str | None,
) -> bool:
    """本次 API 变化是否必须再抬版本号。

    - 版本降级（release 段变小）→ 必须失败；
    - `new` 不高于已发布基线 → 必须失败（已发布版本不可回滚 / 不可重发）；
    - `new == base` 且没有已发布基线 → 必须失败（无法证明落在未发布版本里）；
    - 其余情况（已经抬过且高于已发布基线）→ 放行。

    只比 base 版本号会把「已经抬过但还没发布」的版本误判成没抬（docs/releasing.md §发版步骤
    说「功能 PR 里已经抬过就沿用」）；而只看 `new != base` 又会放过降级。两者都要防。
    """
    new = release_parts(new_version)
    base = release_parts(base_version)
    if new < base:
        return True
    if published_version is not None and new <= release_parts(published_version):
        return True
    if new == base:
        return published_version is None
    return False


EXPORT_LINE = re.compile(r"""(?m)^\s*export\s+['"]([^'"]+)['"]""")


def root_export_surface(text: str) -> list[str]:
    """根包 barrel 的 re-export 目标（排序后比较，顺序变化不算 API 变化）。"""
    return sorted(EXPORT_LINE.findall(text))


def root_requires_bump(
    base_exports: list[str],
    current_exports: list[str],
    base_version: str,
    new_version: str,
) -> bool:
    """根包 export 变化时，版本是否必须高于 base。"""
    if sorted(base_exports) == sorted(current_exports):
        return False
    return release_parts(new_version) <= release_parts(base_version)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--base',
        default='origin/main',
        help='对比的 base ref（CI 用 PR base sha）；实际对比 merge-base；默认 origin/main',
    )
    parser.add_argument('--package', help='只检查一个包（debug 用）')
    parser.add_argument(
        '--online',
        action='store_true',
        help='用 pub.dev 最新版本当已发布基线（取不到时回退到仓库快照并提醒）',
    )
    args = parser.parse_args()

    if subprocess.run(
        ['git', 'rev-parse', '--verify', '--quiet', args.base],
        cwd=ROOT,
        capture_output=True,
    ).returncode != 0:
        print(
            f'找不到 base ref：{args.base}。浅克隆请先 fetch 全历史，'
            '或显式传 --base <sha>（CI 用 actions/checkout fetch-depth: 0）。',
            file=sys.stderr,
        )
        return 2

    base_ref = merge_base(args.base)
    if base_ref is None:
        print(
            f'无法计算 {args.base} 与 HEAD 的 merge-base；请确认 base 存在且历史完整。',
            file=sys.stderr,
        )
        return 2

    packages = [] if args.package == 'w_tools' else ([args.package] if args.package else manifest_packages())
    errors: list[str] = []
    warnings: list[str] = []
    skipped: list[str] = []
    new_packages: list[str] = []
    pending: list[str] = []
    checked = 0
    for package in packages:
        current = api_surface(ROOT / 'packages' / package)
        if not current:
            if package in NO_PUBLIC_API:
                skipped.append(package)
                continue
            errors.append(
                f'{package}: 解析不到公开 API（lib/ 下缺 w_tools_*.dart barrel），'
                '版本门禁会空转；补 barrel 或登记到 check_public_api_diff.NO_PUBLIC_API'
            )
            continue
        if not base_has_package(base_ref, package):
            new_packages.append(package)
            continue
        base = base_surface(base_ref, package)
        if base is None:
            # base 里有这个包、却读不出 API：不能当成新包跳过（版本门禁会静默消失）。
            errors.append(
                f'{package}: 读不到 base 里的公开 API（git archive 失败）；'
                '请确认 fetch 完整历史后重跑'
            )
            continue
        old_version = base_version(base_ref, package)
        new_version = current_version(package)
        if old_version is None or new_version is None:
            errors.append(f'{package}: 读不到 pubspec version（base={old_version}，当前={new_version}）')
            continue
        checked += 1
        changes = diff_surfaces(base, current)
        if not changes:
            continue
        published = published_version(package, args.online, warnings)
        if not requires_bump(new_version, old_version, published):
            if new_version == old_version and published is not None:
                pending.append(f'{package} {new_version}')
            continue
        sample = '、'.join(sorted(changes)[:3])
        errors.append(
            f'{package}: 公开 API 有 {len(changes)} 处变化（{sample}…），'
            f'但版本 {new_version} 没有高于已发布基线 {published or "无"}'
            f'（base {old_version}）。请抬版本并写 CHANGELOG 段'
        )

    checked_root = 0
    if args.package in (None, 'w_tools'):
        current_root = ROOT / 'lib/w_tools.dart'
        base_root = _git_show(base_ref, 'lib/w_tools.dart')
        if not current_root.is_file():
            if args.package == 'w_tools':
                errors.append('w_tools: 缺 lib/w_tools.dart，根包版本门禁无法执行')
        elif base_root is None:
            if args.package == 'w_tools':
                errors.append('w_tools: base 里读不到 lib/w_tools.dart，根包版本门禁无法执行')
        else:
            checked_root = 1
            base_exports = root_export_surface(base_root)
            current_exports = root_export_surface(current_root.read_text())
            old_root_version = _parse_version(_git_show(base_ref, 'pubspec.yaml') or '')
            new_root_version = _parse_version((ROOT / 'pubspec.yaml').read_text())
            if old_root_version is None or new_root_version is None:
                errors.append(
                    'w_tools: 读不到根包 pubspec version'
                    f'（base={old_root_version}，当前={new_root_version}）'
                )
            elif root_requires_bump(
                base_exports,
                current_exports,
                old_root_version,
                new_root_version,
            ):
                errors.append(
                    'w_tools: 根包 re-export 有变化，但版本 '
                    f'{new_root_version} 没有高于 base {old_root_version}。'
                    '请抬根包版本并写 CHANGELOG 段'
                )

    if errors:
        print('公开 API 变了但没有抬版本：', file=sys.stderr)
        for error in errors:
            print(f'  ✗ {error}', file=sys.stderr)
        return 1
    if pending:
        print(f'✓ 公开 API 变化落在未发布版本里：{"、".join(pending)}')
    for warning in warnings:
        print(f'  ! {warning}')
    if new_packages:
        print(f'! base 里没有这些包（新包，跳过对比）：{"、".join(new_packages)}')
    if skipped:
        print(f'! 无 barrel 公开 API，已跳过：{"、".join(skipped)}')
    root_note = ' + 根包' if checked_root else ''
    print(f'✓ 公开 API 变化的包都已抬版本（对比 {checked} 个包{root_note}）')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
