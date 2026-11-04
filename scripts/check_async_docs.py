#!/usr/bin/env python3
"""Async 5.0 文档片段一致性检查。

只覆盖当前公开文档，不检查历史迁移文档；目标是挡住已经证伪的写法。
"""
from __future__ import annotations

import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
files = [
    root / 'packages/async/README.md',
    root / 'docs/agents/async.md',
    root / 'docs/modules/async_module.md',
]
errors: list[str] = []

bad_patterns = {
    r'WAsync\.runValue': 'WAsync.runValue 已删除，用 WAsync.run',
    r'WAsyncOptions\s*\(\s*loading:': 'WAsyncOptions.loading 已改名 activity',
    r'options\.loading': 'options.loading 已改名 activity',
    r'dataOrNull': 'dataOrNull 已删除，用 data',
    r'WAsync\.run\s*\([^;]*?onSuccess\s*:': 'WAsync.run 不再接受 onSuccess，用 WAsync.map',
    r'result\.isProgrammingError': '请解构 WAsyncFailure 的 isProgrammingError',
}
for path in files:
    text = path.read_text()
    for pattern, message in bad_patterns.items():
        if re.search(pattern, text, re.S):
            errors.append(f'{path}: {message}')

readme = (root / 'packages/async/README.md').read_text()
if 'WAsyncController.list' in readme and '.load();' not in readme:
    errors.append('packages/async/README.md: 快速开始缺少 controller.load()')

if errors:
    for error in errors:
        print(f'✗ {error}', file=sys.stderr)
    sys.exit(1)
print('async 文档片段检查通过')
