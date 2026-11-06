#!/usr/bin/env python3
"""三包默认样式禁止字面量色值（ADR-0003）。

范围：`packages/{form,toast,async}/lib`。
允许：`Colors.transparent`；以及行内标注 `// style-literal-ok: <理由>` 的历史预设
（例如 `WFormBorderConfig.standard()` 的显式浅色色板）。

为什么：form / toast / async 不依赖 w_tools_ui，颜色必须从 `ColorScheme` 派生，
否则深色主题下会出现白底表单、黑字提示这类不可读的默认样式。
"""
from __future__ import annotations

import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
targets = ['packages/form', 'packages/toast', 'packages/async']
pattern = re.compile(r'\bColor\(0x|\bColors\.(?:white|black|grey)\b')

violations: list[str] = []
scanned = 0
for target in targets:
    lib = root / target / 'lib'
    if not lib.is_dir():
        continue
    for path in sorted(lib.rglob('*.dart')):
        if path.name.endswith('.g.dart'):
            continue
        scanned += 1
        for number, line in enumerate(path.read_text().splitlines(), start=1):
            if 'style-literal-ok' in line:
                continue
            code = re.sub(r'//.*$', '', line)
            if code.lstrip().startswith('//'):
                continue
            if pattern.search(code):
                violations.append(
                    f'{path.relative_to(root)}:{number}: {line.strip()}'
                )

# 目录 / 文件都匹配不到时不能报“通过”：那说明路径写错了，而不是没有违规。
if scanned == 0:
    print('  ✗ 没有扫描到任何文件：packages/{form,toast,async}/lib 不存在或为空')
    sys.exit(1)

for violation in violations:
    print(f'  ✗ 默认样式出现字面量色值：{violation}')
if violations:
    print('  改用 ColorScheme / TextTheme 派生；确属显式预设的，标 `// style-literal-ok: <理由>`')
    sys.exit(1)
print('  ✓ form / toast / async 的默认样式没有字面量色值')
