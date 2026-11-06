#!/usr/bin/env python3
"""测试 import 边界：`package:w_tools_<pkg>/src/...` 只允许出现在 `test/internal/`。

默认检查 `scripts/packages.manifest` 里的全部包（不再只查 ui）。
存量违规登记在 `scripts/test_imports_baseline.yaml`：
- 新增违规 → 失败（应把测试挪进 `test/internal/` 或改用 barrel）；
- 基线里已经不再违规的文件 → 也失败（只减不增，修好了要删行）。
"""
from __future__ import annotations

import argparse
import pathlib
import re
import sys

import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent
BASELINE = ROOT / 'scripts/test_imports_baseline.yaml'
MANIFEST = ROOT / 'scripts/packages.manifest'


def manifest_packages() -> list[str]:
    packages: list[str] = []
    for raw in MANIFEST.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        packages.append(line.split('|')[0].removeprefix('w_tools_'))
    return packages


def violations(package_dir: pathlib.Path, package: str) -> dict[str, list[int]]:
    """返回 {相对包路径: [行号...]}。"""
    pattern = re.compile(rf"package:w_tools_{re.escape(package)}/src/")
    found: dict[str, list[int]] = {}
    test_dirs = [
        package_dir / 'test',
        package_dir / 'integration_test',
        package_dir / 'example' / 'test',
    ]
    for test_dir in test_dirs:
        if not test_dir.exists():
            continue
        for path in sorted(test_dir.rglob('*.dart')):
            relative = path.relative_to(test_dir)
            if relative.parts and relative.parts[0] == 'internal':
                continue
            text = path.read_text()
            lines = [text.count('\n', 0, match.start()) + 1 for match in pattern.finditer(text)]
            if lines:
                found[str(path.relative_to(package_dir))] = lines
    return found


def check_package(package_dir: pathlib.Path, package: str) -> list[str]:
    """兼容旧调用：返回可读的错误行。"""
    errors: list[str] = []
    for path, lines in violations(package_dir, package).items():
        for line in lines:
            errors.append(
                f'{path}:{line} 直接 import src（应放 test/internal/ 或改用 barrel）'
            )
    return errors


def load_baseline() -> dict[str, set[str]]:
    if not BASELINE.exists():
        return {}
    raw = yaml.safe_load(BASELINE.read_text()) or {}
    return {
        str(pkg): set(paths or [])
        for pkg, paths in (raw.get('packages') or {}).items()
    }


def write_baseline(data: dict[str, set[str]]) -> None:
    lines = [
        '# 测试 import 边界的存量违规（只减不增）。',
        '# 规则：packages/<pkg>/{test,integration_test,example/test} 里只允许 import barrel；',
        '# 需要内部实现时把测试放进 test/internal/。',
        '# 新增违规必须改代码，不要往这里加行；脚本会双向检查（新违规 / 已修复未删行）。',
        '# 生成：python3 scripts/check_test_imports.py --write',
        'version: 1',
        'packages:',
    ]
    for pkg in sorted(data):
        if not data[pkg]:
            continue
        lines.append(f'  {pkg}:')
        for path in sorted(data[pkg]):
            lines.append(f'    - {path}')
    BASELINE.write_text('\n'.join(lines) + '\n')


def evaluate(
    packages: list[str],
    found_by_package: dict[str, dict[str, list[int]]],
    baseline: dict[str, set[str]],
    known_packages: list[str] | None = None,
) -> list[str]:
    errors: list[str] = []
    for package in packages:
        found = set(found_by_package.get(package, {}))
        allowed = baseline.get(package, set())
        for path in sorted(found - allowed):
            errors.append(
                f'{package}: {path} 新增 src import（应放 test/internal/ 或改用 barrel）'
            )
        for path in sorted(allowed - found):
            errors.append(
                f'{package}: {path} 已不在违规列表（已修复 / 已移动），请从基线删行'
            )
    known = set(known_packages if known_packages is not None else packages)
    for package in sorted(set(baseline) - known):
        errors.append(f'{package}: 基线里的包不在 manifest 里，请确认包名')
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--package', help='manifest 裸名，如 ui；缺省检查全部包')
    parser.add_argument('--write', action='store_true', help='重建基线（需人工 review）')
    args = parser.parse_args()

    all_packages = manifest_packages()
    if args.package:
        if args.package not in all_packages:
            print(f'未知包：{args.package}（可选：{" ".join(all_packages)}）', file=sys.stderr)
            return 2
        packages = [args.package]
    else:
        packages = all_packages

    found = {
        package: violations(ROOT / 'packages' / package, package)
        for package in packages
    }

    if args.write:
        data = {package: set(paths) for package, paths in found.items()}
        if args.package:
            # 只重建单包时保留其它包，避免把它们当成已修复。
            data = {**load_baseline(), **data}
        write_baseline(data)
        print(f'已写入 {BASELINE.relative_to(ROOT)}（{sum(len(v) for v in data.values())} 个文件）')
        return 0

    baseline = load_baseline()
    errors = evaluate(packages, found, baseline, known_packages=all_packages)
    if errors:
        print('测试 import 边界检查失败：', file=sys.stderr)
        for error in errors:
            print(f'  ✗ {error}', file=sys.stderr)
        return 1

    debt = sum(len(baseline.get(package, set())) for package in packages)
    print(f'✓ 测试 import 边界通过（{len(packages)} 个包，{debt} 个存量文件）')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
