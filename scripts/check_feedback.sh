#!/usr/bin/env bash
# 反馈日志自检（docs/feedback/）：
#  1. 已闭环条目必须带版本号（✅ [包] x.y.z）
#  2. README 索引表里的「待处理」数量必须与实际一致
#  3. 待处理超过 30 天 → 只警告，不失败
# 用法：bash scripts/check_feedback.sh
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

[ -d docs/feedback ] || { echo "（没有 docs/feedback，跳过）"; exit 0; }

python3 - <<'PY'
import datetime
import pathlib
import re
import sys

base = pathlib.Path('docs/feedback')
errors: list[str] = []
warns: list[str] = []
today = datetime.date.today()

closed_version = re.compile(r'✅\s*(?:[A-Za-z_]+\s+)?\d+\.\d+\.\d+')
index_row = re.compile(r'^\|\s*\[([a-z_]+)\]\([^)]+\)\s*\|\s*(\d+)\s*\|', re.M)

readme = (base / 'README.md').read_text()
indexed = {m.group(1): int(m.group(2)) for m in index_row.finditer(readme)}

for f in sorted(base.glob('*.md')):
    if f.name in {'README.md', 'TEMPLATE.md'}:
        continue
    text = f.read_text()
    pkg = f.stem

    # 1) 已闭环行必须带版本号
    for line in text.splitlines():
        if re.match(r'^\| \d{4}-\d{2}-\d{2} ', line) and not closed_version.search(line):
            errors.append(f'{f} 已闭环条目缺少版本号：{line[:70]}')

    # 2) 索引数量一致
    pending = len(re.findall(r'^### \[待处理\]', text, re.M))
    if pkg in indexed and indexed[pkg] != pending:
        errors.append(f'docs/feedback/README.md 里 {pkg} 写 {indexed[pkg]} 条待处理，实际 {pending} 条')

    # 3) stale 警告
    for m in re.finditer(r'状态变更：(\d{4}-\d{2}-\d{2})', text):
        try:
            d = datetime.date.fromisoformat(m.group(1))
        except ValueError:
            continue
        age = (today - d).days
        if age > 30:
            warns.append(f'{f} 的待处理条目已挂 {age} 天（状态变更 {d}）')

for w in warns:
    print(f'! {w}', file=sys.stderr)
if errors:
    for e in errors:
        print(f'✗ {e}', file=sys.stderr)
    print(f'\n反馈日志检查失败：{len(errors)} 项', file=sys.stderr)
    sys.exit(1)
print(f'反馈日志检查通过（{len(warns)} 条警告）')
PY
