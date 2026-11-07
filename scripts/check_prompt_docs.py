#!/usr/bin/env python3
"""检查文档里的命令是否可执行。

1) `docs/ai-maintainer-prompts.md` 是维护者直接复制粘贴的提示词手册，规则最严：
   命令可执行 + 生成器 cwd 正确 + 占位符都有定义 + 场景编号都有标题 + CLI flag 存在。
2) 其余**当前文档**（README / AGENTS / CONTRIBUTING / scripts/README / docs 顶层与
   agents·recipes·guides·feedback / 包 README）只校验「脚本存在 + flag 被脚本或 CLI 认识」。
   历史目录（analysis / adr / migrations）不参与：它们允许记录旧命令。

规则：
1. 引用的 scripts/*.sh|py 必须存在；
2. `bash scripts/x.sh --flag` / `python3 scripts/x.py --flag` 里的 flag 必须被该脚本认识；
3. （仅提示词手册）代码块里 `dart run tool/<file>.dart` / `dart test test/<file>.dart`
   必须在 `cd packages/cli` 之后（`cd ../..` 之后再跑同样算错）；
4. （仅提示词手册）不允许残留 `<...>` 占位符；
5. （仅提示词手册）正文占位符必须出现在填空表里（表下说明里的 <runner> 等除外）；
6. （仅提示词手册）§1 场景选择里引用的 A~Z / X-n 必须有对应标题；
7. 其余当前文档：脚本存在、flag 被脚本认识；
8. `dart run w_tools_cli:<sub>` 的 flag 必须被 packages/cli/bin/<sub>.dart 认识。
"""
from __future__ import annotations

import argparse
import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
DEFAULT_DOC = root / 'docs/ai-maintainer-prompts.md'
CLI_BIN = root / 'packages' / 'cli' / 'bin'
CLI_CALL = re.compile(r'w_tools_cli:(?:w_tools\s+)?([a-z][a-z0-9-]*)([^\n]*)')
DOCUMENTED_BELOW = {'<runner>', '<包目录>', '<pkg1>', '<pkg2>'}


def command_flags(tail: str) -> list[str]:
    """取一条命令里的 flag；在反引号 / 中文括号 / 注释 / 表格分隔处截断。

    否则同一行后面解释性文字里的 `--check` 会被算到前一个脚本头上。
    """
    tail = re.split(r'[`（(#|]', tail, maxsplit=1)[0]
    return re.findall(r'--[A-Za-z][A-Za-z0-9-]*', tail)


def script_exists_errors(text: str, name: str) -> list[str]:
    errors: list[str] = []
    for lineno, line in enumerate(text.splitlines(), 1):
        for match in re.finditer(r'scripts/([A-Za-z0-9_.-]+\.(?:sh|py))', line):
            if not (root / 'scripts' / match.group(1)).exists():
                errors.append(f'{name}:{lineno}: 引用的脚本不存在：scripts/{match.group(1)}')
    return errors


def script_flag_errors(text: str, name: str) -> list[str]:
    errors: list[str] = []
    for lineno, line in enumerate(text.splitlines(), 1):
        for match in re.finditer(
            r'(?:bash|python3)\s+scripts/([A-Za-z0-9_.-]+\.(?:sh|py))([^\n]*)', line
        ):
            script = root / 'scripts' / match.group(1)
            if not script.exists():
                continue  # 规则 1 已报
            body = script.read_text()
            for flag in command_flags(match.group(2)):
                # 按完整 token 匹配：`--with-test` 不能因为 `--with-tests` 存在就算认识。
                if not re.search(rf'(?<![\w-]){re.escape(flag)}(?![\w-])', body):
                    errors.append(f'{name}:{lineno}: {match.group(1)} 不认识 {flag}')
    return errors


def cwd_errors(text: str, name: str) -> list[str]:
    errors: list[str] = []
    in_fence = False
    at_cli = False
    for lineno, line in enumerate(text.splitlines(), 1):
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
                f'{name}:{lineno}: 缺少 cd packages/cli（生成器 / 契约测试只在这个目录下成立）',
            )
    return errors


def placeholder_errors(text: str, name: str) -> list[str]:
    errors: list[str] = []
    for lineno, line in enumerate(text.splitlines(), 1):
        if '<...>' in line:
            errors.append(f'{name}:{lineno}: 残留 <...>，换成填空表里的具名占位符')

    defined = set(re.findall(r'^\| `(<[^`]+>)` \|', text, re.M))
    used = set(re.findall(r'<[A-Za-z\u4e00-\u9fff][^<>\s]{0,15}>', text))
    for placeholder in sorted(used - defined - DOCUMENTED_BELOW):
        errors.append(f'{name}: 未定义的占位符 {placeholder}（补进填空表，或写进表下说明）')
    return errors


def scenario_errors(text: str, name: str) -> list[str]:
    errors: list[str] = []
    heading_ids = set(
        re.findall(r'^#{2,3}\s+([A-Z](?:-\d+[A-Z]?)?)[.\s]', text, re.M),
    )
    selection = re.search(r'^## 1\. 场景选择.*?(?=^## )', text, re.S | re.M)
    if selection is None:
        errors.append(f'{name}: 缺少「## 1. 场景选择」一节')
    else:
        referenced = set(re.findall(r'\b([A-Z](?:-\d+[A-Z]?)?)\b', selection.group(0)))
        for scenario in sorted(referenced - heading_ids):
            errors.append(f'{name}: 场景选择引用了 {scenario}，但正文没有对应标题')
    return errors


def _cli_flags(subcommand: str) -> set[str] | None:
    path = CLI_BIN / f'{subcommand}.dart'
    if not path.is_file():
        return None
    body = path.read_text()
    flags = set(re.findall(r'--([A-Za-z][A-Za-z0-9-]*)', body))
    flags |= set(re.findall(r"addFlag\('([^']+)'\)", body))
    flags |= set(re.findall(r"addOption\('([^']+)'\)", body))
    if subcommand == 'init':
        # init 的 `--<feature>` / `--no-<feature>` 由 initFeatureSpecs 动态生成，不在 bin 里
        # 逐条 addFlag；从 features.dart 取，避免 `--no-async` 这类被误报。
        features = CLI_BIN.parent / 'lib' / 'src' / 'init' / 'features.dart'
        if features.is_file():
            for flag in re.findall(
                r"InitFeatureSpec\([^,]+,\s*'([a-z0-9-]+)'", features.read_text()
            ):
                flags.add(flag)
                flags.add(f'no-{flag}')
    return flags


def cli_flag_errors(text: str, name: str) -> list[str]:
    """`dart run w_tools_cli:w_tools <sub> --flag` 的 flag 必须被对应 bin 认识。"""
    errors: list[str] = []
    cache: dict[str, set[str] | None] = {}
    for lineno, line in enumerate(text.splitlines(), 1):
        for match in CLI_CALL.finditer(line):
            subcommand, tail = match.group(1), match.group(2)
            if subcommand not in cache:
                cache[subcommand] = _cli_flags(subcommand)
            flags = cache[subcommand]
            if flags is None:
                continue  # 不是已知子命令（可能是描述性文字）
            for flag in re.findall(r'--([A-Za-z][A-Za-z0-9-]*)', tail):
                if flag not in flags:
                    errors.append(f'{name}:{lineno}: w_tools {subcommand} 不认识 --{flag}')
    return errors


def command_docs() -> list[pathlib.Path]:
    docs: list[pathlib.Path] = [
        root / 'README.md',
        root / 'AGENTS.md',
        root / 'CONTRIBUTING.md',
        root / 'scripts/README.md',
    ]
    docs += sorted((root / 'docs').glob('*.md'))
    for sub in ('agents', 'recipes', 'guides', 'feedback'):
        docs += sorted((root / 'docs' / sub).glob('*.md'))
    docs += sorted((root / 'packages').glob('*/README.md'))
    docs += sorted((root / 'packages').glob('*/AGENTS.md'))
    return sorted(set(docs))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--doc', default=str(DEFAULT_DOC), help='提示词手册路径（测试用）')
    args = parser.parse_args(argv)
    doc = pathlib.Path(args.doc)
    if not doc.is_file():
        print(f'缺少 {doc}', file=sys.stderr)
        return 2

    text = doc.read_text()
    name = doc.name
    errors: list[str] = []
    errors += script_exists_errors(text, name)
    errors += script_flag_errors(text, name)
    errors += cwd_errors(text, name)
    errors += placeholder_errors(text, name)
    errors += scenario_errors(text, name)
    errors += cli_flag_errors(text, name)

    for path in command_docs():
        if not path.is_file() or path.name == 'ai-maintainer-prompts.md':
            continue
        other = path.read_text()
        rel = str(path.relative_to(root))
        errors += script_exists_errors(other, rel)
        errors += script_flag_errors(other, rel)
        errors += cli_flag_errors(other, rel)

    if errors:
        for error in errors:
            print(f'✗ {error}', file=sys.stderr)
        print(f'\n文档命令检查失败：{len(errors)} 项', file=sys.stderr)
        return 1
    print('文档命令检查通过（提示词手册 + 当前文档）')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
