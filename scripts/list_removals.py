#!/usr/bin/env python3
"""列出所有 `remove-in` 弃用项，供下一个大版本机械删除。

用法：
    python3 scripts/list_removals.py          # 文本，按到期版本分组
    python3 scripts/list_removals.py --md     # Markdown 表格
    python3 scripts/list_removals.py --package async

约定与 check_deprecations.py 一致：`/// remove-in: x.y.z` 必须在 `@Deprecated`
前后 10 行内；声明取 @Deprecated 之后第一条非注释/非注解行。
"""
from __future__ import annotations

import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
packages = root / 'packages'
version_re = re.compile(r'^version:[ \t]*(\S+)', re.MULTILINE)
remove_in_re = re.compile(r'remove-in:\s*(\d+\.\d+\.\d+)')
window = 10


def parse_version(raw: str) -> tuple[int, int, int] | None:
    m = re.match(r'(\d+)\.(\d+)\.(\d+)', raw)
    return tuple(int(x) for x in m.groups()) if m else None  # type: ignore[return-value]


def declaration_after(lines: list[str], index: int) -> str:
    for line in lines[index + 1 : index + window + 1]:
        s = line.strip()
        if not s or s.startswith(('///', '//', '@', '}', ')')):
            continue
        return s[:110]
    return '(unknown)'


args = sys.argv[1:]
wanted = None
if '--package' in args:
    i = args.index('--package')
    if i + 1 >= len(args):
        print('--package 需要包名', file=sys.stderr)
        raise SystemExit(2)
    wanted = args[i + 1]

rows: list[tuple[str, str, str, str]] = []
for pubspec in sorted(packages.glob('*/pubspec.yaml')):
    package = pubspec.parent.name
    if wanted and wanted not in {package, f'w_tools_{package}'}:
        continue
    current = parse_version((version_re.search(pubspec.read_text()) or [None, '0.0.0'])[1])
    for path in sorted((pubspec.parent / 'lib').rglob('*.dart')):
        lines = path.read_text().splitlines()
        for i, line in enumerate(lines):
            if 'remove-in:' not in line:
                continue
            target = remove_in_re.search(line)
            if not target:
                continue
            # 关联到最近的下一个 @Deprecated（标记在注解之前）；没有则向前找
            dep = next(
                (j for j in range(i, min(len(lines), i + window + 1)) if '@Deprecated' in lines[j]),
                None,
            )
            if dep is None:
                dep = next(
                    (
                        j
                        for j in range(max(0, i - window), i)
                        if '@Deprecated' in lines[j]
                    ),
                    None,
                )
            decl = declaration_after(lines, dep) if dep is not None else '(no @Deprecated)'
            rel = path.relative_to(root)
            rows.append((target.group(1), package, f'{rel}:{i + 1}', decl))

rows.sort(key=lambda r: (tuple(int(x) for x in r[0].split('.')), r[1], r[2]))
if '--md' in args:
    print('| 到期 | 包 | 位置 | 声明 |')
    print('| --- | --- | --- | --- |')
    for target, package, loc, decl in rows:
        print(f'| {target} | {package} | `{loc}` | `{decl}` |')
else:
    current_target = None
    for target, package, loc, decl in rows:
        if target != current_target:
            print(f'\n== {target} ==')
            current_target = target
        print(f'  {package}: {loc}\n    {decl}')
print(f'\n共 {len(rows)} 项', file=sys.stderr)
