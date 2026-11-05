#!/usr/bin/env bash
#
# 发布前门禁（静态检查默认全跑；测试 / dry-run 按需开启）。
#
# 用法：
#   bash scripts/preflight.sh                 # format / analyze / docs（含 feedback）/ 弃用 / catalog / release
#   bash scripts/preflight.sh --with-tests    # 再加所有包 + example + 根包测试 + 模板编译
#   bash scripts/preflight.sh --with-dry-run  # 再加全部子包 + 根包 publish dry-run
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

run "format" dart --suppress-analytics format --output=none --set-exit-if-changed packages test example
run "analyze" flutter analyze
run "docs" bash scripts/check_docs.sh
run "doc symbols" python3 scripts/check_doc_symbols.py
run "removed API" python3 scripts/check_removed_api.py
run "public catalog" python3 scripts/check_public_catalog.py
run "style literals" python3 scripts/check_style_literals.py
run "deprecations" python3 scripts/check_deprecations.py
run "release check" bash scripts/release_check.sh
# CI 的包矩阵与静态门禁必须从 manifest / preflight 派生，不能手抄一份。
run "ci parity" python3 scripts/ci_matrix.py --check

if [ -n "$with_tests" ]; then
  while IFS='|' read -r name path runner aggregate example; do
    case "$name" in ''|'#'*) continue ;; esac
    case "$runner" in
      flutter) run "test $name" bash -c "cd $path && flutter test --reporter=compact" ;;
      dart) run "test $name" bash -c "cd $path && dart test --reporter=compact" ;;
      *) echo "未知 runner: $name=$runner" >&2; failed=1 ;;
    esac
  done < "$root/scripts/packages.manifest"
  run "test root" flutter test
  run "test example" bash -c "cd example && flutter test --reporter=compact"
  while IFS='|' read -r name path runner aggregate example; do
    case "$name" in ''|'#'*) continue ;; esac
    if [ "$example" = "example" ]; then
      run "test $name/example" bash -c "cd $path/example && flutter test --reporter=compact"
    fi
  done < "$root/scripts/packages.manifest"
  run "template compile" bash -c "cd packages/cli && dart run tool/check_templates_compile.dart"
fi

if [ -n "$with_dry_run" ]; then
  while IFS='|' read -r name path runner aggregate example; do
    case "$name" in ''|'#'*) continue ;; esac
    run "publish dry-run $name" bash scripts/publish_package.sh "$path" --dry-run
  done < "$root/scripts/packages.manifest"
  echo "==> publish dry-run 根包（子包未发布时失败是预期）"
  if bash scripts/publish_package.sh . --dry-run; then
    echo "    ✓ 根包 dry-run"
  else
    echo "    ! 根包 dry-run 失败：仅在全部子包已上线后才应通过"
  fi
fi

if [ "$failed" -ne 0 ]; then
  echo "门禁失败" >&2
  exit 1
fi
echo "门禁通过"
