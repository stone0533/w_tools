#!/usr/bin/env python3
"""检查当前文档里的 `w_tools*: ^x.y.z` 安装示例与 example 链接。

规则：**安装示例的下界必须等于仓库当前版本**，不能只保证 caret 区间能接受当前版本。
`^1.0.0` 对当前 1.9.10 是合法的 caret，但用户照抄会装到旧版；这类“下界落后”由本脚本拦截。

扫描范围是当前文档（根 README / AGENTS / CONTRIBUTING / docs 当前目录 / 包 README），
历史目录 `docs/migrations` / `docs/adr` / `docs/analysis` / `docs/feedback` 不参与。
跨包示例同样扫描：例如 `packages/map/README.md` 里的 `w_tools_map_google` 也会对照
`packages/map_google/pubspec.yaml` 校验。
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


def normalized(parts: tuple[int, ...]) -> tuple[int, int, int]:
    return (parts + (0, 0, 0))[:3]


root_pubspec = yaml.safe_load((root / 'pubspec.yaml').read_text())
versions: dict[str, str] = {root_pubspec['name']: str(root_pubspec.get('version', ''))}

for pubspec in sorted((root / 'packages').glob('*/pubspec.yaml')):
    data = yaml.safe_load(pubspec.read_text())
    name = data.get('name')
    version_raw = str(data.get('version', ''))
    package_dir = pubspec.parent
    if not name:
        continue
    versions[name] = version_raw
    readme = package_dir / 'README.md'
    if not readme.exists():
        errors.append(f'{package_dir.name}: 缺 README.md')
        continue
    if package_dir.joinpath('example').is_dir() and not re.search(
        r'example|示例',
        readme.read_text(),
        re.I,
    ):
        errors.append(f'{package_dir.name}: 有 example，但 README 没提到示例')

# 当前文档：历史目录不参与“示例版本必须最新”的检查。
docs: list[pathlib.Path] = [
    root / 'README.md',
    root / 'AGENTS.md',
    root / 'CONTRIBUTING.md',
    root / 'scripts' / 'README.md',
]
docs += sorted((root / 'docs').glob('*.md'))
for sub in ('agents', 'modules', 'recipes', 'guides'):
    docs += sorted((root / 'docs' / sub).glob('*.md'))
docs += sorted((root / 'packages').glob('*/README.md'))

install_re = re.compile(
    r'^\s*(w_tools(?:_[A-Za-z0-9_]+)?)\s*:\s*\^(\d+(?:\.\d+)*)',
    re.M,
)
seen: set[tuple[str, str, str]] = set()
for path in sorted(set(docs)):
    if not path.is_file():
        continue
    rel = path.relative_to(root)
    for match in install_re.finditer(path.read_text()):
        name, constraint_raw = match.group(1), match.group(2)
        key = (str(rel), name, constraint_raw)
        if key in seen:
            continue
        seen.add(key)
        if name not in versions:
            errors.append(f'{rel}: 安装示例引用了未知包 {name}')
            continue
        current = versions[name]
        if normalized(numbers(constraint_raw)) != normalized(numbers(current)):
            errors.append(
                f'{rel}: {name} 安装示例应使用当前版本 ^{current}'
                f'（现为 ^{constraint_raw}）',
            )

if errors:
    for error in errors:
        print(f'✗ {error}', file=sys.stderr)
    sys.exit(1)
print('当前文档安装约束（下界 == 当前版本）与 example 链接检查通过')
