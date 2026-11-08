#!/usr/bin/env python3
"""覆盖率下限检查：读取 lcov.info，按行覆盖失败。

CI 里在 `flutter test --coverage` 之后跑；不在 preflight 默认路径里，
避免每次本地门禁都重新跑一遍带覆盖率的测试。

用法：
  python3 scripts/check_coverage.py --package ui --min-lines 90
  python3 scripts/check_coverage.py --lcov /tmp/lcov.info --min-lines 90

退出码：0 达标；1 低于下限；2 报告缺失 / 无有效 LF。
"""
from __future__ import annotations

import argparse
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent


def parse_lcov(path: pathlib.Path) -> tuple[int, int]:
    lines_hit = 0
    lines_found = 0
    for line in path.read_text(errors='replace').splitlines():
        if line.startswith('LF:'):
            lines_found += int(line[3:].strip() or 0)
        elif line.startswith('LH:'):
            lines_hit += int(line[3:].strip() or 0)
    return lines_hit, lines_found


def main() -> int:
    parser = argparse.ArgumentParser(description='覆盖率下限检查')
    parser.add_argument('--package', help='packages/<name>/coverage/lcov.info')
    parser.add_argument('--lcov', help='直接指定 lcov.info 路径')
    parser.add_argument('--min-lines', type=float, required=True, help='行覆盖下限（百分比）')
    args = parser.parse_args()

    if args.lcov:
        path = pathlib.Path(args.lcov)
    elif args.package:
        path = ROOT / 'packages' / args.package / 'coverage' / 'lcov.info'
    else:
        parser.error('需要 --package 或 --lcov')

    if not path.is_file():
        print(f'✗ 找不到 lcov.info: {path}', file=sys.stderr)
        return 2

    lines_hit, lines_found = parse_lcov(path)
    if lines_found == 0:
        print(f'✗ {path} 没有有效的 LF 记录', file=sys.stderr)
        return 2

    percent = lines_hit * 100 / lines_found
    label = args.package or path.parent.parent.name
    print(
        f'{label}: 行覆盖 {percent:.1f}%（{lines_hit}/{lines_found}），'
        f'下限 {args.min_lines:.1f}%'
    )
    if percent + 1e-9 < args.min_lines:
        print(f'✗ {label} 行覆盖 {percent:.1f}% 低于下限 {args.min_lines:.1f}%', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
