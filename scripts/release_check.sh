#!/usr/bin/env bash
#
# 发布前校验：子包版本 / CHANGELOG / 根包依赖约束 / README 版本声明 / 与 pub.dev 的漂移。
#
#   scripts/release_check.sh            # 离线检查，CI 每次都跑
#   scripts/release_check.sh --strict   # 额外要求工作区干净（真正发布前用）
#   scripts/release_check.sh --online   # 额外对比 pub.dev 已发布版本，找出「仓库领先」的包
#   scripts/release_check.sh --package map   # 只检查某个子包（单独发一个包时用）
#
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 2

PACKAGES="core ui form api app toast map qr"
STRICT=0
ONLINE=0
SELECTED=""

usage() {
  sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --strict) STRICT=1 ;;
    --online) ONLINE=1 ;;
    --package)
      if [ $# -lt 2 ]; then
        echo "--package 需要包名（如 --package map）" >&2
        exit 2
      fi
      SELECTED="$2"
      shift
      ;;
    --package=*) SELECTED="${1#*=}" ;;
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

if [ -n "$SELECTED" ]; then
  case " $PACKAGES " in
    *" $SELECTED "*) ;;
    *)
      echo "未知子包: ${SELECTED}（可选：${PACKAGES}）" >&2
      exit 2
      ;;
  esac
fi

errors=0
warns=0

section() { printf '\n== %s\n' "$1"; }
fail() {
  printf '  ✗ %s\n' "$1"
  errors=$((errors + 1))
}
warn() {
  printf '  ! %s\n' "$1"
  warns=$((warns + 1))
}
ok() { printf '  ✓ %s\n' "$1"; }

pubspec_version() { sed -n 's/^version:[[:space:]]*//p' "$1" | head -n1; }

# CHANGELOG 里是否有精确匹配该版本的二级标题
changelog_has_version() {
  local escaped="${2//./\\.}"
  grep -qE "^##[[:space:]]+${escaped}([[:space:]]|$)" "$1"
}

# CHANGELOG 里是否存在带条目的 `## Unreleased` 段
changelog_has_unreleased() {
  awk '
    /^## / {
      if (seen) exit
      if ($0 ~ /^##[[:space:]]+Unreleased[[:space:]]*$/) { seen = 1; next }
    }
    seen && /^- / { found = 1 }
    END { exit found ? 0 : 1 }
  ' "$1"
}

# 版本比较：$1 > $2 时返回 0
ver_gt() {
  awk -v a="$1" -v b="$2" 'BEGIN {
    split(a, A, "."); split(b, B, ".");
    for (i = 1; i <= 3; i++) { A[i] += 0; B[i] += 0 }
    for (i = 1; i <= 3; i++) {
      if (A[i] > B[i]) exit 0
      if (A[i] < B[i]) exit 1
    }
    exit 1
  }'
}

# caret 约束 ^A.B.C 是否接受版本 V（同 major 且 >= A.B.C）
caret_accepts() {
  awk -v c="$1" -v v="$2" 'BEGIN {
    if (substr(c, 1, 1) != "^") exit 2
    c = substr(c, 2)
    split(c, C, "."); split(v, V, ".");
    for (i = 1; i <= 3; i++) { C[i] += 0; V[i] += 0 }
    ok = (V[1] == C[1]) && (V[2] > C[2] || (V[2] == C[2] && V[3] >= C[3]))
    exit ok ? 0 : 1
  }'
}

section '子包版本 / 发布物料'
for pkg in $PACKAGES; do
  if [ -n "$SELECTED" ] && [ "$pkg" != "$SELECTED" ]; then
    continue
  fi
  dir="packages/$pkg"
  pub="$dir/pubspec.yaml"

  if [ ! -f "$pub" ]; then
    fail "$pkg: 缺 pubspec.yaml"
    continue
  fi

  name="$(sed -n 's/^name:[[:space:]]*//p' "$pub" | head -n1)"
  version="$(pubspec_version "$pub")"

  [ "$name" = "w_tools_$pkg" ] || fail "$pkg: name 应为 w_tools_${pkg}，实际为 '$name'"
  if [ -z "$version" ]; then
    fail "$pkg: pubspec.yaml 缺 version"
    continue
  fi

  grep -q '^resolution: workspace$' "$pub" || fail "$pkg: 缺 resolution: workspace"

  for f in README.md CHANGELOG.md LICENSE; do
    [ -f "$dir/$f" ] || fail "$pkg: 缺 $f"
  done

  if [ -f "$dir/CHANGELOG.md" ]; then
    changelog_has_version "$dir/CHANGELOG.md" "$version" ||
      fail "$pkg: CHANGELOG 里没有 '## $version' 段（当前 pubspec 版本是 ${version}）"
    changelog_has_unreleased "$dir/CHANGELOG.md" &&
      warn "$pkg: CHANGELOG 有未发版条目（## Unreleased）—— 若是已随旧版本发布的内容，折叠进对应版本；只有真正未发的才留在这里"
  fi

  constraint="$(sed -n "s/^  w_tools_${pkg}:[[:space:]]*//p" pubspec.yaml | head -n1)"
  if [ -z "$constraint" ]; then
    fail "根包 pubspec.yaml 缺少对 w_tools_$pkg 的依赖"
  else
    caret_accepts "$constraint" "$version"
    rc=$?
    if [ "$rc" = 0 ]; then
      ok "$name ${version}（根约束 ${constraint}）"
      lower="${constraint#^}"
      if ver_gt "$version" "$lower"; then
        warn "根包约束 ${constraint} 的下界低于本地版本 ${version} —— 已有 lockfile 的聚合包用户不会自动拿到它"
      fi
    elif [ "$rc" = 2 ]; then
      fail "根包对 w_tools_$pkg 的约束 '$constraint' 不是 ^ 形式，脚本无法校验"
    else
      fail "根包约束 $constraint 不接受本地版本 $version —— 聚合包用户拿不到这个子包版本"
    fi
  fi
done

section '根包'
root_version="$(pubspec_version pubspec.yaml)"
if [ -n "$SELECTED" ]; then
  ok "跳过（--package 只检查 w_tools_${SELECTED}；根包版本在完整检查里校验）"
elif [ -z "$root_version" ]; then
  fail "根包 pubspec.yaml 缺 version"
else
  if changelog_has_version CHANGELOG.md "$root_version"; then
    ok "w_tools $root_version"
  else
    fail "根包 CHANGELOG 里没有 '## $root_version' 段"
  fi
  changelog_has_unreleased CHANGELOG.md &&
    warn "根包 CHANGELOG 有未发版条目（## Unreleased）"
fi

section 'README 版本声明'
# README 不再硬编码「当前 x.y.z」：版本会随各包独立发版漂移，以 pubspec / pub.dev 为准。
if grep -nE '当前[[:space:]]*`[0-9]+\.[0-9]+\.[0-9]+`' README.md >/dev/null 2>&1; then
  while IFS= read -r line; do
    fail "README.md 硬编码了子包版本：$line"
  done < <(grep -nE '当前[[:space:]]*`[0-9]+\.[0-9]+\.[0-9]+`' README.md)
else
  ok "README 未硬编码版本号"
fi

if [ "$STRICT" = 1 ]; then
  section '工作区状态（--strict）'
  if git diff --quiet HEAD -- 2>/dev/null; then
    ok "已跟踪文件无未提交改动"
  else
    fail "有未提交改动：发布请从干净提交开始（dry-run 也会因此返回 65）"
  fi
  untracked="$(git ls-files --others --exclude-standard 2>/dev/null)"
  if [ -z "$untracked" ]; then
    ok "无未跟踪文件"
  else
    fail "存在未跟踪文件：$(echo "$untracked" | head -n3 | tr '\n' ' ')"
  fi
fi

if [ "$ONLINE" = 1 ]; then
  section 'pub.dev 发布状态（--online）'
  if [ -n "$SELECTED" ]; then
    online_names="w_tools_$SELECTED"
  else
    online_names="$(
      printf 'w_tools\n'
      for pkg in $PACKAGES; do printf 'w_tools_%s\n' "$pkg"; done
    )"
  fi
  for name in $online_names; do
    local_version="$root_version"
    [ "$name" = "w_tools" ] || local_version="$(pubspec_version "packages/${name#w_tools_}/pubspec.yaml")"

    published="$(
      curl -fsSL --max-time 10 "https://pub.dev/api/packages/$name" 2>/dev/null |
        grep -o '"latest":{"version":"[^"]*"' |
        head -n1 |
        sed 's/.*"version":"//; s/"$//'
    )"

    if [ -z "$published" ]; then
      warn "$name: 取不到线上版本（网络或包不存在），跳过比对"
      continue
    fi

    if [ "$local_version" = "$published" ]; then
      ok "$name $local_version 已发布"
    elif ver_gt "$local_version" "$published"; then
      fail "$name: 仓库 $local_version > pub.dev $published —— 待发布"
    else
      fail "$name: 仓库 $local_version < pub.dev $published —— 仓库落后于线上"
    fi
  done
fi

printf '\n'
if [ "$errors" -gt 0 ]; then
  printf '检查失败：%s 项错误，%s 条提醒\n' "$errors" "$warns"
  exit 1
fi

printf '检查通过（%s 条提醒）\n' "$warns"
if [ -n "$SELECTED" ]; then
  printf '单个包发布：cd packages/%s && flutter pub publish，发布后重跑本脚本 --package %s --online 确认。\n' "$SELECTED" "$SELECTED"
else
  printf '发布顺序：先按「仓库领先」的子包逐个 flutter pub publish，再发根包 w_tools（抬高约束后发布）。\n'
fi
