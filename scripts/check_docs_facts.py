#!/usr/bin/env python3
"""当前文档的事实一致性检查。

只检查“当前文档”，历史目录（migrations/adr/analysis/release）允许旧版本和旧数量。

检查六类事实：
1. 规模类数字（N 个库子包 / N 个 Flutter）从 pubspec 推导后与正文比对；
2. `docs/README.md` 必须索引每个顶层文档、子目录 README、没有 README 的目录下的文档，以及每个 ADR；
3. 每个带 README 的 docs 子目录，它的 README 必须索引本目录下所有文档；
4. 当前文档不得再使用旧命令入口；
5. ADR 编号 / 状态行 / 索引状态与日期 / 补充日期 / 已取代链接；
6. doctor 的 R1~R9 规则表在 conventions 与 CLI README 中 id / 级别一致。

第 1 条用推导而不是“记住几个过期数字”：包数量变化时这里不需要改代码。
"""
from __future__ import annotations

import pathlib
import re
import sys
import yaml

root = pathlib.Path(__file__).resolve().parent.parent
historical = {'migrations', 'adr', 'analysis', 'releases'}
files: list[pathlib.Path] = [root / 'README.md', root / 'AGENTS.md', root / 'CONTRIBUTING.md', root / 'scripts/README.md']
for base in ['docs', 'packages']:
    for path in (root / base).rglob('*.md'):
        rel = path.relative_to(root)
        if base == 'docs' and len(rel.parts) > 1 and rel.parts[1] in historical:
            continue
        if base == 'packages' and ('example' in rel.parts or path.name == 'CHANGELOG.md'):
            continue
        files.append(path)

errors: list[str] = []

# 包数量 / 根聚合关系从 pubspec 推导，避免文档写死过期数字。
TOOLS = {'w_tools_cli', 'w_tools_figma', 'w_tools_device', 'w_tools_e2e'}
packages = {}
for pubspec in (root / 'packages').glob('*/pubspec.yaml'):
    data = yaml.safe_load(pubspec.read_text())
    packages[data['name']] = data
library_packages = set(packages) - TOOLS
flutter_library = {
    name for name in library_packages
    if packages[name].get('environment', {}).get('flutter')
}

modules_readme = root / 'docs/modules/README.md'
if modules_readme.exists():
    text = modules_readme.read_text()
    expected = f'**{len(library_packages)} 个库子包**'
    if expected not in text:
        errors.append(f'docs/modules/README.md: 缺少当前包数量 {expected}')
    for name in sorted(library_packages):
        if name not in text:
            errors.append(f'docs/modules/README.md: 没有列出 {name}')

root_pubspec = yaml.safe_load((root / 'pubspec.yaml').read_text())
root_aggregate = {
    name for name in (root_pubspec.get('dependencies') or {})
    if str(name).startswith('w_tools_')
}
if modules_readme.exists():
    text = modules_readme.read_text()
    for name in sorted(root_aggregate):
        if name not in text:
            errors.append(f'docs/modules/README.md: 根聚合包 {name} 未说明')

# 1) 规模类数字必须与推导值一致（不再维护“哪些数字算过期”的清单）。
module_docs = sorted((root / 'docs/modules').glob('*_module.md'))
scale = {
    '库子包': len(library_packages),
    'Flutter': len(flutter_library),
    '包': len(packages),
    '份模块文档': len(module_docs),
}
for path in files:
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        for label, expected in scale.items():
            for match in re.finditer(rf'(\d+)\s*个\s*{label}', line):
                actual = int(match.group(1))
                if actual != expected:
                    errors.append(
                        f'{path.relative_to(root)}:{number}: 写「{actual} 个 {label}」，'
                        f'按 pubspec 推导应为 {expected}',
                    )

# 2) docs/README.md 是文档索引：顶层文档 / 子目录 README / 无 README 目录下的文档都要有链接。
link_re = re.compile(r'!?\[[^\]]*\]\(([^)]+)\)')


def linked_targets(path: pathlib.Path) -> set[pathlib.Path]:
    targets: set[pathlib.Path] = set()
    for match in link_re.finditer(path.read_text()):
        target = match.group(1).strip().split('#')[0].strip()
        if not target or target.startswith(('http://', 'https://', 'mailto:')):
            continue
        targets.add((path.parent / target).resolve())
    return targets


docs_index = root / 'docs/README.md'
if docs_index.exists():
    indexed = linked_targets(docs_index)
    for path in sorted((root / 'docs').rglob('*.md')):
        rel = path.relative_to(root / 'docs')
        if rel == pathlib.Path('README.md'):
            continue
        indexed_by_dir = (path.parent / 'README.md').exists()
        if len(rel.parts) > 1 and rel.name != 'README.md' and indexed_by_dir:
            continue  # 子目录文档由该目录 README 负责
        if path.resolve() not in indexed:
            errors.append(f'docs/README.md: 没有索引 docs/{rel.as_posix()}')
    # ADR 在总索引里逐条列出（带一句摘要）；有 adr/README 不代表总索引可以漏。
    for path in sorted((root / 'docs/adr').glob('*.md')):
        if path.name == 'README.md':
            continue
        if path.resolve() not in indexed:
            errors.append(
                f'docs/README.md: 没有索引 docs/adr/{path.name}（新增 ADR 要在总索引留一行）',
            )
else:
    errors.append('缺少 docs/README.md')

# 3) 每个子目录的 README 必须索引本目录下的所有文档。
for readme in sorted((root / 'docs').glob('*/README.md')):
    indexed = linked_targets(readme)
    for path in sorted(readme.parent.glob('*.md')):
        if path.name == 'README.md':
            continue
        if path.resolve() not in indexed:
            errors.append(f'{readme.relative_to(root)}: 没有索引 {path.name}')

# 4) 当前文档不得再使用旧命令入口。
for path in files:
    if re.search(
        r'dart run w_tools_cli:(context|list|explain|doctor|init|feedback|upgrade)', path.read_text()
    ):
        errors.append(f'{path.relative_to(root)}: 仍用旧命令入口（应为 w_tools_cli:w_tools ...）')

# 5) ADR：编号唯一且递增、文件命名规范、有状态行；索引状态/日期与正文一致；
#    「已取代」必须有 Superseded by 链接；「补充 / 修订」必须带日期。
adr_dir = root / 'docs/adr'
adrs = sorted(path for path in adr_dir.glob('*.md') if path.name != 'README.md')
seen: set[int] = set()
last = 0
adr_status: dict[str, str] = {}
for path in adrs:
    match = re.match(r'^(\d{4})-[a-z0-9-]+\.md$', path.name)
    if not match:
        errors.append(f'docs/adr/{path.name}: 文件名应形如 NNNN-kebab-title.md')
        continue
    number = int(match.group(1))
    if number in seen:
        errors.append(f'docs/adr/{path.name}: 编号 {number:04d} 重复')
    if number <= last:
        errors.append(f'docs/adr/{path.name}: 编号必须递增（退役编号可以留空，但不能复用）')
    seen.add(number)
    last = max(last, number)
    text = path.read_text()
    status = re.search(r'^- 状态：(.+)$', text, re.M)
    if not status:
        errors.append(f'docs/adr/{path.name}: 缺少「- 状态：…」行')
        continue
    adr_status[path.name] = status.group(1).strip()
    if status.group(1).strip().startswith('已取代') and not re.search(
        r'Superseded by \[ADR-\d{4}\]',
        text,
    ):
        errors.append(
            f'docs/adr/{path.name}: 状态是「已取代」，但缺少 Superseded by [ADR-000N] 链接',
        )
    for heading in re.findall(r'^##\s*(?:补充|修订)[^\n]*$', text, re.M):
        if not re.search(r'\d{4}-\d{2}-\d{2}', heading):
            errors.append(
                f'docs/adr/{path.name}: 「{heading.strip()}」缺少日期（YYYY-MM-DD）',
            )

adr_index = adr_dir / 'README.md'
if adr_index.exists():
    indexed_files: set[str] = set()
    for line in adr_index.read_text().splitlines():
        match = re.match(
            r'\|\s*\[(\d{4})\]\(([^)]+)\)\s*\|[^|]*\|\s*([^|]+?)\s*\|\s*(\d{4}-\d{2}-\d{2})\s*\|',
            line,
        )
        if not match:
            continue
        number, filename, index_status, index_date = match.groups()
        indexed_files.add(filename)
        body_status = adr_status.get(filename)
        if body_status is None:
            if not (adr_dir / filename).exists():
                errors.append(f'docs/adr/README.md: 索引引用了不存在的文件 {filename}')
            continue
        head = lambda value: re.split(r'[（(]', value)[0].strip()  # noqa: E731
        if head(index_status) != head(body_status):
            errors.append(
                f'docs/adr/README.md: {number} 索引状态「{index_status}」'
                f'与正文「{body_status}」不一致',
            )
        body_dates = re.findall(r'\d{4}-\d{2}-\d{2}', body_status)
        if body_dates and body_dates[0] != index_date:
            errors.append(
                f'docs/adr/README.md: {number} 索引日期 {index_date} '
                f'与正文状态日期 {body_dates[0]} 不一致',
            )
    for path in adrs:
        if path.name not in indexed_files:
            errors.append(f'docs/adr/README.md: 没有索引 {path.name}')

# 6) doctor 规则表必须在 conventions 与 CLI README 中一致（同一份规则，两个展示面）。
def doctor_rule_table(path: pathlib.Path) -> dict[str, str]:
    table: dict[str, str] = {}
    for line in path.read_text().splitlines():
        match = re.match(r'\|\s*(R[1-9])\s*\|\s*([^|]+?)\s*\|', line)
        if match:
            table[match.group(1)] = match.group(2).strip()
    return table


conventions = root / 'docs/conventions.md'
cli_readme = root / 'packages/cli/README.md'
if conventions.exists() and cli_readme.exists():
    in_conventions = doctor_rule_table(conventions)
    in_cli = doctor_rule_table(cli_readme)
    for rule in sorted(set(in_conventions) | set(in_cli)):
        if in_conventions.get(rule) != in_cli.get(rule):
            errors.append(
                f'doctor 规则表不一致：{rule} 在 conventions.md 是 '
                f'{in_conventions.get(rule)}，在 packages/cli/README.md 是 {in_cli.get(rule)}',
            )

if errors:
    for error in errors:
        print(f'✗ {error}', file=sys.stderr)
    sys.exit(1)
print('当前文档事实检查通过')
