#!/usr/bin/env python3
"""检查文档代码块里引用的 `W...(...)` 是否真实存在。

只扫推荐路径（docs/agents、docs/recipes、packages/*/README.md、docs/modules），
跳过迁移 / 分析 / ADR（历史文档允许出现已删除的名字）。

规则：```dart 代码块内 `WXxx(` 的 `WXxx` 必须能在 packages/*/lib 找到
class / enum / mixin / extension / typedef 声明。
"""
from __future__ import annotations

import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
declared: set[str] = set()
decl_re = re.compile(r'\b(?:class|enum|mixin|extension|typedef)\s+(W[A-Za-z0-9_]+)')

for path in (root / 'packages').glob('*/lib/**/*.dart'):
    declared.update(decl_re.findall(path.read_text()))

targets: list[pathlib.Path] = []
for sub in ('docs/agents', 'docs/recipes', 'docs/modules'):
    targets.extend(sorted((root / sub).glob('*.md')))
targets.extend(sorted((root / 'packages').glob('*/README.md')))

call_re = re.compile(r'\b(W[A-Z][A-Za-z0-9_]*)\s*\(')
block_re = re.compile(r'```dart\n(.*?)```', re.S)
bad: list[str] = []

for path in targets:
    text = path.read_text()
    for block in block_re.findall(text):
        for match in call_re.finditer(block):
            name = match.group(1)
            if name not in declared:
                line = block[: match.start()].count('\n') + 1
                bad.append(f'{path.relative_to(root)}: 代码块第 {line} 行引用了未定义符号 {name}')

if bad:
    print('文档代码块引用了不存在的符号：', file=sys.stderr)
    for item in bad:
        print(f'  ✗ {item}', file=sys.stderr)
    sys.exit(1)

print(f'✓ 文档代码块符号检查通过（{len(targets)} 个文件）')
