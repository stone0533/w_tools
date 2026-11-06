#!/usr/bin/env python3
"""检查子包与根 README 的安装约束与 example 链接。

安装版本按 **caret 语义**校验，不是只比 major：
`^1.0.0` 不接受 1.9.10 这种“major 对但下界落后”的写法，用户照抄会装到旧版。

根 README 是用户第一入口，它的 `w_tools*: ^x.y.z` 示例同样对着 pubspec 校验 ——
历史上这里漏过 `w_tools: ^7.0.0`（实际已 9.x）。
"""
from __future__ import annotations

import pathlib
import re
import sys
import yaml

root = pathlib.Path(__file__).resolve().parent.parent
errors: list[str] = []


def numbers(raw: str) -> tuple[int, ...]:
    return tuple(int(part) for part in re.findall(r'\d+', raw))


def caret_allows(constraint: tuple[int, ...], version: tuple[int, ...]) -> bool:
    """^X.Y.Z 的语义：>= 下界、且不进下一个 breaking 段。"""
    lower = constraint + (0,) * (3 - len(constraint))
    current = version + (0,) * (3 - len(version))
    if current < lower:
        return False
    if lower[0] > 0:
        return current[0] == lower[0]
    if lower[1] > 0:
        return current[:2] == lower[:2]
    return current[:2] == (0, 0)


root_pubspec = yaml.safe_load((root / 'pubspec.yaml').read_text())
versions: dict[str, str] = {root_pubspec['name']: str(root_pubspec.get('version', ''))}

for pubspec in sorted((root / 'packages').glob('*/pubspec.yaml')):
    data = yaml.safe_load(pubspec.read_text())
    name = data.get('name')
    version_raw = str(data.get('version', ''))
    package_dir = pubspec.parent
    readme = package_dir / 'README.md'
    if not name:
        continue
    versions[name] = version_raw
    if not readme.exists():
        errors.append(f'{package_dir.name}: 缺 README.md')
        continue
    text = readme.read_text()
    if version_raw:
        install = re.search(rf'{re.escape(name)}\s*:\s*\^(\d+(?:\.\d+)*)', text)
        if install:
            constraint = numbers(install.group(1))
            current = numbers(version_raw)
            if not caret_allows(constraint, current):
                errors.append(
                    f'{package_dir.name}: README 安装约束 ^{install.group(1)} '
                    f'不接受 pubspec 当前版本 {version_raw}',
                )
    example = package_dir / 'example'
    if example.is_dir() and not re.search(r'example|示例', text, re.I):
        errors.append(f'{package_dir.name}: 有 example，但 README 没提到示例')

# 根 README 的安装示例：`w_tools*: ^x.y.z` 必须接受该包 pubspec 的当前版本。
root_readme = root / 'README.md'
seen: set[str] = set()
for match in re.finditer(
    r'^\s*(w_tools(?:_[A-Za-z0-9_]+)?)\s*:\s*\^(\d+(?:\.\d+)*)',
    root_readme.read_text(),
    re.M,
):
    name, constraint_raw = match.group(1), match.group(2)
    key = f'{name}^{constraint_raw}'
    if key in seen:
        continue
    seen.add(key)
    if name not in versions:
        errors.append(f'README.md: 安装示例引用了未知包 {name}')
        continue
    current = versions[name]
    if not caret_allows(numbers(constraint_raw), numbers(current)):
        errors.append(
            f'README.md: {name} 安装约束 ^{constraint_raw} 不接受当前版本 {current}',
        )

if errors:
    for error in errors:
        print(f'✗ {error}', file=sys.stderr)
    sys.exit(1)
print('子包 / 根 README 安装约束与 example 链接检查通过')
