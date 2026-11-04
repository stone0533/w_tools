#!/usr/bin/env python3
"""检查 5.0 已删除的 API 是否仍出现在文档/示例（迁移/历史文档除外）。

推荐路径（docs/agents、docs/recipes、docs/modules、各包 README、消费方模板、example）
里如果出现已删除符号，除非同一行明确写“已删除/已移除/不再提供/迁移”，否则失败。
"""
from __future__ import annotations

import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
names = [
    r'WRowButtons', r'WRowButtonsController', r'WSizeBox', r'WPadding', r'WColumn',
    r'WImageCachePolicy', r'WImageConfig', r'WImageDefaults\b', r'WImageEmptyError',
    r'WImageNetworkError', r'WImageAssetError', r'WImageDecodeError', r'WImageProviderError',
    r'WImageFileError', r'WImageUnsupportedError', r'WImage\.avatar', r'WImage\.thumbnail',
    r'WImage\.cover', r'WImage\.assetImage', r'WToastConfig', r'WFormDefaults',
    r'WFormBorderConfigBuilder', r'WFormRowBorderExtension', r'withFormBorder',
    r'WAsyncViewDefaults', r'WAsyncSliverDefaults', r'\bWConfig\b', r'\bWRoute\b',
    r'\bonDataUpdated\b', r'WApp\(\)', r'WMapConfig\.build',
]
patterns = [re.compile(r'\b' + n + r'\b') for n in names]
allow = re.compile(r'删除|移除|不再提供|迁移|removed', re.IGNORECASE)

targets = []
for sub in ('docs/agents', 'docs/recipes', 'docs/modules'):
    targets += sorted((root / sub).glob('*.md'))
targets += sorted((root / 'packages').glob('*/README.md'))
targets += sorted((root / 'packages').glob('*/example/README.md'))
targets += sorted((root / 'packages').glob('*/example/lib/**/*.dart'))
targets += sorted((root / 'packages/cli/templates/agents').rglob('*.md'))

bad = []
for path in targets:
    if not path.is_file():
        continue
    for i, line in enumerate(path.read_text().splitlines(), 1):
        if allow.search(line):
            continue
        for pattern in patterns:
            if pattern.search(line):
                bad.append(f'{path.relative_to(root)}:{i}: {line.strip()[:100]}')
                break

if bad:
    print('文档/示例仍引用 5.0 已删除 API：', file=sys.stderr)
    for item in bad:
        print(f'  ✗ {item}', file=sys.stderr)
    sys.exit(1)

print(f'✓ 已删除 API 未被推荐（{len(targets)} 个文件）')
