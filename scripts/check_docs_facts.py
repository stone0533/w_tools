#!/usr/bin/env python3
"""当前文档的事实一致性检查。

只检查“当前文档”，历史目录（migrations/adr/analysis/release）允许旧版本和旧数量。
"""
from __future__ import annotations

import pathlib
import re
import sys
import yaml

root = pathlib.Path(__file__).resolve().parent.parent
historical = {'migrations', 'adr', 'analysis', 'releases'}
files: list[pathlib.Path] = [root / 'README.md', root / 'AGENTS.md', root / 'CONTRIBUTING.md', root / 'scripts/README.md']
for base in ['docs', 'packages']:
    for path in (root / base).rglob('*.md'):
        rel = path.relative_to(root)
        if base == 'docs' and len(rel.parts) > 1 and rel.parts[1] in historical:
            continue
        if base == 'packages' and ('example' in rel.parts or path.name == 'CHANGELOG.md'):
            continue
        files.append(path)

errors: list[str] = []

# 包数量 / 根聚合关系从 pubspec 推导，避免文档写死过期数字。
TOOLS = {'w_tools_cli', 'w_tools_figma', 'w_tools_device', 'w_tools_e2e'}
packages = {}
for pubspec in (root / 'packages').glob('*/pubspec.yaml'):
    data = yaml.safe_load(pubspec.read_text())
    packages[data['name']] = data
flutter_packages = {
    name for name, data in packages.items()
    if data.get('environment', {}).get('flutter') and name not in TOOLS
}
modules_readme = root / 'docs/modules/README.md'
if modules_readme.exists():
    text = modules_readme.read_text()
    library_packages = set(packages) - TOOLS
    expected = f'**{len(library_packages)} 个库子包**'
    if expected not in text:
        errors.append(f'docs/modules/README.md: 缺少当前包数量 {expected}')
    for name in sorted(library_packages):
        if name not in text:
            errors.append(f'docs/modules/README.md: 没有列出 {name}')

root_pubspec = yaml.safe_load((root / 'pubspec.yaml').read_text())
root_aggregate = {
    name for name in (root_pubspec.get('dependencies') or {})
    if str(name).startswith('w_tools_')
}
if modules_readme.exists():
    text = modules_readme.read_text()
    for name in sorted(root_aggregate):
        if name not in text:
            errors.append(f'docs/modules/README.md: 根聚合包 {name} 未说明')
patterns = {
    r'9 个 Flutter': '当前文档仍写 9 个 Flutter 子包（实际 11）',
    r'8 个 Flutter': '当前文档仍写 8 个 Flutter 子包（实际 11）',
    r'13 个子包': '当前文档仍写 13 个子包（实际更多）',
    r'11 个 Flutter 子包通过[^\n]*聚合': '当前文档错误声称 11 个全部由根包聚合',
    r'dart run w_tools_cli:(context|list|explain|doctor|init|feedback)': '当前文档仍用旧命令入口',
}
for path in files:
    text = path.read_text()
    for pattern, message in patterns.items():
        if re.search(pattern, text):
            errors.append(f'{path.relative_to(root)}: {message}')

if errors:
    for error in errors:
        print(f'✗ {error}', file=sys.stderr)
    sys.exit(1)
print('当前文档事实检查通过')
