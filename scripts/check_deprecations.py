#!/usr/bin/env python3
"""弃用到期检查：每个 @Deprecated 都要有 remove-in，到期必须删。

约定写在 `@Deprecated` 紧邻上方的注释块里：

    /// remove-in: 4.0.0
    @Deprecated('Use WTextStyles instead')

- 缺 `remove-in`：错误（阻断），必须补上到期版本；
- 包当前版本 >= remove-in：错误（阻断），该删除或改期。

为什么需要它：`WConfig.assetImagePath` 的注释写「下个大版本移除」，跨过 3.0 仍在
（2026-11 评审 P2-8）。弃用没有到期，就永远不会被删；有到期而不检查，同样等于没有。

规则只认「紧贴声明的连续注释块」：以前在 `index±8` 的全窗口里找第一个 `remove-in`，
相邻的两条弃用会互借到期版本，漏写的那条就永远不报错（2026-11-07 二轮审计 P1-5）。
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

# 紧邻 @Deprecated 的注释 / 注解都算同一个块；空行或代码行结束这个块。
BLOCK_PREFIXES = ('///', '//', '@')


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


def find_remove_in(lines: list[str], index: int) -> tuple[int, int, int] | None:
    """从 @Deprecated 所在行向上找紧邻注释块里的 remove-in。

    只在连续注释 / 注解块里找：遇到空行或代码行就停。这样相邻两条弃用不会互借。
    """
    for offset in range(1, window + 1):
        position = index - offset
        if position < 0:
            break
        stripped = lines[position].strip()
        if not stripped:
            break
        match = remove_in_re.search(stripped)
        if match:
            return tuple(int(part) for part in match.groups())
        if not stripped.startswith(BLOCK_PREFIXES):
            break
    return None


def check_file(path: pathlib.Path, version: tuple[int, int, int], errors: list[str]) -> None:
    lines = path.read_text().splitlines()
    rel = path.relative_to(root)
    for index, line in enumerate(lines):
        if '@Deprecated' not in line:
            continue

        target = find_remove_in(lines, index)
        member = declaration_after(lines, index)

        if target is None:
            errors.append(f'{rel}:{index + 1} 缺 remove-in（{member or "?"}）')
        elif version >= target:
            wanted = '.'.join(str(part) for part in target)
            current = '.'.join(str(part) for part in version)
            errors.append(
                f'{rel}:{index + 1} remove-in {wanted} 已到期（当前 {current}），'
                f'请删除或改期：{member or "?"}'
            )


def main() -> int:
    errors: list[str] = []

    for pubspec in sorted(packages.glob('*/pubspec.yaml')):
        package = pubspec.parent.name
        version_raw = version_re.search(pubspec.read_text())
        version = parse_version(version_raw.group(1)) if version_raw else None
        if version is None:
            # 读不到版本时到期判断会整包空转（以前直接 continue，门禁静默失效）。
            errors.append(f'packages/{package}/pubspec.yaml: 读不到合法 version')
            continue

        lib = pubspec.parent / 'lib'
        if not lib.is_dir():
            continue

        for path in sorted(lib.rglob('*.dart')):
            if path.name.endswith('.g.dart'):
                continue
            check_file(path, version, errors)

    for error in errors:
        print(f'  ✗ {error}')

    if not errors:
        print('  ✓ 弃用项都有到期版本，且没有到期未删的')

    return 1 if errors else 0


if __name__ == '__main__':
    raise SystemExit(main())
