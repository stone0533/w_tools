#!/usr/bin/env python3
"""公开 API 变了就必须抬版本。

对比 PR base 与当前工作区的公开 API 表面（barrel 导出的类型 / 成员 / 签名）：

- 有变化 + pubspec 版本没变 → 失败（补版本号 + CHANGELOG）；
- 有变化 + 版本变了 → 通过（CHANGELOG 段 / semver 由 release_check 与 api diff 继续把关）；
- 包在 base 里不存在（新包）→ 跳过。

只用于 PR 门禁（需要 base 全历史）；本地浅克隆缺 base 时返回 2。
"""
from __future__ import annotations

import argparse
import io
import pathlib
import re
import subprocess
import sys
import tarfile
import tempfile

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from check_public_api_diff import api_surface  # noqa: E402

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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--base',
        default='origin/main',
        help='对比的 base ref（CI 用 PR base sha）；默认 origin/main',
    )
    parser.add_argument('--package', help='只检查一个包（debug 用）')
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

    packages = [args.package] if args.package else manifest_packages()
    errors: list[str] = []
    checked = 0
    for package in packages:
        current = api_surface(ROOT / 'packages' / package)
        base = base_surface(args.base, package)
        if base is None:
            continue  # 新包：base 里没有，版本从 0 开始，不需要对比
        old_version = base_version(args.base, package)
        new_version = current_version(package)
        if old_version is None or new_version is None:
            errors.append(f'{package}: 读不到 pubspec version（base={old_version}，当前={new_version}）')
            continue
        checked += 1
        changes = diff_surfaces(base, current)
        if not changes:
            continue
        if new_version != old_version:
            continue
        sample = '、'.join(sorted(changes)[:3])
        errors.append(
            f'{package}: 公开 API 有 {len(changes)} 处变化（{sample}…），'
            f'但版本仍是 {new_version}。请抬版本并写 CHANGELOG 段'
        )

    if errors:
        print('公开 API 变了但没有抬版本：', file=sys.stderr)
        for error in errors:
            print(f'  ✗ {error}', file=sys.stderr)
        return 1
    print(f'✓ 公开 API 变化的包都已抬版本（对比 {checked} 个包）')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
