#!/usr/bin/env bash
#
# 只检查**已暂存**的 Dart 文件是否格式化（pre-commit 调用，<1s）。
#
# 为什么：format 门禁只在 preflight 里（--with-tests 约 12–15 分钟），
# 新建文件忘格式化要等一整轮才发现。这里把反馈提前到 commit 前。
#
# 用法：
#   bash scripts/format_staged.sh      # 有未格式化的 staged .dart 时 exit 1
#
# 不改文件、不动 index：失败时打印需要执行的命令，由你决定是否格式化。
#
set -euo pipefail

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

if dart format --output=none --set-exit-if-changed "${files[@]}"; then
  exit 0
fi

echo "" >&2
echo "✗ 已暂存的 Dart 文件未格式化。执行：" >&2
printf '  dart format %s\n' "${files[*]}" >&2
echo "然后重新 git add（或 git commit --no-verify 跳过本次检查）。" >&2
exit 1
