#!/usr/bin/env bash
# 文档自检：链接、旧命令、安装版本、符号 / 根包导出、已删除 API、索引、docs/agents 一致性。
# 用法：bash scripts/check_docs.sh（preflight 与 CI 都会跑）
#
# 每一步都会打出自己的名字：失败时能直接看出是哪一步，而不是只看到子脚本的堆栈。
# 只有显式标了 step_optional 的步骤，退出码 2 才会按“环境不可用”跳过。
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

# 多数检查脚本 import yaml；缺依赖时给一句可执行的提示，而不是让 python 抛堆栈。
if ! python3 -c 'import yaml' >/dev/null 2>&1; then
  echo "缺少 PyYAML：python3 -m pip install pyyaml（CI 的 venv 会自动安装）" >&2
  exit 2
fi

errors=0
_step() {
  local allow_skip="$1" label="$2"
  shift 2
  local output status
  output="$("$@" 2>&1)"
  status=$?
  if [ "$status" -eq 0 ]; then
    printf '✓ %s\n' "$label"
  elif [ "$allow_skip" -eq 1 ] && [ "$status" -eq 2 ]; then
    printf '! %s（环境不可用，跳过）\n' "$label"
    [ -n "$output" ] && printf '%s\n' "$output" | sed 's/^/    /'
  else
    printf '✗ %s\n' "$label" >&2
    [ -n "$output" ] && printf '%s\n' "$output" | sed 's/^/    /' >&2
    errors=$((errors + 1))
  fi
}

step() { _step 0 "$@"; }
# 依赖 dart 运行时的检查：环境不可用（退出码 2）时跳过，不把环境问题算成文档失败。
step_optional() { _step 1 "$@"; }

# 1) 相对链接必须存在
check_links() {
  local tmp bad=0 python_status=0
  tmp="$(mktemp)"
  python3 - "$tmp" <<'PY' || python_status=$?
import pathlib
import re
import sys

out = pathlib.Path(sys.argv[1])
roots = [
    'docs',
    'README.md',
    'CONTRIBUTING.md',
    'AGENTS.md',
    'packages/cli/README.md',
    'scripts/README.md',
]
files = []
for root in roots:
    p = pathlib.Path(root)
    if p.is_file():
        files.append(p)
    elif p.is_dir():
        files.extend(p.rglob('*.md'))
# 包 README / 包 AGENTS / example README 也属于推荐阅读路径，链接同样要能点开。
for pattern in ('packages/*/README.md', 'packages/*/AGENTS.md', 'packages/*/example/README.md'):
    files.extend(pathlib.Path('.').glob(pattern))
files = sorted(set(files))

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
# 必须带尾换行：调用方用 `while read` 读，最后一行没有分隔符时会被整行丢掉。
out.write_text('\n'.join(bad) + ('\n' if bad else ''))
PY
  if [ "$python_status" -ne 0 ]; then
    printf '链接检查脚本执行失败（python 退出 %s）\n' "$python_status" >&2
    rm -f "$tmp"
    return 1
  fi
  # `|| [ -n "$line" ]`：即使上面的写端忘了补尾换行，也不能静默漏掉最后一条。
  while IFS= read -r line || [ -n "$line" ]; do
    [ -n "$line" ] || continue
    printf '✗ 失效链接：%s\n' "$line" >&2
    bad=1
  done < "$tmp"
  rm -f "$tmp"
  return "$bad"
}

# 2) 不允许旧命令（CLI 已拆到 w_tools_cli）
check_old_commands() {
  local hits
  hits="$(grep -rnE 'w_tools:(init|doctor)' docs README.md CONTRIBUTING.md AGENTS.md packages/cli/README.md 2>/dev/null || true)"
  [ -z "$hits" ] && return 0
  printf '文档里还有旧命令 w_tools:init / w_tools:doctor（应为 w_tools_cli:...）\n' >&2
  printf '%s\n' "$hits" >&2
  return 1
}

# 3) 新增包要出现在模块文档索引里
check_package_index() {
  local dir name missing=0
  for dir in packages/*/; do
    name="w_tools_$(basename "$dir")"
    if ! grep -q "$name" docs/modules/README.md; then
      printf 'docs/modules/README.md 没有提到 %s（新增包要补进文档）\n' "$name" >&2
      missing=1
    fi
  done
  return "$missing"
}

# 4) 不再维护硬编码版本表
check_no_version_table() {
  if grep -q '## 10. 子包版本' docs/modules/components.md; then
    printf 'docs/modules/components.md 又出现硬编码版本表（应链接 pub.dev / pubspec）\n' >&2
    return 1
  fi
}

step '相对链接' check_links
step '旧命令' check_old_commands
step '模块索引包覆盖' check_package_index
step '组件目录版本表' check_no_version_table
step '文档片段与表格列数' python3 scripts/check_docs_snippets.py
step 'modules/README 重复示例' python3 scripts/check_docs_duplicates.py --fail
step '版本声明' python3 scripts/check_docs_versions.py
step_optional '反馈台账' bash scripts/check_feedback.sh
step 'async 旧 API' python3 scripts/check_async_docs.py
step '安装约束 / 示例' python3 scripts/check_package_docs.py
step '文档符号 / import 边界' python3 scripts/check_doc_symbols.py
step '已删除 API' python3 scripts/check_removed_api.py
# 这两项只读 .md / yaml，必须留在 docs-only 也会跑的这一层（preflight 可能被 CI 路径过滤跳过）。
step 'catalog 锚点' python3 scripts/check_catalog_anchors.py
step '教学覆盖' python3 scripts/check_teaching_coverage.py
step '当前文档事实' python3 scripts/check_docs_facts.py
step '维护者提示词' python3 scripts/check_prompt_docs.py
step 'docs/agents 索引与入口' python3 scripts/check_agents_consistency.py

if [ "$errors" -gt 0 ]; then
  printf '\n文档检查失败：%s 项\n' "$errors"
  exit 1
fi
printf '文档检查通过\n'
