#!/usr/bin/env bash
#
# ship.sh —— 一条命令走完「提交 → push → 开 PR（可选：等 checks 后合并）」。
#
# 为什么需要它：仓库的正常流程是 分支 → commit → push → PR（模板必带「## 改动类型」）
# → Required checks → Merge commit。每一步都有硬约束（commit-msg 的 conventional 标题、
# pre-push 禁止 main、check_pr_scope 要求 body 勾选、只允许 Merge commit），手敲容易漏；
# 这个脚本只做**顺序编排**，所有门禁仍然原样执行，不绕过任何钩子。
#
# 用法：
#   bash scripts/ship.sh -m "feat(cli): 一句话" --type public --j4 "J-4 结论…"
#   bash scripts/ship.sh -m "fix(cli): 修个 bug" --type internal      # 内部重构
#   bash scripts/ship.sh -m "..." --type public --check --merge       # 跑 preflight 并等 checks 后合并
#   bash scripts/ship.sh --merge                                      # 已有 OPEN PR：只等 checks + 合并
#                                                                      （不碰工作区、不重写 PR body）
#   bash scripts/ship.sh -m "..." --dry-run                           # 只打印计划，不动任何东西
#
# 参数：
#   -m, --message <msg>   commit 标题（conventional）；同时作为 PR 标题
#   -t, --type <t>        internal | public | remove | new（可逗号分隔；public/remove/new 需要 --j4）
#   --j4 <text>           填进 PR 的「J-4 结论」；公开变化时必填
#   --closes <n>          追加 `Closes #n`（可重复）
#   --branch <name>       在 main 上显式指定新分支名（默认从 -m 标题推导）
#   --body <file>         直接用这份 PR body，跳过自动生成
#   --tracked             只暂存已跟踪文件（默认 git add -A）
#   -y, --yes             不再交互确认
#   --check               提交前跑 `bash scripts/preflight.sh --changed`
#   --merge               开 PR 后等 checks，然后 Merge commit + 删远端分支
#   --dry-run             只打印将要执行的命令
#   -h, --help
#
# 不做的事（有意）：
#   - 不 `--no-verify`、不 `--admin`、不 force-push、不 squash（仓库只允许 Merge commit）；
#   - 不自动改 commit（整理成几个逻辑 commit 仍由人决定）；
#   - 不在 main 上提交 / 推送；不在工作区有未跟踪文件时「替你想」要不要提交（默认全加，先给你看 stat）。
#
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

message=""
types=""
j4=""
closes=()
body_file=""
branch_override=""
staged_only=0
assume_yes=0
run_check=0
merge_after=0
dry_run=0

usage() {
  sed -n '2,35p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

die() {
  echo "✗ $*" >&2
  exit 1
}

# 打印 + 执行（dry-run 只打印）
run() {
  if [ "$dry_run" -eq 1 ]; then
    printf '+ %s\n' "$*"
    return 0
  fi
  "$@"
}

run_shell() {
  if [ "$dry_run" -eq 1 ]; then
    printf '+ %s\n' "$1"
    return 0
  fi
  bash -c "$1"
}

while [ $# -gt 0 ]; do
  case "$1" in
    -m | --message)
      [ $# -ge 2 ] || die "$1 需要参数"
      message="$2"
      shift 2
      ;;
    -t | --type)
      [ $# -ge 2 ] || die "$1 需要参数"
      types="${types:+$types,}$2"
      shift 2
      ;;
    --j4)
      [ $# -ge 2 ] || die "--j4 需要参数"
      j4="$2"
      shift 2
      ;;
    --closes)
      [ $# -ge 2 ] || die "--closes 需要参数"
      closes+=("$2")
      shift 2
      ;;
    --body)
      [ $# -ge 2 ] || die "--body 需要参数"
      body_file="$2"
      shift 2
      ;;
    --branch)
      [ $# -ge 2 ] || die "--branch 需要参数"
      branch_override="$2"
      shift 2
      ;;
    --tracked)
      staged_only=1
      shift
      ;;
    -y | --yes)
      assume_yes=1
      shift
      ;;
    --check)
      run_check=1
      shift
      ;;
    --merge)
      merge_after=1
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      die "未知参数：$1（用 --help 看用法）"
      ;;
  esac
done

# ---------- 0. 基础环境 ----------
command -v gh >/dev/null 2>&1 || die "需要 gh（GitHub CLI）。安装：https://cli.github.com/"
source "$root/scripts/_gh.sh"
[ -f scripts/check_pr_ready.sh ] || die "缺少 scripts/check_pr_ready.sh（仓库不完整？）"

branch_from_message() {
  local title="${1%%$'\n'*}"
  local pattern='^(feat|fix|chore|docs|refactor|test)(\([^)]*\))?:[[:space:]]*(.+)$'
  if [[ ! "$title" =~ $pattern ]]; then
    return 1
  fi
  local type="${BASH_REMATCH[1]}"
  local desc="${BASH_REMATCH[3]}"
  local slug
  slug="$(
    printf '%s' "$desc" |
      tr '[:upper:]' '[:lower:]' |
      sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' |
      cut -c1-50 |
      sed -E 's/-+$//'
  )"
  [ -n "$slug" ] || slug="update"
  printf '%s/%s\n' "$type" "$slug"
}

branch="$(git rev-parse --abbrev-ref HEAD)"
if [ "$branch" = "HEAD" ]; then
  die "当前不在分支上（detached HEAD）；先 git switch -c <分支>"
fi
if [ -n "$branch_override" ] && [ "$branch" != "main" ]; then
  die "--branch 只在 main 上创建新分支时使用（当前：$branch）"
fi
if [ "$branch" = "main" ]; then
  if [ -n "$branch_override" ]; then
    branch="$branch_override"
  elif [ -n "$message" ]; then
    branch="$(branch_from_message "$message")" ||
      die "无法从 -m 标题推导分支名；请用 --branch <name>（要求 feat|fix|chore|docs|refactor|test: ...）"
  else
    die "禁止在 main 上提交 / 推送。先给 -m 或 --branch，或手动 git switch -c <分支>"
  fi
  if ! git check-ref-format --branch "$branch" >/dev/null 2>&1; then
    die "分支名不合法：$branch"
  fi
  if [ "$dry_run" -eq 1 ]; then
    echo "== 将在 main 上创建分支：$branch"
  else
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      die "分支已存在：$branch；换一个 --branch 或先 git switch $branch"
    fi
    git switch -c "$branch"
  fi
fi

# 两种模式：
# - sync（默认）：暂存 → commit → push → 开 / 更新 PR；需要 --type 或 --body
# - merge-only：只对当前分支的 OPEN PR 等 checks 再合并；不碰工作区、不重写 PR body
sync=1
if [ -z "$types" ] && [ -z "$body_file" ] && [ -z "$message" ]; then
  sync=0
fi
if [ "$sync" -eq 0 ] && [ "$merge_after" -eq 0 ]; then
  die "没有可做的事：给 --type internal|public|remove|new 开 PR，或 --merge 合并已有 PR"
fi
if [ "$sync" -eq 1 ] && [ -z "$types" ] && [ -z "$body_file" ]; then
  die "必须给 --type internal|public|remove|new（PR 模板要求至少勾选一项；也可以 --body 用现成 body）"
fi

if [ "$sync" -eq 0 ]; then
  # merge-only：gh 会按当前分支找 PR；先确认状态，避免把「没开 PR」误当成合并失败
  pr_number="<current-pr>"
  if [ "$dry_run" -eq 0 ]; then
    state="$(gh pr view --json state --jq .state 2>/dev/null || true)"
    [ "$state" = "OPEN" ] || die "当前分支没有 OPEN PR（状态：${state:-无}）；先用 --type … 开 PR"
    pr_number="$(gh pr view --json number -q .number)"
  fi
  echo "== 等 checks 注册 + watch"
  run gh_wait_checks "$pr_number"
  echo "== Merge commit + 删远端分支"
  run gh pr merge --merge --delete-branch
  if [ "$dry_run" -eq 0 ]; then
    echo "✓ 已合并。下一步（本地收尾，手动执行）："
    echo "  git switch main && git pull --ff-only"
  fi
  exit 0
fi

# 公开面路径：改了这些且选 internal 时提醒（不是硬失败：lib/ 里也可能是内部重构）
public_paths_re='^(lib/|bin/|packages/[^/]+/(lib|bin|templates|catalog|schema)/)'
changed_all="$(
  {
    git diff --name-only "origin/main...HEAD" 2>/dev/null || true
    git diff --name-only 2>/dev/null || true
    git diff --name-only --cached 2>/dev/null || true
    git ls-files --others --exclude-standard 2>/dev/null || true
  } | sort -u
)"
touched_public=0
if printf '%s\n' "$changed_all" | grep -Eq "$public_paths_re"; then
  touched_public=1
fi

case ",$types," in
  *",public,"* | *",remove,"* | *",new,"*)
    [ -n "$j4" ] || die "选了公开类别（public / remove / new）就必须给 --j4 \"<J-4 结论>\"（模板要求；写「不适用：…」也要写一句）"
    ;;
esac
if [ "$touched_public" -eq 1 ] && [ "${types:-internal}" = "internal" ]; then
  echo "! 检测到改了公开面路径（lib / bin / templates / catalog / schema），但 --type 是 internal。" >&2
  echo "  如果这是公开变化 / 行为变化，请改成 --type public；确实是内部重构可忽略。" >&2
fi

# ---------- 1. 暂存 + 提交 ----------
if [ "$staged_only" -eq 1 ]; then
  run git add -u
else
  run git add -A
fi

if ! git diff --cached --quiet; then
  echo "== 将提交："
  git diff --cached --stat
else
  echo "== 没有新的暂存改动（只处理已有 commit）"
fi

if ! git diff --cached --quiet; then
  [ -n "$message" ] || die "有改动要提交，但没给 -m \"<conventional 标题>\""
  if [ "$assume_yes" -eq 0 ] && [ -t 0 ] && [ "$dry_run" -eq 0 ]; then
    printf '继续提交？[y/N] '
    read -r answer
    case "$answer" in
      y | Y | yes | YES) ;;
      *) die "已取消（暂存内容保留）" ;;
    esac
  fi

  if [ "$run_check" -eq 1 ]; then
    echo "== preflight --changed"
    run_shell "bash scripts/preflight.sh --changed"
  fi

  run git commit -m "$message"
else
  [ -n "$message" ] || message="$(git log -1 --format=%s)"
fi

# 已有 commit 也需要一个标题（PR 标题只取首行）
[ -n "$message" ] || message="$(git log -1 --format=%s)"
title="${message%%$'\n'*}"

# ---------- 2. 与 origin/main 的关系 ----------
if [ "$dry_run" -eq 0 ]; then
  git fetch origin main --quiet 2>/dev/null || echo "! 无法 fetch origin main（离线？），跳过领先/落后检查" >&2
fi

ahead="$(git rev-list --count "origin/main..HEAD" 2>/dev/null || echo 0)"
behind="$(git rev-list --count "HEAD..origin/main" 2>/dev/null || echo 0)"
if [ "$ahead" -eq 0 ] && [ "$merge_after" -eq 0 ]; then
  echo "✓ 当前分支相对 origin/main 没有新 commit，无事可做。"
  exit 0
fi
if [ "$behind" -gt 0 ]; then
  echo "! 当前分支落后 origin/main $behind 个 commit；建议先 git merge origin/main（或 rebase）再开 PR。" >&2
fi

# ---------- 3. PR body ----------
tmpdir="${TMPDIR:-/tmp}"; tmpdir="${tmpdir%/}"
tmp_body="$(mktemp "$tmpdir/w_tools_pr_body.XXXXXX")"
cleanup() { rm -f "$tmp_body"; }
trap cleanup EXIT

if [ -n "$body_file" ]; then
  [ -f "$body_file" ] || die "--body 指向的文件不存在：$body_file"
  cp "$body_file" "$tmp_body"
else
  {
    echo "## 改动类型"
    echo
    case ",$types," in
      *",public,"*) echo "- [x] 公开变化（API / 行为 / 新组件）" ;;
      *) echo "- [ ] 公开变化（API / 行为 / 新组件）" ;;
    esac
    case ",$types," in
      *",internal,"*) echo "- [x] 内部重构（公开 API / 默认行为不变）" ;;
      *) echo "- [ ] 内部重构（公开 API / 默认行为不变）" ;;
    esac
    case ",$types," in
      *",remove,"*) echo "- [x] 删除 / 废弃" ;;
      *) echo "- [ ] 删除 / 废弃" ;;
    esac
    case ",$types," in
      *",new,"*) echo "- [x] 新增包" ;;
      *) echo "- [ ] 新增包" ;;
    esac
    echo
    echo "## 摘要"
    echo
    echo "$message"
    if [ "${#closes[@]}" -gt 0 ]; then
      echo
      for number in "${closes[@]}"; do echo "Closes #$number"; done
    fi
    echo
    echo "## J-4 结论（有公开 API / 行为变化时必填）"
    echo
    echo "- J-4 结论：${j4:-未填（内部变更）；如涉及公开面请补}。"
    echo
    echo "## 自检"
    echo
    echo "- [x] 本地 PR 级门禁：bash scripts/check_pr_ready.sh"
    if [ "$run_check" -eq 1 ]; then
      echo "- [x] bash scripts/preflight.sh --changed"
    else
      echo "- [ ] bash scripts/preflight.sh --changed（本次未跑，可加 --check）"
    fi
    echo "- [ ] CI Required checks 通过后合并（仓库只允许 Merge commit）"
    echo
    echo "> 由 scripts/ship.sh 生成；模板里的命名 / 版本物料勾选项请按需补。"
  } >"$tmp_body"
fi

if [ "$dry_run" -eq 1 ]; then
  echo "== 将使用的 PR body（${tmp_body}）"
  sed 's/^/  /' "$tmp_body"
fi

echo "== 本地 PR 级门禁（check_pr_ready）"
if [ "$dry_run" -eq 1 ]; then
  printf '+ bash scripts/check_pr_ready.sh %s\n' "$tmp_body"
else
  bash scripts/check_pr_ready.sh "$tmp_body"
fi

# ---------- 4. push + PR ----------
run git push -u origin HEAD

existing_pr=""
if [ "$dry_run" -eq 0 ]; then
  existing_pr="$(gh pr view --json number,state --jq 'select(.state=="OPEN") | .number' 2>/dev/null || true)"
fi

if [ -n "$existing_pr" ]; then
  echo "== 更新已有 PR #$existing_pr 的 body"
  run gh pr edit "$existing_pr" --body-file "$tmp_body"
  pr_number="$existing_pr"
else
  echo "== 创建 PR"
  run gh pr create --base main --title "$title" --body-file "$tmp_body"
  if [ "$dry_run" -eq 1 ]; then
    pr_number="<new>"
  else
    pr_number="$(gh pr view --json number --jq .number)"
  fi
fi

if [ "$dry_run" -eq 0 ]; then
  echo "PR: $(gh pr view --json url --jq .url)"
fi

# ---------- 5. 可选：等 checks + 合并 ----------
if [ "$merge_after" -eq 1 ]; then
  echo "== 等 checks 注册 + watch"
  run gh_wait_checks "$pr_number"
  echo "== Merge commit + 删远端分支"
  run gh pr merge "$pr_number" --merge --delete-branch
  echo "✓ 已合并。下一步（本地收尾，手动执行）："
  echo "  git switch main && git pull --ff-only"
  exit 0
fi

echo "下一步："
echo "  bash scripts/ship.sh --merge  # 等 checks 注册后 watch 并合并（已开 PR 时不会重复创建）"
