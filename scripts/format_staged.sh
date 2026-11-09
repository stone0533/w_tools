#!/usr/bin/env bash
#
# 只检查**已暂存**的 Dart 文件是否格式化（pre-commit 调用，<1s）。
#
# 为什么：format 门禁只在 preflight 里（全量档较慢），
# 新建文件忘格式化要等一整轮才发现。这里把反馈提前到 commit 前。
#
# 用法：
#   bash scripts/format_staged.sh      # 有未格式化的 staged .dart 时 exit 1
#
# 不改文件、不动 index：失败时打印需要执行的命令，由你决定是否格式化。
#
set -euo pipefail

# 与 preflight / CI 一致：非交互环境下 dart 不写 telemetry 会话文件。
export CI="${CI:-true}"

if ! root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "format_staged: 当前目录不在 git 仓库里" >&2
  exit 1
fi
cd "$root"

files=()
while IFS= read -r file; do
  [ -n "$file" ] && files+=("$file")
done < <(git diff --cached --name-only --diff-filter=ACM -- '*.dart')

if [ ${#files[@]} -eq 0 ]; then
  exit 0
fi

if ! command -v dart >/dev/null 2>&1; then
  echo "format_staged: 找不到 dart，跳过 staged 格式检查" >&2
  exit 0
fi

status=0
dart --suppress-analytics format --output=none --set-exit-if-changed "${files[@]}" || status=$?
case "$status" in
  0) exit 0 ;;
  1)
    echo "" >&2
    echo "✗ 已暂存的 Dart 文件未格式化。执行：" >&2
    printf '  dart format %s\n' "${files[*]}" >&2
    echo "然后重新 git add（或 git commit --no-verify 跳过本次检查）。" >&2
    exit 1
    ;;
  *)
    # 不能把环境 / 工具崩溃说成“文件未格式化”：那会让人去格式化已经正确的文件。
    echo "format_staged: dart format 执行失败（exit ${status}），这是环境 / 工具问题，不是格式问题" >&2
    exit 2
    ;;
esac
