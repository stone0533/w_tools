#!/usr/bin/env python3
"""检查 docs 中已经证伪的 API 片段与 components 表格列数。"""
from __future__ import annotations

import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
docs = root / 'docs'
errors: list[str] = []
historical = {'migrations', 'adr', 'analysis', 'releases'}

for path in docs.rglob('*.md'):
    if any(part in historical for part in path.relative_to(docs).parts):
        continue
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

    # WImage 6.0：旧构造器 / String 扩展已删除；允许“已删除”说明行。
    for i, line in enumerate(text.splitlines()):
        if any(word in line for word in ('已删除', '删除', '不要用', '不再', '移除')):
            continue
        if re.search(r'WImage\.(?:thumbnail|cover|network|asset|file|base64|provider|memory)\s*\(', line):
            errors.append(f'{path}:{i + 1}: WImage 旧构造器已删除，改用 WImage.source')
        if re.search(r'\.to(?:Image|AssetImage|Base64Image|FileImage)\s*\(', line):
            errors.append(f'{path}:{i + 1}: String 图片扩展已删除，改用 WImage.source')

    # form 5.0：直接字段不接受 config；只提示当前业务文档，内部实现说明不误伤。
    lines = text.splitlines()
    for i, line in enumerate(lines):
        if not re.match(r'\s*config\s*:', line):
            continue
        window = '\n'.join(lines[max(0, i - 25) : i])
        if re.search(r'WForm(?:TextField|Dropdown|MultiDropdown|DatePicker|Checkbox|RadioGroup|Button)\s*\(', window):
            errors.append(f'{path}:{i + 1}: 直接表单字段不应传 config')

components = docs / 'modules' / 'components.md'
lines = components.read_text().splitlines()
start = next((i for i, line in enumerate(lines) if line.startswith('## 8. 能力')), None)
end = next((i for i, line in enumerate(lines) if start is not None and i > start and line.startswith('## 9.')), None)
if start is None or end is None:
    # 标题改名时不能静默跳过列数检查：那会让整个 §8 表格失守。
    errors.append(
        f'{components}: 找不到「## 8. 能力…」或「## 9. …」标题，无法校验组件表格列数',
    )
else:
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
