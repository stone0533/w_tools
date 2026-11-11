#!/usr/bin/env bash
#
# 发布前门禁（静态检查默认全跑；测试 / dry-run 按需开启）。
#
# 用法：
#   bash scripts/preflight.sh                 # format / analyze / docs（含 feedback）/ 弃用 / catalog（含生成物新鲜度）/ release
#   bash scripts/preflight.sh --with-tests    # 再加所有包 + example + 根包测试 + 模板编译
#   bash scripts/preflight.sh --package ui    # 静态门禁 + 只跑 ui 包（含 example）的测试
#   bash scripts/preflight.sh --changed       # 只跑相对 origin/main 改动到的包（含工作区改动）
#   bash scripts/preflight.sh --sandbox       # 不跑 Flutter 测试（本机 / agent 沙箱没有 FVM cache 写权限时）
#   bash scripts/preflight.sh --with-dry-run  # 再加全部子包 + 根包 publish dry-run
#   bash scripts/preflight.sh --all           # 全部
#
# 退出码：任一步失败即非 0（包括根包 dry-run）。根包 dry-run 要求根包依赖的版本都已发布：
# 发布子包阶段请用 --with-tests；全部子包上线后再跑 --all / --with-dry-run。
set -uo pipefail

# 与 CI 保持一致：dart / flutter 子进程在非交互环境下不写 telemetry 会话文件。
# 本机 / agent 沙箱里 ~/.dart-tool 不可写时，不设这个会让 `dart run` / `dart test`
# 以 FileSystemException 失败，看起来像测试失败。
export CI="${CI:-true}"

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

usage() {
  sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

with_tests=""
with_dry_run=""
only_pkg=""
changed=""
sandbox=""
base=""
while [ $# -gt 0 ]; do
  case "$1" in
    --with-tests) with_tests=1 ;;
    --with-dry-run) with_dry_run=1 ;;
    --changed) changed=1; with_tests=1 ;;
    --sandbox) sandbox=1 ;;
    --package)
      if [ $# -lt 2 ]; then
        echo "--package 需要包目录名（如 ui）" >&2
        exit 2
      fi
      only_pkg="$2"
      shift
      ;;
    --package=*) only_pkg="${1#*=}" ;;
    --base)
      if [ $# -lt 2 ]; then
        echo "--base 需要 ref（如 origin/main）" >&2
        exit 2
      fi
      base="$2"
      shift
      ;;
    --base=*) base="${1#*=}" ;;
    --all) with_tests=1; with_dry_run=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "未知参数: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [ -n "$only_pkg" ] && [ -n "$changed" ]; then
  echo "--package 与 --changed 不能同时使用" >&2
  exit 2
fi

if [ -n "$only_pkg" ]; then
  with_tests=1
  if ! awk -F'|' -v p="packages/$only_pkg" '$1 !~ /^#/ && $2 == p { found = 1 } END { exit found ? 0 : 1 }' \
    "$root/scripts/packages.manifest"; then
    echo "--package 未在 packages.manifest 找到: $only_pkg" >&2
    exit 2
  fi
fi

changed_pkgs=""
root_changed=""
run_all=""
if [ -n "$changed" ]; then
  base_ref="${base:-origin/main}"
  if ! git rev-parse --verify --quiet "$base_ref" >/dev/null; then
    echo "--changed 需要 base ref（默认 origin/main）：先 git fetch，或用 --base <ref>" >&2
    exit 2
  fi
  if ! merge_base="$(git merge-base "$base_ref" HEAD)"; then
    echo "无法计算 $base_ref 与 HEAD 的 merge-base" >&2
    exit 2
  fi
  changed_files="$(
    {
      git diff --name-only "$merge_base" HEAD
      git diff --name-only
      git ls-files --others --exclude-standard
    } | sort -u
  )"
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    case "$file" in
      packages/*)
        pkg="${file#packages/}"
        pkg="${pkg%%/*}"
        if awk -F'|' -v p="packages/$pkg" '$1 !~ /^#/ && $2 == p { found = 1 } END { exit found ? 0 : 1 }' \
          "$root/scripts/packages.manifest"; then
          changed_pkgs="$changed_pkgs $pkg"
        fi
        ;;
      lib/* | test/* | example/*)
        root_changed=1
        ;;
      pubspec.yaml | analysis_options.yaml)
        # workspace / 分析配置变化可能影响所有包：宁可多跑。
        root_changed=1
        run_all=1
        ;;
    esac
  done <<< "$changed_files"
  changed_pkgs="$(printf '%s\n' $changed_pkgs | sort -u | tr '\n' ' ')"
  echo "== --changed: base ${base_ref}，包: ${changed_pkgs:-（无）}${root_changed:+，root}"
  if [ -z "$changed_pkgs" ] && [ -z "$root_changed" ]; then
    echo "   本次改动不涉及包测试，只跑静态门禁"
  fi
fi

# 多数检查脚本 import yaml；缺依赖时由共用守卫给两条可执行的修法。
source "$root/scripts/_python.sh"
if ! require_python_yaml; then
  exit 2
fi

failed=0
failed_steps=()
record_failure() {
  failed=1
  failed_steps+=("$1")
}
run() {
  local name="$1"
  shift
  echo "==> $name"
  if "$@"; then
    echo "    ✓ $name"
  else
    echo "    ✗ $name" >&2
    record_failure "$name"
  fi
}

skip_sandbox() {
  echo "==> $1"
  echo "    - 跳过（--sandbox：Flutter 测试 / 发布 dry-run 由 CI 覆盖）"
}

pkg_selected() {
  local path="$1"
  local short="$2"
  if [ -n "$only_pkg" ]; then
    [ "$path" = "packages/$only_pkg" ]
    return
  fi
  if [ -n "$changed" ]; then
    [ -n "$run_all" ] && return 0
    case " $changed_pkgs " in
      *" $short "*) return 0 ;;
    esac
    return 1
  fi
  return 0
}

contains_changed_pkg() {
  case " $changed_pkgs " in
    *" $1 "*) return 0 ;;
  esac
  return 1
}

run_root_tests=""
if [ -z "$only_pkg" ]; then
  if [ -n "$changed" ]; then
    [ -n "$root_changed" ] && run_root_tests=1
  else
    run_root_tests=1
  fi
fi

run_cli_tests=""
if [ -n "$only_pkg" ]; then
  [ "$only_pkg" = "cli" ] && run_cli_tests=1
elif [ -n "$changed" ]; then
  if [ -n "$run_all" ] || contains_changed_pkg cli; then
    run_cli_tests=1
  fi
else
  run_cli_tests=1
fi

# dart analyze 与 flutter analyze 用同一个 analyzer，但不需要 Flutter SDK 的
# engine cache；本机 / agent 沙箱里 flutter analyze 会因 FVM cache 只读直接失败。
# CI 的每包 job 仍会跑 flutter analyze，这里换成 dart analyze 不会降低覆盖面。
run "format" dart --suppress-analytics format --output=none --set-exit-if-changed lib packages test example
run "analyze" dart --suppress-analytics analyze
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
# 消费方 AGENTS 的预算（行数 / 字符 / 反馈行数）：超了必须删内容或显式改
# packages/cli/catalog/agent_budget.yaml（改预算要在 PR 里写理由）。
run "agents budget" bash -c "cd packages/cli && dart --suppress-analytics run tool/agent_budget.dart --check"
run "style literals" python3 scripts/check_style_literals.py
run "deprecations" python3 scripts/check_deprecations.py
run "script unit tests" bash -c "cd scripts/tests && python3 -m unittest discover -p 'test_*.py'"
# 版本号会同时出现在子包 pubspec / 根 pubspec / init versions.dart；
# 只靠 release_check 与 ai_contract 测试会漏掉 CLI 自己的 cliConstraint。
run "versions" python3 scripts/check_versions.py
run "release check" bash scripts/release_check.sh
# CI 的包矩阵与静态门禁必须从 manifest / preflight 派生，不能手抄一份。
run "ci parity" python3 scripts/ci_matrix.py --check
# 每个检查脚本都必须真的被某个入口调用，并且在本手册登记 —— 防止「文档说在跑、实际没接」。
run "gate coverage" python3 scripts/check_gate_coverage.py

if [ -n "$with_tests" ]; then
  while IFS='|' read -r name path runner aggregate example || [ -n "$name" ]; do
    case "$name" in ''|'#'*) continue ;; esac
    short="${name#w_tools_}"
    pkg_selected "$path" "$short" || continue
    case "$runner" in
      flutter)
        if [ -n "$sandbox" ]; then
          skip_sandbox "test $name"
        else
          run "test $name" bash -c "cd $path && flutter --suppress-analytics test --reporter=compact"
        fi
        ;;
      dart)
        run "test $name" bash -c "cd $path && dart --suppress-analytics test --reporter=compact"
        ;;
      *) echo "未知 runner: $name=$runner" >&2; record_failure "test $name (unknown runner)" ;;
    esac
  done < "$root/scripts/packages.manifest"

  if [ -n "$run_root_tests" ]; then
    if [ -n "$sandbox" ]; then
      skip_sandbox "test root"
      skip_sandbox "test example"
    else
      run "test root" flutter --suppress-analytics test
      run "test example" bash -c "cd example && flutter --suppress-analytics test --reporter=compact"
    fi
  fi

  while IFS='|' read -r name path runner aggregate example || [ -n "$name" ]; do
    case "$name" in ''|'#'*) continue ;; esac
    short="${name#w_tools_}"
    pkg_selected "$path" "$short" || continue
    if [ "$example" = "example" ]; then
      if [ -n "$sandbox" ]; then
        skip_sandbox "test $name/example"
      else
        run "test $name/example" bash -c "cd $path/example && flutter --suppress-analytics test --reporter=compact"
      fi
    fi
  done < "$root/scripts/packages.manifest"

  if [ -n "$run_cli_tests" ]; then
    run "template compile" bash -c "cd packages/cli && dart --suppress-analytics run tool/check_templates_compile.dart"
  fi
fi

if [ -n "$with_dry_run" ]; then
  if [ -n "$sandbox" ]; then
    skip_sandbox "publish dry-run"
  else
    while IFS='|' read -r name path runner aggregate example || [ -n "$name" ]; do
      case "$name" in ''|'#'*) continue ;; esac
      short="${name#w_tools_}"
      pkg_selected "$path" "$short" || continue
      run "publish dry-run $name" bash scripts/publish_package.sh "$path" --dry-run
    done < "$root/scripts/packages.manifest"
    if [ -z "$only_pkg" ] && [ -z "$changed" ]; then
      # 根包 dry-run 也计入失败：它要求根包依赖的版本都已发布。
      # 发布子包阶段请改用 --with-tests；全部子包上线后再跑 --all。
      run "publish dry-run root" bash scripts/publish_package.sh . --dry-run
    fi
  fi
fi

if [ "$failed" -ne 0 ]; then
  if [ -n "${failed_steps[*]:-}" ]; then
    echo "门禁失败：${failed_steps[*]}" >&2
  else
    echo "门禁失败" >&2
  fi
  exit 1
fi
echo "门禁通过"
