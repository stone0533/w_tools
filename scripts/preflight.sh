#!/usr/bin/env bash
#
# 发布前门禁（静态检查默认全跑；测试 / dry-run 按需开启）。
#
# 用法：
#   bash scripts/preflight.sh                 # format / analyze / docs / 弃用 / feedback / release
#   bash scripts/preflight.sh --with-tests    # 再加所有包 + example + 根包测试
#   bash scripts/preflight.sh --with-dry-run  # 再加 13 个子包 + 根包 publish dry-run
#   bash scripts/preflight.sh --all           # 全部
#
# 退出码：任一步失败即非 0；dry-run 根包失败在子包未发布时是预期行为，
# 脚本会单独提示，但不会让整次门禁失败（用 --with-dry-run 时）。
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

with_tests=""
with_dry_run=""
for arg in "$@"; do
  case "$arg" in
    --with-tests) with_tests=1 ;;
    --with-dry-run) with_dry_run=1 ;;
    --all) with_tests=1; with_dry_run=1 ;;
    -h | --help)
      sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "未知参数: $arg" >&2
      exit 2
      ;;
  esac
done

failed=0
run() {
  local name="$1"
  shift
  echo "==> $name"
  if "$@"; then
    echo "    ✓ $name"
  else
    echo "    ✗ $name" >&2
    failed=1
  fi
}

run "format" dart format --output=none --set-exit-if-changed packages test example
run "analyze" flutter analyze
run "docs" bash scripts/check_docs.sh
run "doc symbols" python3 scripts/check_doc_symbols.py
run "removed API" python3 scripts/check_removed_api.py
run "public catalog" python3 scripts/check_public_catalog.py
run "style literals" python3 scripts/check_style_literals.py
run "deprecations" python3 scripts/check_deprecations.py
run "feedback" bash scripts/check_feedback.sh
run "release check" bash scripts/release_check.sh

if [ -n "$with_tests" ]; then
  for p in core async ui form api app app_getx toast map map_google qr e2e; do
    run "test packages/$p" bash -c "cd packages/$p && flutter test --reporter=compact"
  done
  for p in cli figma device; do
    run "test packages/$p" bash -c "cd packages/$p && dart test --reporter=compact"
  done
  run "test root" flutter test
  for p in api app_getx async core form map_google qr ui; do
    run "test packages/$p/example" bash -c "cd packages/$p/example && flutter test --reporter=compact"
  done
fi

if [ -n "$with_dry_run" ]; then
  for p in core async ui form api app app_getx toast map map_google qr cli figma device e2e; do
    run "publish dry-run packages/$p" bash scripts/publish_package.sh "packages/$p" --dry-run
  done
  echo "==> publish dry-run 根包（子包未发布时失败是预期）"
  if bash scripts/publish_package.sh . --dry-run; then
    echo "    ✓ 根包 dry-run"
  else
    echo "    ! 根包 dry-run 失败：仅在 13 个子包已上线后才应通过"
  fi
fi

if [ "$failed" -ne 0 ]; then
  echo "门禁失败" >&2
  exit 1
fi
echo "门禁通过"
