#!/usr/bin/env python3
"""catalog usage / pitfalls / related 里的 W* 必须真实存在于公开 API。"""
from __future__ import annotations

import pathlib
import re
import sys

import yaml

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from check_public_api_diff import DECL, _body, strip_comments  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG = ROOT / 'packages/cli/catalog/components.yaml'
SYMBOL = re.compile(r'\bW[A-Z][A-Za-z0-9_]*(?:\.[A-Za-z_]\w*)?')


def extract_symbols(text: str) -> set[str]:
    return set(SYMBOL.findall(text))


def _entry_texts(entry: dict) -> list[str]:
    # dontUseFor / pitfalls 允许出现“不要用已删除 API”的反例；只检查推荐用法。
    texts = [str(entry.get(key, '')) for key in ('name', 'useFor', 'usage')]
    related = entry.get('related') or []
    texts.extend(str(item) for item in related)
    return texts


def type_bodies(package_dir: pathlib.Path) -> dict[str, str]:
    bodies: dict[str, str] = {}
    for path in (package_dir / 'lib').rglob('*.dart'):
        text = strip_comments(path.read_text())
        for match in DECL.finditer(text):
            bodies[match.group(1)] = _body(text, match.start())
    return bodies


def validate(entries: list[dict], bodies: dict[str, str]) -> list[str]:
    errors: list[str] = []
    for entry in entries:
        for text in _entry_texts(entry):
            for symbol in extract_symbols(text):
                type_name, _, member = symbol.partition('.')
                body = bodies.get(type_name)
                if body is None:
                    errors.append(f'{entry.get("name", "?")}: {type_name} 不在任何公开 API')
                elif member and not re.search(rf'\b{re.escape(member)}\b', body):
                    errors.append(f'{entry.get("name", "?")}: {symbol} 不在 {type_name} 的声明里')
    return errors


def main() -> int:
    data = yaml.safe_load(CATALOG.read_text())
    entries = data.get('components', [])
    packages = sorted({str(entry.get('package')) for entry in entries})
    bodies: dict[str, str] = {}
    for package in packages:
        short = package.removeprefix('w_tools_')
        package_dir = ROOT / 'packages' / short
        if package_dir.exists():
            bodies.update(type_bodies(package_dir))
    errors = validate(entries, bodies)
    if errors:
        print('catalog 符号校验失败：', file=sys.stderr)
        for error in errors:
            print(f'  ✗ {error}', file=sys.stderr)
        return 1
    print(f'✓ catalog 符号都能在公开 API 找到（{len(entries)} 条）')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
