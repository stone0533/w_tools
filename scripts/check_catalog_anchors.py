#!/usr/bin/env python3
"""校验 catalog 的 docsAnchor 都能在 docs/modules/*_module.md 找到。

`gen_catalog --check` 只保证生成物与 YAML 一致，不保证 anchor 指向真实标题；
本脚本把这类错误提前到静态 preflight。
"""
from __future__ import annotations

import pathlib
import re
import sys

import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG = ROOT / 'packages/cli/catalog/components.yaml'
MODULES = ROOT / 'docs/modules'

MODULE_BY_PACKAGE = {
    'w_tools_core': 'core_module.md',
    'w_tools_api': 'api_module.md',
    'w_tools_async': 'async_module.md',
    'w_tools_form': 'form_module.md',
    'w_tools_ui': 'ui_module.md',
    'w_tools_toast': 'toast_module.md',
    'w_tools_qr': 'qr_module.md',
    'w_tools_map': 'map_module.md',
    'w_tools_map_google': 'map_module.md',
    'w_tools_app': 'app_module.md',
    'w_tools_app_getx': 'app_module.md',
}


def slug(heading: str) -> str:
    h = heading.strip().lower().replace('`', '')
    h = re.sub(r'^#{1,6}\s+', '', h)
    h = re.sub(r'[^\w\u4e00-\u9fff\- ]', '', h)
    return h.strip().replace(' ', '-')


def collect_anchors(module_dir: pathlib.Path = MODULES) -> dict[str, set[str]]:
    by_module: dict[str, set[str]] = {}
    for path in module_dir.glob('*_module.md'):
        anchors: set[str] = set()
        for match in re.finditer(r'^#{1,6}\s+(.+)$', path.read_text(), re.M):
            anchors.add(slug(match.group(1)))
        by_module[path.name] = anchors
    return by_module


def validate(
    entries: list[dict],
    anchors_by_module: dict[str, set[str]],
    module_by_package: dict[str, str] | None = None,
) -> list[str]:
    mapping = module_by_package if module_by_package is not None else MODULE_BY_PACKAGE
    errors: list[str] = []
    for entry in entries:
        name = str(entry.get('name', '?')).strip('`')
        anchor = (entry.get('docsAnchor') or '').strip()
        if not anchor:
            # docsAnchor 是可选字段；缺失由 UI / form 的完整性测试单独保证。
            continue
        if anchor.startswith('#'):
            errors.append(f'{name} 的 docsAnchor 不能带 #：{anchor}')
            continue
        package = str(entry.get('package', ''))
        module = mapping.get(package)
        if module is None:
            if not any(anchor in anchors for anchors in anchors_by_module.values()):
                errors.append(f'{name} 的 docsAnchor 不在任何 module 文档：{anchor}')
            continue
        anchors = anchors_by_module.get(module)
        if anchors is None:
            errors.append(f'{name} 的 package {package} 没有对应的 {module}')
            continue
        if anchor not in anchors:
            errors.append(f'{name} 的 docsAnchor 不在 {module}：{anchor}')
    return errors


def main() -> int:
    data = yaml.safe_load(CATALOG.read_text())
    entries = data.get('components', [])
    anchors = collect_anchors()
    errors = validate(entries, anchors)
    if errors:
        print('catalog docsAnchor 校验失败：', file=sys.stderr)
        for error in errors:
            print(f'  ✗ {error}', file=sys.stderr)
        return 1
    print(f'✓ catalog docsAnchor 都能在 module 文档找到（{len(entries)} 条）')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
