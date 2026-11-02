#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

fixture="example/fixtures/nodes-demo.json"

echo '== frames =='
dart run bin/figma.dart frames --file="$fixture"

echo
echo '== spec (Markdown) =='
dart run bin/figma.dart spec 1:2 --file="$fixture"

echo
echo '== spec (JSON) =='
dart run bin/figma.dart spec 1:2 --file="$fixture" --json

echo
echo '== tokens =='
dart run bin/figma.dart tokens 1:2 --file="$fixture"

echo
echo '== tokens (min=2) =='
dart run bin/figma.dart tokens 1:2 --file="$fixture" --min=2
