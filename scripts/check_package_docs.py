#!/usr/bin/env python3
"""检查每个子包 README 的安装版本与 example 链接。"""
from __future__ import annotations

import pathlib
import re
import sys
import yaml

root = pathlib.Path(__file__).resolve().parent.parent
errors: list[str] = []

for pubspec in sorted((root / 'packages').glob('*/pubspec.yaml')):
    data = yaml.safe_load(pubspec.read_text())
    name = data.get('name')
    version = str(data.get('version', ''))
    package_dir = pubspec.parent
    readme = package_dir / 'README.md'
    if not name:
        continue
    if not readme.exists():
        errors.append(f'{package_dir.name}: 缺 README.md')
        continue
    text = readme.read_text()
    major = version.split('.')[0] if version else ''
    if major:
        install = re.search(
            rf'{re.escape(name)}\s*:\s*\^(\d+)\.',
            text,
        )
        if install and install.group(1) != major:
            errors.append(
                f'{package_dir.name}: README 安装版本 ^${install.group(1)} 与 pubspec {version} 不一致',
            )
    example = package_dir / 'example'
    if example.is_dir() and not re.search(r'example|示例', text, re.I):
        errors.append(f'{package_dir.name}: 有 example，但 README 没提到示例')

if errors:
    for error in errors:
        print(f'✗ {error}', file=sys.stderr)
    sys.exit(1)
print('子包 README 版本/示例检查通过')
