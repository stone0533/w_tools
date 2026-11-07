#!/usr/bin/env bash
set -euo pipefail

CLI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEMO_DIR="$CLI_DIR/example/demo_project"
TMP_ROOT="${TMPDIR:-/tmp}"
TMP_ROOT="${TMP_ROOT%/}"
TMP="$(mktemp -d "$TMP_ROOT/w_tools_cli_demo.XXXXXX")"

cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

cp -R "$DEMO_DIR/." "$TMP/"

cd "$CLI_DIR"

# 干净 checkout 下先准备 CLI 依赖；已准备好时直接跳过。
if [ ! -d .dart_tool ]; then
  dart pub get
fi

echo "== init =="
dart run bin/w_tools.dart init --root="$TMP" --profile=minimal --no-ui --no-instructions

echo
echo "== init --check-drift =="
dart run bin/w_tools.dart init --root="$TMP" --profile=minimal --no-ui --no-instructions --check-drift

echo
echo "== doctor =="
dart run bin/w_tools.dart doctor --root="$TMP" --format=markdown

echo
echo "== context =="
dart run bin/w_tools.dart context --root="$TMP" --format=prompt --max-tokens=1200

echo
echo "== list =="
dart run bin/w_tools.dart list WForm

echo
echo "== explain =="
dart run bin/w_tools.dart explain WForm

echo
echo "== feedback =="
dart run bin/w_tools.dart feedback status --root="$TMP"
dart run bin/w_tools.dart feedback path --root="$TMP" --package=cli

echo
echo "临时 demo 项目：${TMP}"
echo "脚本退出后自动清理"
