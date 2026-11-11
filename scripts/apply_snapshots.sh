#!/usr/bin/env bash
#
# 把发布时暂存在 .w_tools/release-snapshots/ 的 API 快照应用到 scripts/api_snapshots/。
#
# 为什么需要它：
#   发布脚本在发布成功后写快照；如果直接写进 scripts/api_snapshots/，这份未跟踪文件会
#   挡住下一个包的发布（发布保护要求工作区干净），也会在 reset --hard 时丢失（PR #8 踩过）。
#   所以快照先写到 gitignored 的 pending 目录，一批发完再统一应用。
#
# 用法：
#   bash scripts/apply_snapshots.sh
#   bash scripts/apply_snapshots.sh --ship                    # 应用后建分支、PR、等 checks、合并
#   bash scripts/apply_snapshots.sh --from <dir> --to <dir>   # 调试 / 测试用
#
# 不带 --ship 只做文件移动，不 commit / 不 push；应用后打印快照 PR 的手工命令。
# 根包发布前必须先合入快照 PR（release_check --strict 会检查快照 tracked 且版本一致）。
#
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
from="${W_TOOLS_SNAPSHOT_DIR:-$root/.w_tools/release-snapshots}"
to="${W_TOOLS_SNAPSHOT_TARGET:-$root/scripts/api_snapshots}"
ship=0

usage() {
  sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --from)
      [ $# -ge 2 ] || { echo "--from 需要目录" >&2; exit 2; }
      from="$2"
      shift
      ;;
    --from=*) from="${1#*=}" ;;
    --to)
      [ $# -ge 2 ] || { echo "--to 需要目录" >&2; exit 2; }
      to="$2"
      shift
      ;;
    --to=*) to="${1#*=}" ;;
    --ship) ship=1 ;;
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

if [ ! -d "$from" ]; then
  echo "没有待应用快照：$from 不存在（先发布子包，快照会自动写到那里）"
  exit 0
fi

files=()
while IFS= read -r file; do
  [ -n "$file" ] && files+=("$file")
done < <(find "$from" -maxdepth 1 -type f -name 'w_tools_*.txt' -print | sort)

if [ ${#files[@]} -eq 0 ]; then
  echo "没有待应用快照：$from 为空"
  exit 0
fi

mkdir -p "$to"
applied=()
echo "== 应用 API 快照：$from -> $to"
for file in "${files[@]}"; do
  base="$(basename "$file")"
  pkg="${base#w_tools_}"
  pkg="${pkg%%-*}"
  version="${base#w_tools_${pkg}-}"
  version="${version%.txt}"
  pubspec="$root/packages/$pkg/pubspec.yaml"
  if [ ! -f "$pubspec" ]; then
    echo "  ! ${base}：找不到 packages/$pkg/pubspec.yaml（仍应用；请确认包名）" >&2
  else
    local_version="$(sed -n 's/^version:[[:space:]]*//p' "$pubspec" | head -n1)"
    if [ "$local_version" != "$version" ]; then
      echo "  ! ${base}：本地 pubspec 版本是 ${local_version:-?}，快照版本是 ${version}（仍应用；根包 strict 会拦住不一致）" >&2
    fi
  fi
  mv -f "$file" "$to/$base"
  applied+=("$pkg $version")
  echo "  ✓ $base"
done

# 只有目录空了才删；有用户放进去的其他文件就保留。
rmdir "$from" 2>/dev/null || true

if [ "$ship" -eq 1 ]; then
  branch="chore/release-snapshots-$(date +%Y%m%d-%H%M%S)"
  if git -C "$root" show-ref --verify --quiet "refs/heads/$branch"; then
    branch="${branch}-$$"
  fi
  git -C "$root" switch -c "$branch"
  if [ ${#applied[@]} -eq 1 ]; then
    subject="${applied[0]}"
  else
    subject="$(IFS=', '; echo "${applied[*]}")"
  fi
  exec bash "$root/scripts/ship.sh" \
    -m "chore(release): ${subject} API 基线" --type internal --merge --yes
fi

cat <<'EOF'

下一步（快照必须走分支 + PR）：
  git switch -c chore/release-snapshots   # 已存在则 git switch chore/release-snapshots
  git add scripts/api_snapshots
  git commit -m "chore(release): <pkg> <version> API 基线"
  bash scripts/ship.sh --type internal --merge --yes

合入 PR 并 `git switch main && git pull --ff-only` 之后，才能发根包。
EOF
