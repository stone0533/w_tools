#!/usr/bin/env python3
"""docs/agents 的索引与入口一致性检查。

规则只写一次，给两层文档兜底：

1. `docs/agents/README.md` 必须索引该目录下的每个文档（README 自己除外）；
2. 「各包首选入口」表里写出的入口类型，必须能在该包规则页（或被它直接链接的
   docs/agents 子页，例如 ui → button）里找到；
3. 同一张表的主入口符号，至少要有一个出现在根 `AGENTS.md`——防止某个包整节被删掉。

第 2 条治的是“索引表写了一个组件，规则页却从没提过”的漂移：
两张表各自维护时，AI 读到哪份就按哪份写。
"""
from __future__ import annotations

import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
agents = root / 'docs/agents'
readme = agents / 'README.md'
errors: list[str] = []

if not readme.exists():
    print('缺少 docs/agents/README.md', file=sys.stderr)
    sys.exit(2)

link_re = re.compile(r'\]\(([^)]+)\)')


def linked_pages(path: pathlib.Path) -> set[pathlib.Path]:
    """只取 docs/agents 内的直接链接（消费方的 ../../packages 之类不参与）。"""
    out: set[pathlib.Path] = set()
    for match in link_re.finditer(path.read_text()):
        target = match.group(1).strip().split('#')[0].strip()
        if not target or target.startswith(('http://', 'https://', 'mailto:')):
            continue
        candidate = (path.parent / target).resolve()
        if candidate.suffix == '.md' and agents.resolve() in candidate.parents:
            out.add(candidate)
    return out


# 1) 目录下的每个文档都要被索引。
indexed = linked_pages(readme)
for path in sorted(agents.glob('*.md')):
    if path.name == 'README.md':
        continue
    if path.resolve() not in indexed:
        errors.append(f'docs/agents/README.md: 没有索引 {path.name}')

# 2) 首选入口必须在该包规则页（或它直接链接的子页）里出现。
agents_md = (root / 'AGENTS.md').read_text()
table = re.search(r'## 各包首选入口.*?(?=\n## )', readme.read_text(), re.S)
if table is None:
    errors.append('docs/agents/README.md: 缺少「各包首选入口」一节')
else:
    rows = [line for line in table.group(0).splitlines() if line.startswith('|')][2:]
    for row in rows:
        cells = [cell.strip() for cell in row.strip().strip('|').split('|')]
        if len(cells) < 2:
            continue
        package, entry = cells[0], cells[1]
        page = agents / f'{package}.md'
        if not page.exists():
            continue  # cli / device / e2e 走工具文档，不按包规则页检查
        text = page.read_text()
        for linked in linked_pages(page):
            text += linked.read_text()
        entry_names = [
            match.group(1)
            for token in re.findall(r'`([^`]+)`', entry)
            if (match := re.match(r'(W[A-Za-z0-9_]+)', token))
        ]
        for name in entry_names:
            if name not in text:
                errors.append(
                    f'docs/agents/README.md: 「{package}」首选入口写了 {name}，'
                    f'但 {page.name} 从未提到它（索引与规则页不一致）',
                )
        if entry_names and not any(name in agents_md for name in entry_names):
            errors.append(
                f'AGENTS.md: 「{package}」的首选入口（{entry_names[0]} 等）一个都没提到，'
                f'该包的硬规则可能整节被删了',
            )

if errors:
    for error in errors:
        print(f'✗ {error}', file=sys.stderr)
    print(f'\ndocs/agents 一致性检查失败：{len(errors)} 项', file=sys.stderr)
    sys.exit(1)
print(f'docs/agents 一致性检查通过（{len(list(agents.glob("*.md"))) - 1} 个页面）')
