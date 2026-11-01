#!/usr/bin/env bash
set -euo pipefail

CLI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEMO_DIR="$CLI_DIR/example/demo_project"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/w_tools_cli_demo.XXXXXX")"

cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

cp -R "$DEMO_DIR/." "$TMP/"

cd "$CLI_DIR"

echo "== init =="
dart run bin/init.dart --root="$TMP" --profile=minimal --no-ui --no-instructions

echo
echo "== doctor =="
dart run bin/doctor.dart --root="$TMP" --format=markdown

echo
echo "== context =="
dart run bin/context.dart --root="$TMP" --format=prompt --max-tokens=1200

echo
echo "== list =="
dart run bin/list.dart WForm

echo
echo "== explain =="
dart run bin/explain.dart WForm

echo
echo "demo project: ${TMP}（脚本结束会清理）"
