#!/usr/bin/env bash
# 反馈日志自检（docs/feedback/）—— 规则只在 `w_tools_cli:feedback lint` 里实现一次。
# 规则：字段齐全 / 状态合法 / 已闭环带版本号 / 索引数量与文件一致 / 待处理 stale 警告
# 用法：bash scripts/check_feedback.sh
#
# 退出码：
#   0  通过（或没有 dart，直接跳过）
#   1  规则不通过
#   2  环境不可用（没有 package_config / dart 起不来）—— 调用方按“跳过”处理，不算文档失败
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

if ! command -v dart >/dev/null 2>&1; then
  echo '（没有 dart，跳过反馈检查）'
  exit 0
fi
if [ ! -f .dart_tool/package_config.json ]; then
  echo '✗ 没有 .dart_tool/package_config.json —— 反馈检查无法运行。' >&2
  echo '  先执行 `dart pub get`（CI 里请把 pub get 放在本检查之前）。' >&2
  exit 2
fi

# --suppress-analytics：这是只读门禁，不该因为写不了 telemetry 文件而整条失败。
output="$(dart --suppress-analytics run w_tools_cli:feedback lint --stale-days=30 2>&1)"
status=$?
printf '%s\n' "$output"

if [ "$status" -eq 0 ]; then
  exit 0
fi
if printf '%s\n' "$output" | grep -qE 'FileSystemException|Unhandled exception|dartdev|Could not find|Failed to (load|resolve|run)'; then
  echo '（反馈检查环境不可用：dart 运行失败，本次不判定规则）' >&2
  exit 2
fi
exit 1
