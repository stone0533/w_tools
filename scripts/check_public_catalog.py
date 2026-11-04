#!/usr/bin/env python3
"""公开类型 → catalog 反向检查。

catalog 只登记“组件入口”，不是每个子 API 都单独登记。
catalog/uncataloged.yaml 记录有意不登记的公开类型；新增公开类型必须
二选一：加 catalog，或加入该基线。用 --write 重建基线。
"""
from __future__ import annotations

import pathlib
import re
import sys
import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG = ROOT / 'packages/cli/catalog/components.yaml'
BASELINE = ROOT / 'packages/cli/catalog/uncataloged.yaml'
SKIP = {'w_tools_cli', 'w_tools_device', 'w_tools_e2e', 'w_tools_figma'}

DECL = re.compile(r'\b(?:class|enum|mixin|typedef|extension)\s+([A-Z][A-Za-z0-9_]*)')
EXPORT = re.compile(r"^\s*export\s+'([^']+)'(?:\s+show\s+([^;]+)|\s+hide\s+([^;]+))?;", re.M)
PART = re.compile(r"^\s*part\s+'([^']+)'", re.M)


def exported_types(package_dir: pathlib.Path) -> set[str]:
    lib = package_dir / 'lib'
    barrels = list(lib.glob('w_tools_*.dart'))
    out: set[str] = set()
    seen: set[pathlib.Path] = set()

    def visit(path: pathlib.Path, show: set[str] | None, hide: set[str]) -> None:
        path = path.resolve()
        if path in seen or not path.exists():
            return
        seen.add(path)
        text = path.read_text()
        for m in PART.finditer(text):
            visit(path.parent / m.group(1), show, hide)
        for m in EXPORT.finditer(text):
            target = (path.parent / m.group(1)).resolve()
            child_show = set(x.strip() for x in m.group(2).split(',')) if m.group(2) else show
            child_hide = set(x.strip() for x in m.group(3).split(',')) if m.group(3) else hide
            visit(target, child_show, child_hide)
        for m in DECL.finditer(text):
            name = m.group(1)
            if show is not None and name not in show:
                continue
            if name in hide:
                continue
            out.add(name)

    for barrel in barrels:
        visit(barrel, None, set())
    return out


def load_baseline() -> dict[str, set[str]]:
    if not BASELINE.exists():
        return {}
    raw = yaml.safe_load(BASELINE.read_text()) or {}
    return {
        str(pkg): set(names or [])
        for pkg, names in (raw.get('packages') or {}).items()
    }


def write_baseline(data: dict[str, set[str]]) -> None:
    lines = [
        '# 公开类型中，有意不进入 catalog 的子 API。',
        '# 新增公开类型时：要么登记 catalog，要么在这里显式登记。',
        '# 生成：python3 scripts/check_public_catalog.py --write',
        'version: 1',
        'packages:',
    ]
    for pkg in sorted(data):
        lines.append(f'  {pkg}:')
        for name in sorted(data[pkg]):
            lines.append(f'    - {name}')
    BASELINE.write_text('\n'.join(lines) + '\n')


def main() -> int:
    raw = yaml.safe_load(CATALOG.read_text())
    catalog_names: set[str] = set()
    for component in raw['components']:
        for name in component['name'].split('/'):
            catalog_names.add(name.replace('`', '').replace('*', '').strip())

    baseline = load_baseline()
    current: dict[str, set[str]] = {}
    for pubspec in sorted((ROOT / 'packages').glob('*/pubspec.yaml')):
        data = yaml.safe_load(pubspec.read_text())
        pkg = data.get('name')
        if not pkg or pkg in SKIP:
            continue
        current[pkg] = {n for n in exported_types(pubspec.parent) if n not in catalog_names}

    if '--write' in sys.argv:
        write_baseline(current)
        print(f'已写入 {BASELINE.relative_to(ROOT)}')
        return 0

    errors: list[str] = []
    for pkg, names in current.items():
        unknown = names - baseline.get(pkg, set())
        for name in sorted(unknown):
            errors.append(
                f'{pkg}: 新公开类型 {name} 未进入 catalog/uncataloged.yaml；'
                '请登记 catalog 或更新基线',
            )
    if errors:
        for error in errors:
            print(f'✗ {error}', file=sys.stderr)
        return 1
    print(f'公开类型 catalog 检查通过（{sum(len(v) for v in current.values())} 个已登记子 API）')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
