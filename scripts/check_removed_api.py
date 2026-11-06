#!/usr/bin/env python3
"""检查已删除的 API 是否仍出现在文档/示例（迁移/历史文档除外）。

推荐路径（root AGENTS.md、docs/agents、docs/recipes、docs/modules、各包 README、
消费方模板、example）里如果出现已删除符号，除非**同一条目**明确写
“已删除 / 已移除 / 不再提供 / 迁移”，否则失败。

“同一条目”不是整行：表格按单元格、正文按就近 40 字判断。
以前只要整行出现“删除”两个字就放行，导致“前半句推荐、后半句提一句删除”也能过。
"""
from __future__ import annotations

import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
# 已删除的公开名白名单：每次删除 / 废弃都要在这里登记，见 docs/ai-contract.md §7。
names = [
    r'WRowButtons', r'WRowButtonsController', r'WRow\b', r'WSizeBox', r'WPadding', r'WColumn',
    r'WImageCachePolicy', r'WImageConfig', r'WImageLoadConfig', r'WImageDefaults\b', r'WMapConfig',
    r'WImageDefaultsScope', r'WImageEmptyError',
    r'WImageNetworkError', r'WImageAssetError', r'WImageDecodeError', r'WImageProviderError',
    r'WImageFileError', r'WImageUnsupportedError', r'WImage\.avatar', r'WImage\.thumbnail',
    r'WImage\.cover', r'WImage\.assetImage', r'WImage\.(?:network|asset|file|base64|memory|provider)', r'WToastConfig', r'WFormDefaults',
    r'WFormBorderConfigBuilder', r'WFormRowBorderExtension', r'withFormBorder',
    r'WAsyncViewDefaults', r'WAsyncSliverDefaults', r'WAsyncBuilder', r'WAsyncConfig',
    r'WAsyncLoading', r'\bWConfig\b', r'\bWRoute\b', r'WRegExpPattern', r'WRegExpPreset',
    r'WTextConfig', r'\bonDataUpdated\b', r'WApp\(\)', r'WMapConfig\.build',
    # ui 7.0 的改名：旧名不保留，必须登记，否则 README / example 里的旧推荐拦不住。
    r'WHexColor', r'WImageStyleX',
]
# 以 `)` 结尾的条目不能补尾 `\b`：`)` 后面通常不是单词字符，补了就永远匹配不到。
patterns = [
    re.compile(r'\b' + name + ('' if name.endswith(r'\)') else r'\b'))
    for name in names
]
removal = re.compile(r'删除|移除|不再提供|迁移|removed', re.IGNORECASE)

targets = []
for sub in ('docs/agents', 'docs/recipes', 'docs/modules', 'docs/guides'):
    targets += sorted((root / sub).glob('*.md'))
targets += [root / 'README.md', root / 'AGENTS.md']
targets += sorted((root / 'packages').glob('*/README.md'))
targets += sorted((root / 'packages').glob('*/AGENTS.md'))
targets += sorted((root / 'packages').glob('*/example/README.md'))
targets += sorted((root / 'packages').glob('*/example/lib/**/*.dart'))
targets += sorted((root / 'packages/cli/templates/agents').rglob('*.md'))
# catalog 是 explain 的事实源；已删除 API 出现在 usage/pitfalls 里会直接教错 AI。
targets += [root / 'packages/cli/catalog/components.yaml']


def marked_as_removed(line: str, start: int) -> bool:
    """true 表示该符号所在单元格 / 所在句子已经写明“已删除”。"""
    if line.lstrip().startswith('|'):
        cell_start = line.rfind('|', 0, start) + 1
        cell_end = line.find('|', start)
        cell = line[cell_start:cell_end if cell_end >= 0 else len(line)]
        return removal.search(cell) is not None
    sentence_start = max(
        (line.rfind(stop, 0, start) for stop in '。；;'),
        default=-1,
    ) + 1
    sentence_end = min(
        (index for index in (line.find(stop, start) for stop in '。；;') if index >= 0),
        default=len(line),
    )
    return removal.search(line, sentence_start, sentence_end + 1) is not None


bad: list[str] = []
for path in targets:
    if not path.is_file():
        continue
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        for pattern in patterns:
            hit = next(
                (match for match in pattern.finditer(line) if not marked_as_removed(line, match.start())),
                None,
            )
            if hit is not None:
                bad.append(f'{path.relative_to(root)}:{number}: {line.strip()[:100]}')
                break

if bad:
    print('文档/示例仍引用已删除 API：', file=sys.stderr)
    for item in bad:
        print(f'  ✗ {item}', file=sys.stderr)
    sys.exit(1)

print(f'✓ 已删除 API 未被推荐（{len(targets)} 个文件）')
