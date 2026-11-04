#!/usr/bin/env python3
"""文档不得声明「已发布 / 待发布」的具体版本号。

版本只允许有一个真相：各包 `pubspec.yaml` + pub.dev。
历史上这两类句子都漂移过：`docs/agents/figma.md` 写 0.9.2（实际 0.10.0）、
`docs/modules/README.md` 写 device「0.1.1 待发布」（早已发布）—— 2026-11 评审 P3-4。

`docs/analysis/` 是带日期的评审记录，会引用历史版本，跳过。
"""
from __future__ import annotations

import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent

files = [root / 'README.md', root / 'AGENTS.md', root / 'CONTRIBUTING.md']
files += sorted((root / 'packages').glob('*/README.md'))
files += sorted((root / 'packages').glob('*/AGENTS.md'))
files += sorted((root / 'docs').rglob('*.md'))

pattern = re.compile(r'v?\d+\.\d+\.\d+\s*(?:已发布|待发布)')
skip = root / 'docs' / 'analysis'

bad: list[str] = []
for path in files:
    if not path.is_file() or skip in path.parents:
        continue
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        if pattern.search(line):
            bad.append(f'{path.relative_to(root)}:{number}: {line.strip()}')

for line in bad:
    print(f'  ✗ 文档声明了具体版本：{line}')

if not bad:
    print('  ✓ 文档没有「已发布 / 待发布」版本声明')

sys.exit(1 if bad else 0)
