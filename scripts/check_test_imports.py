#!/usr/bin/env python3
"""测试 import 边界：`package:w_tools_<pkg>/src/...` 只允许出现在 test/internal/。"""
from __future__ import annotations

import argparse
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent


def check_package(package_dir: pathlib.Path, package: str) -> list[str]:
    pattern = re.compile(rf"package:w_tools_{re.escape(package)}/src/")
    errors: list[str] = []
    test_dirs = [package_dir / 'test', package_dir / 'integration_test', package_dir / 'example' / 'test']
    for test_dir in test_dirs:
        if not test_dir.exists():
            continue
        for path in test_dir.rglob('*.dart'):
            relative = path.relative_to(test_dir)
            if relative.parts and relative.parts[0] == 'internal':
                continue
            text = path.read_text()
            for match in pattern.finditer(text):
                line = text.count('\n', 0, match.start()) + 1
                errors.append(
                    f'{path.relative_to(package_dir)}:{line} 直接 import src（应放 test/internal/ 或改用 barrel）'
                )
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--package', required=True, help='manifest 裸名，如 ui')
    args = parser.parse_args()
    package_dir = ROOT / 'packages' / args.package
    errors = check_package(package_dir, args.package)
    if errors:
        print('测试 import 边界检查失败：', file=sys.stderr)
        for error in errors:
            print(f'  ✗ {error}', file=sys.stderr)
        return 1
    print(f'✓ {args.package} 测试 import 边界通过')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
