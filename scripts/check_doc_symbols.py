#!/usr/bin/env python3
"""检查文档里的 W 符号：类存在，且 `WXxx.member` 成员存在。

只扫推荐路径（根 README / AGENTS.md、docs/agents、docs/recipes、docs/modules、docs/guides、
packages/*/README.md），跳过迁移 / 分析 / ADR（历史文档允许出现已删除的名字）。

- `WXxx(` 的 `WXxx` 必须能在 packages/*/lib 找到 class / enum / mixin / extension / typedef；
- `WXxx.member` 的 member 必须在该类（深度 1）声明，或属于 Object 的通用成员；
- `docs/naming.md` 是规则表，示例写在行内代码里：同样校验，但忽略该文件明确写成
  反例 / 历史名字的符号（见 `NAMING_DOC_IGNORE`）。
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
# 公开符号来自哪个包：用于验证「import 根 barrel 时符号确实由根包导出」。
symbol_packages: dict[str, set[str]] = {}


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
    package_name = f'w_tools_{path.relative_to(root / "packages").parts[0]}'
    for name in decl_re.findall(text):
        declared.add(name)
        symbol_packages.setdefault(name, set()).add(package_name)
    for match in type_start_re.finditer(text):
        name = match.group(1)
        body = _class_body(text, match.start())
        members.setdefault(name, set()).update(_collect_members(body, name))
        # 命名构造函数（WXxx.named）
        for ctor in re.finditer(rf'\b{re.escape(name)}\.([A-Za-z_]\w*)\s*\(', body):
            members[name].add(ctor.group(1))

object_members = {'copyWith', 'toString', 'hashCode', 'runtimeType', 'noSuchMethod'}

# 每个包的 barrel 可由 `import 'package:w_tools_xxx/...'` 提供的符号范围。
# 只解析 package 级 re-export（如 app_getx -> app）；src 文件仍按包归属处理。
package_reexports: dict[str, set[str]] = {}
for barrel in (root / 'packages').glob('*/lib/w_tools_*.dart'):
    package_name = f'w_tools_{barrel.relative_to(root / "packages").parts[0]}'
    package_reexports[package_name] = set(
        re.findall(r"export\s+'package:(w_tools_[a-z_]+)/", barrel.read_text())
    )

# 根 barrel 的导出范围。
root_barrel = (root / 'lib' / 'w_tools.dart').read_text()
root_exports = set(re.findall(r"export\s+'package:(w_tools_[a-z_]+)/", root_barrel))

targets: list[pathlib.Path] = []
for sub in ('docs/agents', 'docs/recipes', 'docs/modules', 'docs/guides'):
    targets.extend(sorted((root / sub).glob('*.md')))
targets.extend(sorted((root / 'packages').glob('*/README.md')))
# 根 README / AGENTS.md 是仓库的主入口，代码块同样要对着源码校验。
targets += [root / 'README.md', root / 'AGENTS.md', root / 'docs' / 'naming.md']

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

        # 反向检查 import 边界：代码块用到的 W 符号，必须由它 import 的包
        # （或该包再导出的包）提供。能拦住：
        # - import 根 barrel 却用 map / qr / app 等未聚合符号；
        # - import root + map 却用 map_google 的 WMap；
        # - import ui 却用 form 的 WFormButton。
        block_imports = set(re.findall(r"package:(w_tools(?:_[a-z_]+)?)/", block))
        if block_imports:
            clean_block = _strip_comments(block)
            for name in sorted(set(re.findall(r'\b(W[A-Z][A-Za-z0-9_]*)\b', clean_block))):
                packages = symbol_packages.get(name)
                if not packages:
                    continue
                reachable = bool(packages & block_imports)
                if not reachable:
                    for imported in block_imports:
                        if imported == 'w_tools':
                            reachable = bool(packages & root_exports)
                        else:
                            reachable = bool(packages & package_reexports.get(imported, set()))
                        if reachable:
                            break
                if reachable:
                    continue
                line = clean_block.find(name)
                line_no = clean_block[:line].count('\n') + 1 if line >= 0 else 1
                bad.append(
                    f'{path.relative_to(root)}: 代码块第 {line_no} 行 import 的包未导出 {name}；'
                    f'请直接 import 声明的包或改用已导出入口'
                )

NAMING_DOC = root / 'docs' / 'naming.md'
# naming.md 里有意写成不存在的反例 / 历史名字；新增反例时在这里登记。
NAMING_DOC_IGNORE = {
    'WImg', 'WBtn', 'WMsg', 'WQRView', 'WAPIConfig', 'WImageHelper',
    'WMapConfig', 'WImageLoadConfig', 'Widget', 'With',
}
inline_code_re = re.compile(r'`([^`\n]+)`')
inline_symbol_re = re.compile(
    r'(?<![A-Za-z0-9_])(W[A-Z][A-Za-z0-9_]*)(?:\.([a-zA-Z_]\w*))?'
)

if NAMING_DOC.exists():
    text = NAMING_DOC.read_text()
    for span in inline_code_re.finditer(text):
        line = text[: span.start()].count('\n') + 1
        for owner, member in inline_symbol_re.findall(span.group(1)):
            if owner in NAMING_DOC_IGNORE:
                continue
            if owner not in declared:
                bad.append(f'docs/naming.md:{line}: 引用了未定义符号 {owner}')
                continue
            if member in object_members or not member:
                continue
            if member not in members.get(owner, set()):
                bad.append(
                    f'docs/naming.md:{line}: 引用了未定义成员 {owner}.{member}'
                )

if bad:
    print('文档引用了不存在的符号/成员，或 import 的包未导出相关符号：', file=sys.stderr)
    for item in bad:
        print(f'  ✗ {item}', file=sys.stderr)
    sys.exit(1)

print(f'✓ 文档符号 / 成员 / import 导出边界检查通过（{len(targets)} 个文件）')
