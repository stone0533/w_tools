#!/usr/bin/env bash
#
# 发布前门禁（静态检查默认全跑；测试 / dry-run 按需开启）。
#
# 用法：
#   bash scripts/preflight.sh                 # format / analyze / docs（含 feedback）/ 弃用 / catalog（含生成物新鲜度）/ release
#   bash scripts/preflight.sh --with-tests    # 再加所有包 + example + 根包测试 + 模板编译
#   bash scripts/preflight.sh --package ui    # 静态门禁 + 只跑 ui 包（含 example）的测试
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
only_pkg=""
while [ $# -gt 0 ]; do
  case "$1" in
    --with-tests) with_tests=1 ;;
    --with-dry-run) with_dry_run=1 ;;
    --package)
      if [ $# -lt 2 ]; then
        echo "--package 需要包目录名（如 ui）" >&2
        exit 2
      fi
      only_pkg="$2"
      shift
      ;;
    --package=*) only_pkg="${1#*=}" ;;
    --all) with_tests=1; with_dry_run=1 ;;
    -h | --help)
      sed -n '2,16p' "$0" | sed -n 's/^# \{0,1\}//p'
      exit 0
      ;;
    *)
      echo "未知参数: $1" >&2
      exit 2
      ;;
  esac
  shift
done

if [ -n "$only_pkg" ]; then
  with_tests=1
  if ! awk -F'|' -v p="packages/$only_pkg" '$1 !~ /^#/ && $2 == p { found = 1 } END { exit found ? 0 : 1 }' \
    "$root/scripts/packages.manifest"; then
    echo "--package 未在 packages.manifest 找到: $only_pkg" >&2
    exit 2
  fi
fi

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
run "naming" python3 scripts/check_naming.py
run "public catalog" python3 scripts/check_public_catalog.py
# 生成物新鲜度：只改源文件却忘了跑生成器时，这里直接失败（不用等 --with-tests 的 cli 测试）。
run "catalog fresh" bash -c "cd packages/cli && dart --suppress-analytics run tool/gen_catalog.dart --check"
run "templates fresh" bash -c "cd packages/cli && dart --suppress-analytics run tool/gen_templates.dart --check"
run "style literals" python3 scripts/check_style_literals.py
run "deprecations" python3 scripts/check_deprecations.py
run "release check" bash scripts/release_check.sh
# CI 的包矩阵与静态门禁必须从 manifest / preflight 派生，不能手抄一份。
run "ci parity" python3 scripts/ci_matrix.py --check

if [ -n "$with_tests" ]; then
  while IFS='|' read -r name path runner aggregate example; do
    case "$name" in ''|'#'*) continue ;; esac
    if [ -n "$only_pkg" ] && [ "$path" != "packages/$only_pkg" ]; then continue; fi
    case "$runner" in
      flutter) run "test $name" bash -c "cd $path && flutter test --reporter=compact" ;;
      dart) run "test $name" bash -c "cd $path && dart test --reporter=compact" ;;
      *) echo "未知 runner: $name=$runner" >&2; failed=1 ;;
    esac
  done < "$root/scripts/packages.manifest"
  if [ -z "$only_pkg" ]; then
    run "test root" flutter test
    run "test example" bash -c "cd example && flutter test --reporter=compact"
  fi
  while IFS='|' read -r name path runner aggregate example; do
    case "$name" in ''|'#'*) continue ;; esac
    if [ -n "$only_pkg" ] && [ "$path" != "packages/$only_pkg" ]; then continue; fi
    if [ "$example" = "example" ]; then
      run "test $name/example" bash -c "cd $path/example && flutter test --reporter=compact"
    fi
  done < "$root/scripts/packages.manifest"
  if [ -z "$only_pkg" ] || [ "$only_pkg" = "cli" ]; then
    run "template compile" bash -c "cd packages/cli && dart run tool/check_templates_compile.dart"
  fi
fi

if [ -n "$with_dry_run" ]; then
  while IFS='|' read -r name path runner aggregate example; do
    case "$name" in ''|'#'*) continue ;; esac
    if [ -n "$only_pkg" ] && [ "$path" != "packages/$only_pkg" ]; then continue; fi
    run "publish dry-run $name" bash scripts/publish_package.sh "$path" --dry-run
  done < "$root/scripts/packages.manifest"
  if [ -z "$only_pkg" ]; then
    echo "==> publish dry-run 根包（子包未发布时失败是预期）"
    if bash scripts/publish_package.sh . --dry-run; then
      echo "    ✓ 根包 dry-run"
    else
      echo "    ! 根包 dry-run 失败：仅在全部子包已上线后才应通过"
    fi
  fi
fi

if [ "$failed" -ne 0 ]; then
  echo "门禁失败" >&2
  exit 1
fi
echo "门禁通过"
