#!/usr/bin/env bash
# 定向变异：临时破坏一段「被守逻辑」，确认目标用例变红，然后无条件还原。
#
# 用途：证明「这条用例真的在守东西」，而不是只断言了「不抛异常」。
# 变异后测试仍然通过 → 要么用例空转（去改用例），要么这个守卫没有价值（去删守卫）。
#
# 用法：
#   bash scripts/mutate_guard.sh \
#     --file <文件> --from '<被守逻辑原文>' --to '<替换成的任何东西>' \
#     -- <测试命令...>
#
# 例（form 的多选弹层 mounted 守卫）：
#   bash scripts/mutate_guard.sh \
#     --file packages/form/lib/src/components/fields/multi_dropdown_field.dart \
#     --from 'if (!state.mounted) return;' --to '// mutated' \
#     -- cd packages/form && flutter test test/form_gaps_test.dart --plain-name "multi 弹层打开后字段卸载"
#
# 约定：
# - 变异点必须**恰好命中 1 处**（0 处或 >1 处直接报错，避免改错位置造成假红）；
# - 目标用例在变异后必须**非 0 退出**，否则本脚本返回 1；
# - 无论成功失败（含 Ctrl-C），trap 都会把文件还原；
# - 这是**人工工具**，不进 preflight / CI（见 scripts/check_gate_coverage.py 的 MANUAL）。
set -euo pipefail

file=''
from=''
to=''
while [ $# -gt 0 ]; do
  case "$1" in
    --file) file="$2"; shift 2 ;;
    --from) from="$2"; shift 2 ;;
    --to)   to="$2";   shift 2 ;;
    --)     shift; break ;;
    -h|--help) sed -n '2,26p' "$0"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
done
if [ -z "$file" ] || [ -z "$from" ] || [ $# -eq 0 ]; then
  echo "用法: bash scripts/mutate_guard.sh --file <f> --from '<old>' --to '<new>' -- <测试命令...>" >&2
  exit 2
fi
[ -f "$file" ] || { echo "文件不存在: ${file}" >&2; exit 2; }

backup="$(mktemp)"
cp "$file" "$backup"
restore() {
  cp "$backup" "$file"
  rm -f "$backup"
}
trap restore EXIT INT TERM

python3 - "$file" "$from" "$to" <<'PY'
import pathlib
import sys

path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
p = pathlib.Path(path)
text = p.read_text()
hits = text.count(old)
if hits != 1:
    sys.exit(f'变异点必须恰好命中 1 处，实际 {hits} 处：{old!r}')
p.write_text(text.replace(old, new))
PY

out="$(mktemp)"
set +e
"$@" >"$out" 2>&1
code=$?
set -e
tail -n 5 "$out"
rm -f "$out"

if [ "$code" -eq 0 ]; then
  echo '✗ 变异存活：测试仍然通过 —— 用例没守住这段逻辑（或守卫本身无价值）' >&2
  exit 1
fi
echo "✓ 变异被杀死：目标用例变红（exit=${code}），已还原 ${file}"
