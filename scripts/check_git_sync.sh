#!/usr/bin/env bash
# 检查当前分支有 upstream，且 ahead/behind 都为 0。
set -euo pipefail

root="${1:-.}"
cd "$root"

if ! git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
  echo "当前分支没有 upstream；发布前先 git push -u" >&2
  exit 1
fi

upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}')"
ahead="$(git rev-list --count '@{u}..HEAD')"
behind="$(git rev-list --count 'HEAD..@{u}')"

if [ "${ahead}" -ne 0 ]; then
  echo "有 ${ahead} 个提交未 push（${upstream}）；发布前先 git push" >&2
  exit 1
fi
if [ "$behind" -ne 0 ]; then
  echo "落后 $upstream $behind 个提交；先同步再发布" >&2
  exit 1
fi
echo "✓ 已 push（${upstream}）"
