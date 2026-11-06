#!/usr/bin/env python3
"""J-4A：核心入口是否出现在 docs/agents、模板、README、example。"""
from __future__ import annotations

import pathlib
import sys

import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent
ENTRYPOINTS = ROOT / 'packages/cli/catalog/entrypoints.yaml'


def _text(path: pathlib.Path) -> str:
    return path.read_text() if path.exists() else ''


def check_package(root: pathlib.Path, short: str, names: list[str]) -> list[str]:
    carriers = {
        'docs/agents': _text(root / 'docs/agents' / f'{short}.md'),
        'template-zh': _text(root / 'packages/cli/templates/agents/zh' / f'{short}.md'),
        'template-en': _text(root / 'packages/cli/templates/agents/en' / f'{short}.md'),
        'README': _text(root / 'packages' / short / 'README.md'),
        'example': '\n'.join(
            path.read_text()
            for path in (root / 'packages' / short / 'example' / 'lib').rglob('*.dart')
            if path.exists()
        ) if (root / 'packages' / short / 'example' / 'lib').exists() else '',
    }
    errors: list[str] = []
    for name in names:
        missing = [carrier for carrier, text in carriers.items() if name not in text]
        if missing:
            errors.append(f'{short}: {name} 缺少载体 {", ".join(missing)}')
    return errors


def main() -> int:
    data = yaml.safe_load(ENTRYPOINTS.read_text()) or {}
    errors: list[str] = []
    for package, names in data.items():
        short = str(package).removeprefix('w_tools_')
        errors.extend(check_package(ROOT, short, [str(name) for name in names]))
    if errors:
        print('教学覆盖检查失败：', file=sys.stderr)
        for error in errors:
            print(f'  ✗ {error}', file=sys.stderr)
        return 1
    print(f'✓ 核心入口已覆盖 docs/agents / 模板 / README / example（{len(data)} 个包）')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
