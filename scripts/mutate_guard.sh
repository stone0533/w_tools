#!/usr/bin/env bash
# 定向变异：临时破坏一段「被守逻辑」，确认目标用例变红，然后无条件还原。
#
# 用途：证明「这条用例真的在守东西」，而不是只断言了「不抛异常」。
# 变异后测试仍然通过 → 用例空转（去改用例）；若用例改到能红，再确认守卫本身有价值。
#
# 用法：
#   bash scripts/mutate_guard.sh \
#     --file <文件> --from '<被守逻辑原文>' --to '<替换成的任何东西>' \
#     [--expect '<失败输出里必须出现的特征串>'] [--timeout <秒，默认 600，0=不限制>] \
#     -- bash -c '<测试命令>'
#
# 例（form 的多选弹层 mounted 守卫）：
#   bash scripts/mutate_guard.sh \
#     --file packages/form/lib/src/components/fields/multi_dropdown_field.dart \
#     --from 'if (!state.mounted) return;' --to '// mutated' \
#     --expect 'after dispose' \
#     -- bash -c 'cd packages/form && flutter test test/form_gaps_test.dart --plain-name "multi 弹层打开后字段卸载"'
#
# 为什么测试命令必须 `bash -c '...'`：
#   直接写 `-- cd packages/form && flutter test ...` 会被**调用方 shell** 按 && 拆开，
#   脚本只收到 `cd packages/form`：在仓库根跑会报「变异存活」，在 packages/form 里跑会报
#   「变异被杀死」，两次测试其实都没跑。本脚本会拦下第一个词是 cd 的写法。
#
# 退出码：
#   0 = 变异被杀死（用例有效）
#   1 = 变异存活（用例空转 / 守卫无价值）
#   2 = 无效（参数错、命令被拆、编译/加载失败、没匹配到用例、没出现 --expect 特征、超时）
#   3 = 还原失败（备份路径会打在 stderr）
#
# 约定：
# - 变异点必须**恰好命中 1 处**（0 处或 >1 处直接报错，避免改错位置造成假红）；
# - 给了 --expect 时，输出必须包含该特征串，避免把「编译失败」当成「用例变红」；
# - 无论成功失败（含 Ctrl-C），trap 都会还原文件，并用 cmp 校验还原结果；
# - 这是**人工工具**，不进 preflight / CI（见 scripts/check_gate_coverage.py 的 MANUAL）。
set -euo pipefail

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

file=''
from=''
to=''
expect=''
timeout=600
while [ $# -gt 0 ]; do
  case "$1" in
    --file) file="${2:-}"; shift 2 ;;
    --from) from="${2:-}"; shift 2 ;;
    --to) to="${2:-}"; shift 2 ;;
    --expect) expect="${2:-}"; shift 2 ;;
    --timeout) timeout="${2:-}"; shift 2 ;;
    --) shift; break ;;
    -h|--help) usage; exit 0 ;;
    *) echo "未知参数: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ -z "$file" ] || [ -z "$from" ] || [ $# -eq 0 ]; then
  echo '缺少参数：--file / --from / 测试命令（-- 之后）' >&2
  usage >&2
  exit 2
fi
if [ "$from" = "$to" ]; then
  echo '--from 与 --to 相同：这次变异什么也没改' >&2
  exit 2
fi
case "$timeout" in
  ''|*[!0-9]*) echo "--timeout 必须是整数秒：${timeout}" >&2; exit 2 ;;
esac
[ -f "$file" ] || { echo "文件不存在: $file" >&2; exit 2; }

# 单个参数里带 && 时，多半是整条命令被引号包住了：直接交给 bash -c。
case "$1" in
  *'&&'*) set -- bash -c "$1" ;;
esac
if [ "$1" = 'cd' ]; then
  echo '测试命令像是被 && 拆开了：脚本只收到 `cd ...`，实际用例没跑。' >&2
  echo "请写成 -- bash -c 'cd <目录> && <测试命令>'" >&2
  exit 2
fi

run_command() {
  if [ "$timeout" -le 0 ]; then
    "$@"
    return
  fi
  if command -v timeout >/dev/null 2>&1; then
    timeout "$timeout" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$timeout" "$@"
  elif command -v perl >/dev/null 2>&1; then
    perl -e 'alarm shift; exec @ARGV or die "exec: $!\n"' "$timeout" "$@"
  else
    echo '⚠ 找不到 timeout / gtimeout / perl：本次不设超时，卡住请 Ctrl-C（会还原）' >&2
    "$@"
  fi
}

# 变异前先跑一遍未变异的命令：基线必须绿，否则“变异后红”不能证明任何事。
# 例如用例本来就缺依赖 / 断言写错时，任何变异都会让命令 exit 1，旧实现会把它
# 误报成「变异被杀死」。
baseline_out="$(mktemp)"
set +e
run_command "$@" >"$baseline_out" 2>&1
baseline_code=$?
set -e
if [ "$baseline_code" -ne 0 ]; then
  printf '✗ 变异前基线不绿（exit=%s）：测试命令在未变异代码上已经失败，这次红不能证明任何事。\n' "$baseline_code" >&2
  printf '%s\n' '--- 基线输出（末尾 10 行）---' >&2
  tail -n 10 "$baseline_out" >&2
  rm -f "$baseline_out"
  exit 2
fi
rm -f "$baseline_out"

backup="$(mktemp)"
cp "$file" "$backup"
restored=0
restore() {
  if [ "$restored" -eq 1 ]; then
    return 0
  fi
  trap - EXIT INT TERM
  cp "$backup" "$file"
  if cmp -s "$backup" "$file"; then
    rm -f "$backup"
    restored=1
  else
    echo "✗ 还原失败：${file} 与备份不一致（备份：${backup}，请手工恢复）" >&2
    exit 3
  fi
}
on_signal() {
  restore
  echo "已中止，${file} 已还原" >&2
  exit 130
}
trap restore EXIT
trap on_signal INT TERM

if ! line="$(python3 - "$file" "$from" "$to" <<'PY'
import pathlib
import sys

path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
p = pathlib.Path(path)
text = p.read_text()
hits = text.count(old)
if hits != 1:
    sys.exit(f'变异点必须恰好命中 1 处，实际 {hits} 处：{old!r}')
line = text[:text.index(old)].count('\n') + 1
p.write_text(text.replace(old, new, 1))
print(line)
PY
)"; then
  exit 2
fi

printf '▶ 变异 %s:%s\n' "$file" "$line"
printf '  - %s\n' "$from"
printf '  + %s\n' "$to"

out="$(mktemp)"
set +e
run_command "$@" >"$out" 2>&1
code=$?
set -e

printf '%s\n' '--- 测试输出（末尾 10 行）---'
tail -n 10 "$out"
printf '%s\n' '--------------------------------'

rc=0
if [ "$code" -eq 124 ] || [ "$code" -eq 142 ]; then
  msg="✗ 超时：命令在 ${timeout}s 内没有结束——这次没有证明任何东西"
  rc=2
elif grep -q 'No tests ran' "$out"; then
  msg='✗ 无效：没有用例被匹配到（没跑就等于没验证）'
  rc=2
elif [ "$code" -eq 127 ] || [ "$code" -eq 126 ]; then
  msg="✗ 无效：测试命令没跑起来（exit=${code}，命令不存在 / 不可执行）"
  rc=2
elif [ "$code" -ge 128 ]; then
  msg="✗ 无效：命令被信号中断（exit=${code}），没有产生断言失败"
  rc=2
elif [ "$code" -eq 0 ]; then
  msg='✗ 变异存活：测试仍然通过——用例没守住这段逻辑（或守卫本身无价值）'
  rc=1
elif grep -qE 'Compilation failed|Failed to load' "$out"; then
  msg='✗ 无效变异：测试没跑起来（编译/加载失败），这次红不算数'
  rc=2
elif [ -n "$expect" ] && ! grep -qF -- "$expect" "$out"; then
  msg="✗ 变异红了，但输出里没有预期特征：${expect}——换个变异点，或补 --expect"
  rc=2
else
  msg="✓ 变异被杀死：目标用例变红（exit=${code}），已还原 ${file}"
fi

rm -f "$out"
restore
if [ "$rc" -eq 0 ]; then
  echo "$msg"
else
  echo "$msg" >&2
fi
exit "$rc"
