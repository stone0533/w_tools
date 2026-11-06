#!/usr/bin/env python3
"""检查文档里的命令是否可执行。

1) `docs/ai-maintainer-prompts.md` 是维护者直接复制粘贴的提示词手册，规则最严：
   命令可执行 + 生成器 cwd 正确 + 占位符都有定义 + 场景编号都有标题。
2) 其余**当前文档**（README / AGENTS / CONTRIBUTING / scripts/README / docs 顶层与
   agents·recipes·guides·feedback / 包 README）只校验「脚本存在 + flag 被脚本认识」。
   历史目录（analysis / adr / migrations）不参与：它们允许记录旧命令。

规则：
1. 引用的 scripts/*.sh|py 必须存在；
2. `bash scripts/x.sh --flag` / `python3 scripts/x.py --flag` 里的 flag 必须被该脚本认识；
3. （仅提示词手册）代码块里 `dart run tool/<file>.dart` / `dart test test/<file>.dart`
   必须在 `cd packages/cli` 之后（`cd ../..` 之后再跑同样算错）；
4. （仅提示词手册）不允许残留 `<...>` 占位符；
5. （仅提示词手册）正文占位符必须出现在填空表里（或在表下说明里单独定义）；
6. （仅提示词手册）§1 场景选择里引用的 A~M / X-n 必须有对应标题。
"""
from __future__ import annotations

import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
doc = root / 'docs/ai-maintainer-prompts.md'
errors: list[str] = []

if not doc.exists():
    print(f'缺少 {doc.relative_to(root)}', file=sys.stderr)
    sys.exit(2)

text = doc.read_text()
lines = text.splitlines()

def command_flags(tail: str) -> list[str]:
    """取一条命令里的 flag；在反引号 / 中文括号 / 注释 / 表格分隔处截断。

    否则同一行后面解释性文字里的 `--check` 会被算到前一个脚本头上。
    """
    tail = re.split(r'[`（(#|]', tail, maxsplit=1)[0]
    return re.findall(r'--[A-Za-z][A-Za-z0-9-]*', tail)


# 1) 引用的脚本必须存在
for lineno, line in enumerate(lines, 1):
    for match in re.finditer(r'scripts/([A-Za-z0-9_.-]+\.(?:sh|py))', line):
        if not (root / 'scripts' / match.group(1)).exists():
            errors.append(f'{doc.name}:{lineno}: 引用的脚本不存在：scripts/{match.group(1)}')

# 2) 脚本调用里的 flag 必须被脚本认识
for lineno, line in enumerate(lines, 1):
    for match in re.finditer(r'(?:bash|python3)\s+scripts/([A-Za-z0-9_.-]+\.(?:sh|py))([^\n]*)', line):
        script = root / 'scripts' / match.group(1)
        if not script.exists():
            continue  # 规则 1 已报
        body = script.read_text()
        for flag in command_flags(match.group(2)):
            # 按完整 token 匹配：`--with-test` 不能因为 `--with-tests` 存在就算认识。
            if not re.search(rf'(?<![\w-]){re.escape(flag)}(?![\w-])', body):
                errors.append(f'{doc.name}:{lineno}: {match.group(1)} 不认识 {flag}')

# 3) 生成器 / 契约测试必须在 packages/cli 下跑（按代码块跟踪 cwd）
in_fence = False
at_cli = False
for lineno, line in enumerate(lines, 1):
    if line.startswith('```'):
        in_fence = not in_fence
        at_cli = False
        continue
    if not in_fence:
        continue
    stripped = line.strip()
    inline_cli = 'cd packages/cli' in stripped
    if re.match(r'cd\s+packages/cli(\s|$)', stripped):
        at_cli = True
    elif re.match(r'cd\s+', stripped) and '&&' not in stripped:
        at_cli = False  # cd 走了就不再算在 packages/cli
    needs_cli = re.search(
        r'\bdart\s+(?:run\s+tool/[A-Za-z0-9_]+\.dart|test\s+test/[A-Za-z0-9_]+\.dart)',
        line,
    )
    if needs_cli and not (at_cli or inline_cli):
        errors.append(
            f'{doc.name}:{lineno}: 缺少 cd packages/cli（生成器 / 契约测试只在这个目录下成立）',
        )

# 4) 不允许残留未命名的占位符
for lineno, line in enumerate(lines, 1):
    if '<...>' in line:
        errors.append(f'{doc.name}:{lineno}: 残留 <...>，换成填空表里的具名占位符')

# 5) 正文占位符必须在填空表里（表下说明里定义的少数几个除外）
defined = set(re.findall(r'^\| `(<[^`]+>)` \|', text, re.M))
documented_below = {'<runner>', '<包目录>', '<pkg1>', '<pkg2>'}
used = set(re.findall(r'<[A-Za-z\u4e00-\u9fff][^<>\s]{0,15}>', text))
for name in sorted(used - defined - documented_below):
    errors.append(f'{doc.name}: 未定义的占位符 {name}（补进填空表，或写进表下说明）')

# 6) 场景选择里引用的编号必须有对应标题
heading_ids = set(
    re.findall(r'^#{2,3}\s+([A-M](?:-\d+[A-Z]?)?)[.\s]', text, re.M),
)
selection = re.search(r'^## 1\. 场景选择.*?(?=^## )', text, re.S | re.M)
if selection is None:
    errors.append(f'{doc.name}: 缺少「## 1. 场景选择」一节')
else:
    referenced = set(re.findall(r'\b([A-M](?:-\d+[A-Z]?)?)\b', selection.group(0)))
    for scenario in sorted(referenced - heading_ids):
        errors.append(f'{doc.name}: 场景选择引用了 {scenario}，但正文没有对应标题')

# 7) 其余当前文档：脚本必须存在、flag 必须被脚本认识。
#    文档里的命令比提示词手册多一个数量级，改名 / 改 flag 后没人会逐条回读。
command_docs: list[pathlib.Path] = [
    root / 'README.md',
    root / 'AGENTS.md',
    root / 'CONTRIBUTING.md',
    root / 'scripts/README.md',
]
command_docs += sorted((root / 'docs').glob('*.md'))
for sub in ('agents', 'recipes', 'guides', 'feedback'):
    command_docs += sorted((root / 'docs' / sub).glob('*.md'))
command_docs += sorted((root / 'packages').glob('*/README.md'))
command_docs += sorted((root / 'packages').glob('*/AGENTS.md'))

script_ref = re.compile(r'scripts/([A-Za-z0-9_.-]+\.(?:sh|py))')
call_ref = re.compile(r'(?:bash|python3)\s+scripts/([A-Za-z0-9_.-]+\.(?:sh|py))([^\n]*)')


def check_commands(path: pathlib.Path) -> None:
    rel = path.relative_to(root)
    for lineno, line in enumerate(path.read_text().splitlines(), 1):
        for match in script_ref.finditer(line):
            if not (root / 'scripts' / match.group(1)).exists():
                errors.append(f'{rel}:{lineno}: 引用的脚本不存在：scripts/{match.group(1)}')
        for match in call_ref.finditer(line):
            script = root / 'scripts' / match.group(1)
            if not script.exists():
                continue  # 上面的存在性检查已经报过
            body = script.read_text()
            for flag in command_flags(match.group(2)):
                if not re.search(rf'(?<![\w-]){re.escape(flag)}(?![\w-])', body):
                    errors.append(f'{rel}:{lineno}: {match.group(1)} 不认识 {flag}')


for path in sorted(set(command_docs)):
    if path.is_file() and path.name != 'ai-maintainer-prompts.md':
        check_commands(path)

if errors:
    for error in errors:
        print(f'✗ {error}', file=sys.stderr)
    print(f'\n文档命令检查失败：{len(errors)} 项', file=sys.stderr)
    sys.exit(1)

print('文档命令检查通过（提示词手册 + 当前文档）')
