#!/usr/bin/env python3
"""检查 docs/modules 与包 README 是否复制了同一段 dart 示例。

两侧都是手写的「包用法」，完全相同的示例意味着同一事实维护了两份；改一处漏一处就会漂移。
只比**规范化后完全相同**且至少 4 行的代码块，避免把一行 import 之类的正常重复算进来。

用法：
    python3 scripts/check_docs_duplicates.py           # 只报告，退出码 0（清理期用）
    python3 scripts/check_docs_duplicates.py --fail    # 有重复即失败（CI / check_docs 用）

历史：2026-11-06 审计发现 modules（5,726 行）与 packages/*/README（2,537 行）范围重叠。
边界：本检查只抓**完全相同的 dart 代码块**；参数表 / 散文重叠不在范围内，按
[`docs/documentation-map.md`](../docs/documentation-map.md) 的「modules 与包 README 分工」人工收敛。
"""
from __future__ import annotations

import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
docs = root / 'docs' / 'modules'
BLOCK_RE = re.compile(r'```dart\n(.*?)```', re.S)
MIN_LINES = 4


def normalized(block: str) -> str:
    lines = [line.rstrip() for line in block.strip().splitlines()]
    return '\n'.join(line for line in lines if line)


def blocks_with_lines(path: pathlib.Path) -> list[tuple[int, str]]:
    text = path.read_text()
    out: list[tuple[int, str]] = []
    for match in BLOCK_RE.finditer(text):
        body = normalized(match.group(1))
        if body.count('\n') + 1 < MIN_LINES:
            continue
        out.append((text[: match.start()].count('\n') + 1, body))
    return out


duplicates: list[str] = []
compared: list[str] = []
for module in sorted(docs.glob('*_module.md')):
    package = module.name.removesuffix('_module.md')
    readme = root / 'packages' / package / 'README.md'
    if not readme.exists():
        continue
    module_blocks = blocks_with_lines(module)
    readme_blocks = blocks_with_lines(readme)
    if not module_blocks or not readme_blocks:
        continue
    compared.append(f'{module.name} ↔ packages/{package}/README.md')
    readme_index = {body: line for line, body in readme_blocks}
    for line, body in module_blocks:
        readme_line = readme_index.get(body)
        if readme_line is None:
            continue
        duplicates.append(
            f'{module.relative_to(root)}:{line} 与 {readme.relative_to(root)}:{readme_line} '
            f'是同一段 {body.count(chr(10)) + 1} 行 dart 示例',
        )

# 一对可比较的文档都没找到时不能报“通过”：说明路径或命名规则已经变了。
if not compared:
    print(
        '✗ 没有可比较的 modules ↔ 包 README 组合（检查路径 / *_module.md 命名）',
        file=sys.stderr,
    )
    sys.exit(1)

if duplicates:
    for item in duplicates:
        print(f'✗ {item}', file=sys.stderr)
    print(
        f'\n共 {len(duplicates)} 段重复：同一示例只保留一处，另一处改成链接。',
        file=sys.stderr,
    )
    if '--fail' in sys.argv[1:]:
        sys.exit(1)
    print('（report-only：加 --fail 才会让门禁失败）')
else:
    print('✓ modules 与包 README 没有重复的 dart 示例')
