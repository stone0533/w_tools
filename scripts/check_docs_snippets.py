#!/usr/bin/env python3
"""检查 docs 中已经证伪的 API 片段与 components 表格列数。"""
from __future__ import annotations

import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
docs = root / 'docs'
errors: list[str] = []

for path in docs.rglob('*.md'):
    text = path.read_text()
    for pattern, label in (
        (r'WApp\.addPlugin\(', 'WApp.addPlugin 静态调用'),
        (r'customTasks:\s*\(\)', 'customTasks 回调写法'),
        (r'WMap\.closeSelection', 'WMap.closeSelection（应在 WMapController）'),
    ):
        if re.search(pattern, text):
            errors.append(f'{path}: {label}')

    if re.search(r'WQrViewOverlayShape\s*\((?:[^)]|\n)*?borderColor', text):
        errors.append(f'{path}: WQrViewOverlayShape 包含 borderColor')

components = docs / 'modules' / 'components.md'
lines = components.read_text().splitlines()
start = next((i for i, line in enumerate(lines) if line.startswith('## 8. 能力')), None)
end = next((i for i, line in enumerate(lines) if start is not None and i > start and line.startswith('## 9.')), None)
if start is not None and end is not None:
    for i in range(start, end):
        line = lines[i]
        if line.startswith('|') and not line.startswith('| ---'):
            cells = [cell for cell in line.strip().strip('|').split('|')]
            if len(cells) != 4:
                errors.append(f'{components}:{i + 1}: 第 8 节表格应有 4 列，实际 {len(cells)}')

if errors:
    for error in errors:
        print(f'✗ {error}', file=sys.stderr)
    sys.exit(1)
print('片段检查通过')
