#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
git config core.hooksPath .githooks
echo "已安装 git hooks: core.hooksPath=.githooks"
echo "  pre-commit  只查已暂存 .dart 的格式（<1s）"
echo "  commit-msg  conventional commit 标题（Merge / Revert / fixup! / squash! 除外）"
echo "  pre-push    禁止直接 push main"
