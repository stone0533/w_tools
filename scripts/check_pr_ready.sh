#!/usr/bin/env bash
#
# 开 PR 前在本地跑一遍 PR 级门禁（CI 里由 api-bump job 跑同一批检查）。
#
# 为什么需要它：check_pr_scope / check_version_bump 依赖 PR body 与 merge-base，
# 不在 preflight.sh 里；漏跑就只能等 CI 红，反馈慢一轮。
#
# 用法：
#   bash scripts/check_pr_ready.sh <pr-body.md> [base]
#   bash scripts/check_pr_ready.sh /tmp/pr.md            # base 默认 origin/main
#
# PR body 直接用你准备贴进 `gh pr create --body-file` 的那份文件。
#
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
body="${1:-}"
base="${2:-origin/main}"

if [ -z "$body" ] || [ ! -f "$body" ]; then
  echo "用法: bash scripts/check_pr_ready.sh <pr-body.md> [base]" >&2
  exit 2
fi

echo "== check_pr_scope（改动类型 / CHANGELOG / 版本）"
PR_BODY="$(cat "$body")" PR_CONTEXT=1 python3 "$root/scripts/check_pr_scope.py" --base "$base"

echo "== check_version_bump（公开 API 变化是否抬版本）"
python3 "$root/scripts/check_version_bump.py" --base "$base"

echo "✓ PR 级门禁通过（仍建议再跑 bash scripts/preflight.sh --with-tests）"
