#!/usr/bin/env bash
# 发布脚本共用的 GitHub CLI 辅助函数。source 使用，不要直接执行。
#
# 用法：
#   source "$root/scripts/_gh.sh"
#   gh_wait_checks <pr-number> [timeout-seconds]
#
# 为什么不能直接 `gh pr checks --watch`：PR 刚创建时 checks 尚未注册，
# `gh pr checks --watch` 会立刻以 "no checks reported" 退出，调用方误以为
# 已经通过并提前合并（PR #114 / #134 都复现过）。这里先等 statusCheckRollup
# 非空，再交给 --watch。
#
# 文件名以下划线开头：check_gate_coverage 不把它当成面向用户的脚本。

gh_wait_checks() {
  local pr="${1:?usage: gh_wait_checks <pr-number> [timeout-seconds]}"
  local timeout="${2:-300}"
  local interval="${GH_WAIT_INTERVAL:-2}"
  local waited=0
  local count=0

  while [ "$waited" -lt "$timeout" ]; do
    count="$(gh pr view "$pr" --json statusCheckRollup \
      --jq '(.statusCheckRollup // []) | length' 2>/dev/null || echo 0)"
    if [ "$count" -gt 0 ]; then
      break
    fi
    sleep "$interval"
    waited=$((waited + interval))
  done

  if [ "$count" -eq 0 ]; then
    echo "✗ PR #${pr} 在 ${timeout}s 内没有注册任何 checks；拒绝自动合并（确认 workflow 已触发 / 启用）。" >&2
    return 1
  fi

  gh pr checks "$pr" --watch
}
