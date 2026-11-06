#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
git config core.hooksPath .githooks
echo "已安装 git hooks: core.hooksPath=.githooks（pre-push 禁止直接 push main）"
