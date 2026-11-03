#!/usr/bin/env python3
"""弃用到期检查：每个 @Deprecated 都要有 remove-in，到期必须删。

约定写在 `@Deprecated` 前后 8 行的注释里：

    /// remove-in: 4.0.0
    @Deprecated('Use WTextStyles instead')

- 缺 `remove-in`：错误（阻断），必须补上到期版本；
- 包当前版本 >= remove-in：错误（阻断），该删除或改期。

为什么需要它：`WConfig.assetImagePath` 的注释写「下个大版本移除」，跨过 3.0 仍在
（2026-11 评审 P2-8）。弃用没有到期，就永远不会被删；有到期而不检查，同样等于没有。
"""
from __future__ import annotations

import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
packages = root / 'packages'

version_re = re.compile(r'^version:[ \t]*(\S+)', re.MULTILINE)
remove_in_re = re.compile(r'remove-in:\s*(\d+)\.(\d+)\.(\d+)')
window = 8

errors: list[str] = []
warnings: list[str] = []


def parse_version(raw: str) -> tuple[int, int, int] | None:
    match = re.match(r'(\d+)\.(\d+)\.(\d+)', raw)
    if not match:
        return None
    return tuple(int(part) for part in match.groups())  # type: ignore[return-value]


def declaration_after(lines: list[str], index: int) -> str:
    """取 @Deprecated 之后的声明行，用于报错时指出是哪个成员。"""
    for line in lines[index + 1 : index + window + 1]:
        stripped = line.strip()
        if not stripped or stripped.startswith(('///', '//', '@', ')')):
            continue
        return stripped[:96]
    return ''


for pubspec in sorted(packages.glob('*/pubspec.yaml')):
    package = pubspec.parent.name
    version_raw = version_re.search(pubspec.read_text())
    version = parse_version(version_raw.group(1)) if version_raw else None
    if version is None:
        continue

    lib = pubspec.parent / 'lib'
    if not lib.is_dir():
        continue

    for path in sorted(lib.rglob('*.dart')):
        if path.name.endswith('.g.dart'):
            continue
        lines = path.read_text().splitlines()
        for index, line in enumerate(lines):
            if '@Deprecated' not in line:
                continue

            lo, hi = max(0, index - window), min(len(lines), index + window + 1)
            target = None
            for candidate in lines[lo:hi]:
                match = remove_in_re.search(candidate)
                if match:
                    target = tuple(int(part) for part in match.groups())
                    break

            rel = path.relative_to(root)
            member = declaration_after(lines, index)

            if target is None:
                errors.append(f'{rel}:{index + 1} 缺 remove-in（{member or "?"}）')
            elif version >= target:
                wanted = '.'.join(str(part) for part in target)
                current = '.'.join(str(part) for part in version)
                errors.append(
                    f'{rel}:{index + 1} remove-in {wanted} 已到期（当前 {current}），请删除或改期：{member or "?"}'
                )

for warning in warnings:
    print(f'  ! {warning}')
for error in errors:
    print(f'  ✗ {error}')

if not errors and not warnings:
    print('  ✓ 弃用项都有到期版本，且没有到期未删的')

sys.exit(1 if errors else 0)
