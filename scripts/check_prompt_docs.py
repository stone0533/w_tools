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
8. `dart run w_tools_cli:<sub>` 的 flag 必须被 packages/cli/bin/<sub>.dart 认识，
   未知子命令报错；以 `\\` 结尾的续行会先拼成一条逻辑行再校验；
9. （仅提示词手册）代码块里的 `docs/**.md` / `packages/**.md` 路径必须存在
   （模板路径 `<>` 不匹配；其它文档可能写「输出到 docs/x.md」这类未来路径，不做此检查）；
10. （仅提示词手册）`dart run tool/<file>` / `dart test test/<file>` 的文件必须存在；
    场景标题不能重复，且每个顶层场景都必须在 §1 出现（反向也要能查到）。
"""
from __future__ import annotations

import argparse
import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
DEFAULT_DOC = root / 'docs/ai-maintainer-prompts.md'
CLI_BIN = root / 'packages' / 'cli' / 'bin'
# `w_tools_cli:w_tools <sub>` 或 `w_tools_cli:<sub>`；末尾的 (?![\w_]) 防止把裸
# `w_tools_cli:w_tools`（后面没有子命令）回退匹配成子命令 `w`。
CLI_CALL = re.compile(
    r'w_tools_cli:(?:w_tools\s+([a-z][a-z0-9-]*)(?![\w_])|([a-z][a-z0-9-]*)(?![\w_]))([^\n]*)'
)
DOC_PATH = re.compile(r'(?<![\w<])((?:docs|packages)/[A-Za-z0-9_./-]+\.md)')
DOCUMENTED_BELOW = {'<runner>', '<包目录>', '<pkg1>', '<pkg2>'}


def logical_lines(text: str) -> list[tuple[int, str]]:
    """把以 `\\` 结尾的续行拼成一条逻辑行，并保留起始行号。

    否则 `feedback submit \\` 下一行的 `--package` / `--ledger` 不会被校验。
    """
    raw = text.splitlines()
    out: list[tuple[int, str]] = []
    index = 0
    while index < len(raw):
        start = index + 1
        buffer = raw[index]
        while buffer.rstrip().endswith('\\') and index + 1 < len(raw):
            buffer = buffer.rstrip()[:-1].rstrip() + ' ' + raw[index + 1].strip()
            index += 1
        out.append((start, buffer))
        index += 1
    return out


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
    for lineno, line in logical_lines(text):
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


def path_exists_errors(text: str, name: str) -> list[str]:
    """代码块里的 `docs/**.md` / `packages/**.md` 路径必须存在。

    这些路径不是 Markdown 链接，链接检查看不到（旧的 docs/agents/w_tools.md 就是这样漏的）。
    含 `<...>` 的模板路径不会被 DOC_PATH 匹配，天然跳过。
    """
    errors: list[str] = []
    for lineno, line in logical_lines(text):
        for match in DOC_PATH.finditer(line):
            path = match.group(1)
            if not (root / path).is_file():
                errors.append(f'{name}:{lineno}: 引用的路径不存在：{path}')
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
    top_level = re.findall(r'^##\s+([A-Z])[.\s]', text, re.M)
    seen: set[str] = set()
    for letter in top_level:
        if letter in seen:
            errors.append(f'{name}: 场景 {letter} 有重复标题（每个场景只能出现一次）')
        seen.add(letter)

    heading_ids = set(
        re.findall(r'^#{2,3}\s+([A-Z](?:-\d+[A-Z]?)?)[.\s]', text, re.M),
    )
    selection = re.search(r'^## 1\. 场景选择.*?(?=^## )', text, re.S | re.M)
    if selection is None:
        errors.append(f'{name}: 缺少「## 1. 场景选择」一节')
        return errors

    selection_text = selection.group(0)
    for letter in sorted(seen):
        if not re.search(rf'\b{letter}\b', selection_text):
            errors.append(f'{name}: 场景 {letter} 有标题，但 §1 场景选择没有列出（读者找不到）')

    referenced = set(re.findall(r'\b([A-Z](?:-\d+[A-Z]?)?)\b', selection_text))
    for scenario in sorted(referenced - heading_ids):
        errors.append(f'{name}: 场景选择引用了 {scenario}，但正文没有对应标题')
    return errors


DART_TOOL = re.compile(r'dart\s+run\s+tool/([A-Za-z0-9_]+\.dart)')
DART_TEST = re.compile(r'dart\s+test\s+test/([A-Za-z0-9_/.-]+\.dart)')


def dart_file_errors(text: str, name: str) -> list[str]:
    """`dart run tool/<file>` / `dart test test/<file>` 的文件必须存在（相对 packages/cli）。"""
    errors: list[str] = []
    for lineno, line in logical_lines(text):
        for match in DART_TOOL.finditer(line):
            path = root / 'packages' / 'cli' / 'tool' / match.group(1)
            if not path.is_file():
                errors.append(f'{name}:{lineno}: 生成器不存在：packages/cli/tool/{match.group(1)}')
        for match in DART_TEST.finditer(line):
            path = root / 'packages' / 'cli' / 'test' / match.group(1)
            if not path.is_file():
                errors.append(f'{name}:{lineno}: 测试文件不存在：packages/cli/test/{match.group(1)}')
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
    """`dart run w_tools_cli:w_tools <sub> --flag` 的 flag 必须被对应 bin 认识。

    续行（`\\`）会先拼成逻辑行；未知子命令也报错，避免 `lst` 这种拼写错误静默通过。
    """
    errors: list[str] = []
    cache: dict[str, set[str] | None] = {}
    for lineno, line in logical_lines(text):
        for match in CLI_CALL.finditer(line):
            subcommand = match.group(1) or match.group(2)
            tail = match.group(3)
            if subcommand not in cache:
                cache[subcommand] = _cli_flags(subcommand)
            flags = cache[subcommand]
            if flags is None:
                errors.append(
                    f'{name}:{lineno}: 未知的 w_tools 子命令 {subcommand}'
                    f'（没有 packages/cli/bin/{subcommand}.dart）'
                )
                continue
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
    errors += path_exists_errors(text, name)
    errors += dart_file_errors(text, name)

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
