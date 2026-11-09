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
# 退出码：任一步失败即非 0（包括根包 dry-run）。根包 dry-run 要求根包依赖的版本都已发布：
# 发布子包阶段请用 --with-tests；全部子包上线后再跑 --all / --with-dry-run。
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

# 多数检查脚本 import yaml；缺依赖时给一句可执行的提示，而不是让 python 抛堆栈。
if ! python3 -c 'import yaml' >/dev/null 2>&1; then
  echo "缺少 PyYAML：python3 -m pip install pyyaml（CI 的 venv 会自动安装）" >&2
  exit 2
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

run "format" dart --suppress-analytics format --output=none --set-exit-if-changed lib packages test example
run "analyze" flutter analyze
run "docs" bash scripts/check_docs.sh
run "naming" python3 scripts/check_naming.py
run "public catalog" python3 scripts/check_public_catalog.py
run "catalog symbols" python3 scripts/check_catalog_symbols.py
# 按 manifest 遍历，而不是遍历「已有快照」：缺基线必须失败，不能静默跳过。
run "public api diff" bash -c '
  set -e
  while IFS="|" read -r name path runner aggregate example || [ -n "$name" ]; do
    case "$name" in ""|"#"*) continue ;; esac
    python3 scripts/check_public_api_diff.py --package "${name#w_tools_}"
  done < scripts/packages.manifest
'
if [ -n "$only_pkg" ]; then
  run "test imports" python3 scripts/check_test_imports.py --package "$only_pkg"
else
  run "test imports" python3 scripts/check_test_imports.py
fi
# 发布物里的 example 必须能独立 pub get：CI 的仓库内 analyze/test 看不到
# `../../app` / `../packages/qr` 这类包外路径。
run "example paths" python3 scripts/check_example_paths.py
# 生成物新鲜度：只改源文件却忘了跑生成器时，这里直接失败（不用等 --with-tests 的 cli 测试）。
run "catalog fresh" bash -c "cd packages/cli && dart --suppress-analytics run tool/gen_catalog.dart --check"
run "templates fresh" bash -c "cd packages/cli && dart --suppress-analytics run tool/gen_templates.dart --check"
run "style literals" python3 scripts/check_style_literals.py
run "deprecations" python3 scripts/check_deprecations.py
run "script unit tests" bash -c "cd scripts/tests && python3 -m unittest discover -p 'test_*.py'"
run "release check" bash scripts/release_check.sh
# CI 的包矩阵与静态门禁必须从 manifest / preflight 派生，不能手抄一份。
run "ci parity" python3 scripts/ci_matrix.py --check
# 每个检查脚本都必须真的被某个入口调用，并且在本手册登记 —— 防止「文档说在跑、实际没接」。
run "gate coverage" python3 scripts/check_gate_coverage.py

if [ -n "$with_tests" ]; then
  while IFS='|' read -r name path runner aggregate example || [ -n "$name" ]; do
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
  while IFS='|' read -r name path runner aggregate example || [ -n "$name" ]; do
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
  while IFS='|' read -r name path runner aggregate example || [ -n "$name" ]; do
    case "$name" in ''|'#'*) continue ;; esac
    if [ -n "$only_pkg" ] && [ "$path" != "packages/$only_pkg" ]; then continue; fi
    run "publish dry-run $name" bash scripts/publish_package.sh "$path" --dry-run
  done < "$root/scripts/packages.manifest"
  if [ -z "$only_pkg" ]; then
    # 根包 dry-run 也计入失败：它要求根包依赖的版本都已发布。
    # 发布子包阶段请改用 --with-tests；全部子包上线后再跑 --all。
    run "publish dry-run root" bash scripts/publish_package.sh . --dry-run
  fi
fi

if [ "$failed" -ne 0 ]; then
  echo "门禁失败" >&2
  exit 1
fi
echo "门禁通过"
