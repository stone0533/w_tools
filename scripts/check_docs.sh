#!/usr/bin/env bash
# 文档自检：相对链接、旧命令、包清单、硬编码版本表。
# 用法：bash scripts/check_docs.sh（CI 的 umbrella job 也会跑）
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

errors=0
note() {
  printf '✗ %s\n' "$*" >&2
  errors=$((errors + 1))
}

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# 1) 相对链接必须存在
python3 - "$tmp" <<'PY'
import pathlib
import re
import sys

out = pathlib.Path(sys.argv[1])
roots = ['docs', 'README.md', 'CONTRIBUTING.md', 'AGENTS.md', 'packages/cli/README.md']
files = []
for root in roots:
    p = pathlib.Path(root)
    if p.is_file():
        files.append(p)
    elif p.is_dir():
        files.extend(p.rglob('*.md'))

pat = re.compile(r'!?\[[^\]]*\]\(([^)]+)\)')
bad = []
for f in files:
    for m in pat.finditer(f.read_text()):
        target = m.group(1).strip()
        if target.startswith(('http://', 'https://', 'mailto:', '#')):
            continue
        target = target.split('#')[0].strip()
        if not target:
            continue
        if not (f.parent / target).resolve().exists():
            bad.append(f'{f} -> {target}')
out.write_text('\n'.join(bad))
PY
while IFS= read -r line; do
  [ -n "$line" ] && note "失效链接：$line"
done < "$tmp"

# 2) 不允许旧命令（CLI 已拆到 w_tools_cli）
if grep -rnE 'w_tools:(init|doctor)' doc docs README.md CONTRIBUTING.md AGENTS.md packages/cli/README.md >/dev/null 2>&1; then
  note '文档里还有旧命令 w_tools:init / w_tools:doctor（应为 w_tools_cli:...）'
  grep -rnE 'w_tools:(init|doctor)' doc docs README.md CONTRIBUTING.md AGENTS.md packages/cli/README.md >&2
fi

# 3) 新增包要出现在模块文档索引里
for dir in packages/*/; do
  name="w_tools_$(basename "$dir")"
  if ! grep -q "$name" docs/modules/README.md; then
    note "docs/modules/README.md 没有提到 $name（新增包要补进文档）"
  fi
done

# 4) 不再维护硬编码版本表
if grep -q '## 10. 子包版本' docs/modules/components.md; then
  note 'docs/modules/components.md 又出现硬编码版本表（应链接 pub.dev / pubspec）'
fi

if [ "$errors" -gt 0 ]; then
  printf '\n文档检查失败：%s 项\n' "$errors"
  exit 1
fi
printf '文档检查通过\n'
