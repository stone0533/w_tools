#!/usr/bin/env bash
# 发布前确认当前 PR 的 Required checks 已通过。
set -euo pipefail

pr="${1:-}"
if ! command -v gh >/dev/null 2>&1; then
  echo "未安装 gh；无法检查 PR checks。安装后重跑，或人工确认 CI。" >&2
  exit 2
fi
if [ -z "$pr" ]; then
  pr="$(gh pr view --json number -q .number)"
fi
gh pr checks "$pr" --required
