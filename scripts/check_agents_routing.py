#!/usr/bin/env python3
"""AGENTS 模板的「锚」检查：每条 bullet 必须指向某个可查的东西。

为什么需要这条：消费方 AGENTS 是**常驻上下文**，它变胖最隐蔽的方式不是「多写一行」，
而是「写一段没有任何出口的知识」——用哪个组件、什么参数、哪个旧名删了。这类内容
应该待在 catalog（`explain`）或工具 README / `--help` 里；AGENTS 只留「不查也必须
遵守」的约束 + 指针（判据见 `docs/ai-contract.md` §3.3）。

判据（任一即可）：
- `explain <组件>` 指针；
- 反引号里的路径（`lib/app/ui/`、`.w_tools/AI_PROMPTS.md`）；
- 反引号里的配置 / 生成物文件名（`*.yaml` / `*.json` / `*.dart` / `*.md`）；
- doctor 规则号（R1~R9）；
- 可执行命令（`dart run …`、`dart pub add …`、`flutter analyze` / `flutter test`）；
- 模板占位符（`{{analyze}}` / `{{toolkitImport}}` …，渲染后是命令或路径）。

确实不需要出口的流程句可以显式豁免，**必须写理由**：

    <!-- no-anchor: 这是流程要求，没有可查的细节 -->

只扫 `packages/cli/templates/agents/{zh,en}/*.md`（模板源，渲染前）。渲染后的行数 /
字符数预算由 `packages/cli/tool/agent_budget.dart` 负责，不在这里重复。
"""
from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TEMPLATES = ROOT / 'packages/cli/templates/agents'

ANCHORS = [
    re.compile(r'`explain\s+[A-Za-z]'),                        # explain 指针
    re.compile(r'`[^`\n]*/[^`\n]*`'),                          # 反引号里的路径
    re.compile(r'`[^`\n]*\.(?:dart|md|yaml|json)`'),           # 反引号里的文件
    re.compile(r'\bR[1-9]\b'),                                 # doctor 规则号
    re.compile(r'(?:^|[`\s])(?:dart run|dart pub add|flutter analyze|flutter test)\b'),
    re.compile(r'\{\{[a-zA-Z]+\}\}'),                          # 模板占位符
]

EXEMPT = re.compile(r'<!--\s*no-anchor:\s*(.*?)\s*-->', re.S)
BULLET = re.compile(r'^(?:- |\d+\. )')
FENCE = re.compile(r'^\s*```')
HEADING = re.compile(r'^#{1,6}\s')


def entries(text: str) -> list[tuple[int, str]]:
    """把文件切成「条目」：bullet / 编号项 + 缩进续行；表格与标题不算条目。

    返回 [(起始行号从 1 开始, 条目全文)]。紧邻条目的 `no-anchor` 注释会并进条目，
    这样豁免可以写在条目上一行。
    """
    lines = text.splitlines()
    out: list[tuple[int, str]] = []
    pending_comment: str | None = None
    in_fence = False
    current: list[str] = []
    start = 0

    def flush() -> None:
        nonlocal current, pending_comment
        if current:
            body = '\n'.join(current)
            if pending_comment:
                body = f'{pending_comment}\n{body}'
            out.append((start, body))
            pending_comment = None
        current = []

    for index, line in enumerate(lines, start=1):
        if FENCE.match(line):
            in_fence = not in_fence
            flush()
            pending_comment = None
            continue
        if in_fence:
            continue
        stripped = line.strip()
        if not stripped:
            flush()
            pending_comment = None
            continue
        if HEADING.match(line) or stripped.startswith('|'):
            flush()
            pending_comment = None
            continue
        if stripped.startswith('<!--') and stripped.endswith('-->'):
            core = stripped[len('<!--') : -len('-->')].strip()
            flush()
            pending_comment = stripped if core.startswith('no-anchor:') else None
            continue
        if BULLET.match(line):
            flush()
            current = [line]
            start = index
            continue
        if current and line.startswith((' ', '\t')):
            current.append(line)
            continue
        # 正文段落：不检查（预算会挡住整段增长）
        flush()
        pending_comment = None
    flush()
    return out


def has_anchor(body: str) -> bool:
    return any(pattern.search(body) for pattern in ANCHORS)


def check_file(path: pathlib.Path) -> tuple[list[str], int, int]:
    errors: list[str] = []
    checked = 0
    exempted = 0
    for line_no, body in entries(path.read_text()):
        match = EXEMPT.search(body)
        if match is not None:
            if not match.group(1).strip():
                errors.append(f'{path}:{line_no}: no-anchor 豁免必须写理由')
            exempted += 1
            continue
        checked += 1
        if has_anchor(body):
            continue
        first = body.splitlines()[0].strip()
        errors.append(
            f'{path}:{line_no}: 这一条没有锚（explain / 路径 / 规则号 / 命令）\n'
            f'    内容: {first}\n'
            f'    修法: 接一个可查的出口；确实不需要就写 <!-- no-anchor: 理由 -->',
        )
    return errors, checked, exempted


def main() -> int:
    files = sorted(TEMPLATES.glob('*/*.md'))
    if not files:
        print(f'✗ 没有找到模板：{TEMPLATES}', file=sys.stderr)
        return 1

    errors: list[str] = []
    stats: dict[str, tuple[int, int]] = {}
    for path in files:
        file_errors, checked, exempted = check_file(path)
        errors.extend(file_errors)
        lang = path.parent.name
        prev_checked, prev_exempted = stats.get(lang, (0, 0))
        stats[lang] = (prev_checked + checked, prev_exempted + exempted)

    if errors:
        for error in errors:
            print(f'✗ {error}', file=sys.stderr)
        print(f'\nAGENTS 模板锚检查失败：{len(errors)} 项', file=sys.stderr)
        return 1

    summary = ' / '.join(
        f'{lang} {checked} 条（豁免 {exempted}）' for lang, (checked, exempted) in sorted(stats.items())
    )
    print(f'✓ AGENTS 模板每条都有锚：{summary}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
