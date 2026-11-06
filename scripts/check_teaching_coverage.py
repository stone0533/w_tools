#!/usr/bin/env python3
"""J-4A：核心入口是否出现在 docs/agents、模板、README、example。

载体规则：
- 硬性：docs/agents/<doc>.md、templates/agents/{zh,en}/<doc>.md、packages/<pkg>/README.md；
- 可选：`packages/<pkg>/example/lib` 存在时才要求（没有 example 的包不因此失败）。
- `app_getx` / `map_google` 没有独立规则页，共用 `app.md` / `map.md`。

只做子串匹配，代表“提到过”，不代表讲清楚了；详细矩阵仍由 J-4 人工审计。
"""
from __future__ import annotations

import pathlib
import sys

import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent
ENTRYPOINTS = ROOT / 'packages/cli/catalog/entrypoints.yaml'

# 没有独立规则页 / 模板的包，共用哪个包的文档。
DOC_ALIASES = {
    'app_getx': 'app',
    'map_google': 'map',
}


def _text(path: pathlib.Path) -> str:
    return path.read_text() if path.exists() else ''


def check_package(
    root: pathlib.Path,
    short: str,
    names: list[str],
    doc_short: str | None = None,
) -> list[str]:
    doc_short = doc_short or short
    carriers = {
        'docs/agents': _text(root / 'docs/agents' / f'{doc_short}.md'),
        'template-zh': _text(root / 'packages/cli/templates/agents/zh' / f'{doc_short}.md'),
        'template-en': _text(root / 'packages/cli/templates/agents/en' / f'{doc_short}.md'),
        'README': _text(root / 'packages' / short / 'README.md'),
    }
    example_lib = root / 'packages' / short / 'example' / 'lib'
    if example_lib.is_dir():
        carriers['example'] = '\n'.join(
            path.read_text()
            for path in sorted(example_lib.rglob('*.dart'))
            if path.is_file()
        )
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
        errors.extend(
            check_package(ROOT, short, [str(name) for name in names], DOC_ALIASES.get(short))
        )
    if errors:
        print('教学覆盖检查失败：', file=sys.stderr)
        for error in errors:
            print(f'  ✗ {error}', file=sys.stderr)
        return 1
    print(f'✓ 核心入口已覆盖 docs/agents / 模板 / README / example（{len(data)} 个包）')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
