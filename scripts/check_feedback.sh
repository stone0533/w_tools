#!/usr/bin/env bash
# 反馈日志自检（docs/feedback/）—— 规则只在 `w_tools_cli:feedback lint` 里实现一次。
# 规则：字段齐全 / 状态合法 / 已闭环带版本号 / 索引数量与文件一致 / 待处理 stale 警告
# 用法：bash scripts/check_feedback.sh
set -euo pipefail

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

exec dart run w_tools_cli:feedback lint --stale-days=30
