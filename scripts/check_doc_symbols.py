#!/usr/bin/env python3
"""检查文档代码块里的 W 符号：类存在，且 `WXxx.member` 成员存在。

只扫推荐路径（docs/agents、docs/recipes、docs/modules、packages/*/README.md），
跳过迁移 / 分析 / ADR（历史文档允许出现已删除的名字）。

- `WXxx(` 的 `WXxx` 必须能在 packages/*/lib 找到 class / enum / mixin / extension / typedef；
- `WXxx.member` 的 member 必须在该类（深度 1）声明，或属于 Object 的通用成员。
"""
from __future__ import annotations

import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
decl_re = re.compile(r'\b(?:class|enum|mixin|extension|typedef)\s+(W[A-Za-z0-9_]+)')
type_start_re = re.compile(r'\b(?:class|enum|mixin|extension)\s+(W[A-Za-z0-9_]+)')
member_re = re.compile(r'\b(?:get\s+)?([a-zA-Z_]\w*)\s*(?:<[^>\n]*>)?\s*(?:\(|;|=)')
constructor_re = re.compile(r'\b(W[A-Za-z0-9_]+)\s*\(')
skip_members = {
    'if', 'for', 'while', 'switch', 'catch', 'return', 'assert', 'super', 'this',
    'throw', 'await', 'yield', 'else', 'case', 'default', 'try', 'do', 'new',
}

declared: set[str] = set()
members: dict[str, set[str]] = {}


def _strip_comments(text: str) -> str:
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
    return re.sub(r'//[^\n]*', '', text)


def _class_body(text: str, start: int) -> str:
    brace = text.find('{', start)
    if brace < 0:
        return ''
    depth = 0
    for i in range(brace, len(text)):
        if text[i] == '{':
            depth += 1
        elif text[i] == '}':
            depth -= 1
            if depth == 0:
                return text[brace + 1 : i]
    return ''


def _collect_members(body: str, name: str) -> set[str]:
    out: set[str] = set()
    depth = 0
    for raw in body.splitlines():
        line = raw.strip()
        if not line:
            continue
        if depth == 0:
            getter = re.search(r'\bget\s+([A-Za-z_]\w*)', line)
            if getter:
                out.add(getter.group(1))
            enum_value = re.match(r'^([A-Za-z_]\w*)\s*(?:,|$|;|\()', line)
            if enum_value and not line.startswith(('if ', 'return ', 'const ', 'final ')):
                out.add(enum_value.group(1))
            for match in member_re.finditer(line):
                token = match.group(1)
                if token not in skip_members and not token.startswith('_'):
                    out.add(token)
        depth += line.count('{') - line.count('}')
    return out


for path in (root / 'packages').glob('*/lib/**/*.dart'):
    text = _strip_comments(path.read_text())
    declared.update(decl_re.findall(text))
    for match in type_start_re.finditer(text):
        name = match.group(1)
        body = _class_body(text, match.start())
        members.setdefault(name, set()).update(_collect_members(body, name))
        # 命名构造函数（WXxx.named）
        for ctor in re.finditer(rf'\b{re.escape(name)}\.([A-Za-z_]\w*)\s*\(', body):
            members[name].add(ctor.group(1))

object_members = {'copyWith', 'toString', 'hashCode', 'runtimeType', 'noSuchMethod'}

targets: list[pathlib.Path] = []
for sub in ('docs/agents', 'docs/recipes', 'docs/modules'):
    targets.extend(sorted((root / sub).glob('*.md')))
targets.extend(sorted((root / 'packages').glob('*/README.md')))
# 根 AGENTS.md 是仓库 AI 的主入口，代码块同样要对着源码校验。
targets.append(root / 'AGENTS.md')

call_re = re.compile(r'\b(W[A-Z][A-Za-z0-9_]*)\s*\(')
member_access_re = re.compile(r'\b(W[A-Z][A-Za-z0-9_]*)\.([a-zA-Z_]\w*)')
block_re = re.compile(r'```dart\n(.*?)```', re.S)
bad: list[str] = []

for path in targets:
    text = path.read_text()
    for block in block_re.findall(text):
        for match in call_re.finditer(block):
            name = match.group(1)
            if name not in declared:
                line = block[: match.start()].count('\n') + 1
                bad.append(f'{path.relative_to(root)}: 代码块第 {line} 行引用了未定义符号 {name}')
        for match in member_access_re.finditer(block):
            owner, member = match.group(1), match.group(2)
            if owner not in declared:
                continue
            if member in object_members:
                continue
            known = members.get(owner, set())
            if member not in known:
                line = block[: match.start()].count('\n') + 1
                bad.append(
                    f'{path.relative_to(root)}: 代码块第 {line} 行引用了未定义成员 {owner}.{member}'
                )

if bad:
    print('文档代码块引用了不存在的符号/成员：', file=sys.stderr)
    for item in bad:
        print(f'  ✗ {item}', file=sys.stderr)
    sys.exit(1)

print(f'✓ 文档代码块符号/成员检查通过（{len(targets)} 个文件）')
