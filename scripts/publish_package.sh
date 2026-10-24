#!/usr/bin/env bash
#
# 在「发布暂存副本」里执行 pub publish。
#
# 为什么需要它：
#   仓库根的 pubspec.yaml 带 `workspace:`（本地开发需要），子包带 `resolution: workspace`。
#   这些字段会被原样发布出去。消费方把包装进 pub 缓存后，`dart pub deps` 等命令会去读
#   依赖的 `workspace:`，然后找不到 `packages/core` 而失败（2.0.0 就是这样）。
#   所以发布必须在去掉 workspace 字段的副本里进行。
#
# 用法：
#   scripts/publish_package.sh .                 # 发布根包 w_tools
#   scripts/publish_package.sh packages/ui       # 发布 w_tools_ui
#   scripts/publish_package.sh packages/ui --dry-run
#   scripts/publish_package.sh . --stage-only    # 只生成暂存副本（调试用，不删除）
#
# 发布目标：默认 https://pub.dev。
#   不复用 PUB_HOSTED_URL —— 本机常把它设成只读镜像，且镜像元数据会滞后。
#   需要发到其它 host 时显式设 PUBLISH_HOSTED_URL。
#
# 暂存副本会：
#   - 去掉顶层 `workspace:` 块与 `resolution: workspace`
#   - 排除 .git / .dart_tool / build / coverage / test / doc / scripts / .github / pubspec.lock
#   - 根包额外排除 `packages/`（子包只随各自包发布）
#
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 显式指定发布目标：本地 shell 里的 PUB_HOSTED_URL 常指向只读镜像，不能带进发布流程。
publish_host="${PUBLISH_HOSTED_URL:-https://pub.dev}"

usage() {
  sed -n '2,24p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

if [ $# -lt 1 ]; then
  usage >&2
  exit 2
fi

case "$1" in
  -h | --help)
    usage
    exit 0
    ;;
esac

target="$1"
shift

dry_run=""
stage_only=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) dry_run="--dry-run" ;;
    --stage-only) stage_only="1" ;;
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

src="$(cd "$repo_root/$target" && pwd)"
case "$src" in
  "$repo_root" | "$repo_root"/*) ;;
  *)
    echo "目标必须在仓库内: $target" >&2
    exit 2
    ;;
esac

if [ ! -f "$src/pubspec.yaml" ]; then
  echo "找不到 $src/pubspec.yaml" >&2
  exit 2
fi

staging="$(mktemp -d "${TMPDIR:-/tmp}/w-tools-publish.XXXXXX")"
cleanup() {
  if [ -z "$stage_only" ]; then
    rm -rf "$staging"
  fi
}
trap cleanup EXIT

rsync -a \
  --exclude '.git' \
  --exclude '.dart_tool' \
  --exclude 'build' \
  --exclude 'coverage' \
  --exclude '.flutter-plugins' \
  --exclude '.flutter-plugins-dependencies' \
  --exclude 'pubspec.lock' \
  --exclude 'test' \
  --exclude 'docs' \
  --exclude 'scripts' \
  --exclude '.github' \
  --exclude '.idea' \
  --exclude '*.iml' \
  --exclude '.DS_Store' \
  "$src/" "$staging/"

# 根包只发布聚合层本身，8 个子包各自独立发布
if [ "$src" = "$repo_root" ]; then
  rm -rf "$staging/packages"
fi

python3 - "$staging/pubspec.yaml" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
lines = path.read_text().splitlines(keepends=True)
out = []
skipping = False
for line in lines:
    if re.match(r'^workspace:\s*$', line):
        skipping = True
        continue
    if skipping:
        # workspace 的值是 `  - path` 列表；遇到其它行就结束跳过
        if re.match(r'^\s+-\s+', line):
            continue
        skipping = False
    out.append(line)

text = ''.join(out)
text = re.sub(r'^resolution:\s*workspace\s*\n', '', text, flags=re.M)
path.write_text(text)
PY

if grep -qE '^(workspace:|resolution:[[:space:]]*workspace)' "$staging/pubspec.yaml"; then
  echo "暂存 pubspec 仍包含 workspace 字段，发布中止" >&2
  exit 1
fi

echo "== 发布目标: $publish_host"
if [ "$publish_host" != "https://pub.dev" ]; then
  echo "!! 注意：目标不是 pub.dev" >&2
fi
echo "== 暂存目录: $staging"
grep -nE '^(name|version):' "$staging/pubspec.yaml"

publish_runner=flutter
if ! grep -qE 'sdk:[[:space:]]*flutter' "$staging/pubspec.yaml"; then
  publish_runner=dart
fi
echo "== 发布方式: $publish_runner pub publish"

version="$(sed -n 's/^version:[[:space:]]*//p' "$staging/pubspec.yaml" | head -n1)"
major="${version%%.*}"
rest="${version#*.}"
if [ "$major" != "0" ] && [ "$rest" != "0.0" ] && [ -f "$staging/CHANGELOG.md" ]; then
  if awk -v ver="$version" '
      $0 ~ "^##[ \t]+" ver "$" {found = 1; next}
      found && /^## / {exit}
      found {print}
    ' "$staging/CHANGELOG.md" | grep -qiE '^###[[:space:]]+Removed|breaking'; then
    echo "!! 警告：$version 的 CHANGELOG 含 Removed/breaking，按 semver 应作为 major（X.0.0）发布" >&2
  fi
fi

if [ -n "$stage_only" ]; then
  echo "== --stage-only：跳过发布，暂存目录保留"
  exit 0
fi

cd "$staging"
PUB_HOSTED_URL="$publish_host" "$publish_runner" pub publish $dry_run
