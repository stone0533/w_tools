#!/usr/bin/env python3
"""AGENTS 片段预算的历史趋势（周检用）。

数据来源是仓库里的 `docs/metrics/agents_budget.jsonl`：一个 CLI 版本一行，
由 `packages/cli/tool/agent_budget.dart --record` 在发布时写入
（`--check` 会拦住「版本抬了但没记录」）。**本脚本只读、只排版**，不测量：
周检不需要 Dart / pub get，也不依赖外网。

输出是 Markdown，同时打印到 stdout 和 `$GITHUB_STEP_SUMMARY`（传 --summary）。
退出码：0 正常；1 历史缺失 / 坏行（趋势数据断了）；2 用法错误。
"""
from __future__ import annotations

import json
import pathlib
import sys

SCHEMA_PREFIX = 'w_tools_cli.agent_budget/'
DEFAULT_HISTORY = 'docs/metrics/agents_budget.jsonl'
DEFAULT_CLI_PUBSPEC = 'packages/cli/pubspec.yaml'


def load_records(text: str, source: str = 'history') -> list[dict]:
    """逐行解析；任何坏行都直接报错（趋势断档比「少一行」更严重）。"""
    records: list[dict] = []
    for index, line in enumerate(text.splitlines(), start=1):
        if not line.strip():
            continue
        try:
            record = json.loads(line)
        except json.JSONDecodeError as error:
            raise ValueError(f'{source}:{index} 不是合法 JSON：{error}') from error
        if not isinstance(record, dict):
            raise ValueError(f'{source}:{index} 不是 JSON 对象')
        schema = record.get('schema')
        if not isinstance(schema, str) or not schema.startswith(SCHEMA_PREFIX):
            raise ValueError(f'{source}:{index} schema 不是 {SCHEMA_PREFIX}*：{schema!r}')
        if not isinstance(record.get('generator'), str):
            raise ValueError(f'{source}:{index} 缺少 generator')
        rows = record.get('rows')
        if not isinstance(rows, list) or not rows:
            raise ValueError(f'{source}:{index} 缺少 rows')
        record['_line'] = index
        records.append(record)
    return records


def _row(record: dict, lang: str, profile: str) -> dict | None:
    for row in record['rows']:
        if row.get('lang') == lang and row.get('profile') == profile:
            return row
    return None


def _cell(record: dict, lang: str, profile: str) -> str:
    row = _row(record, lang, profile)
    if row is None:
        return '—'
    lines = row.get('lines')
    limit = row.get('limitLines')
    if not isinstance(lines, int) or not isinstance(limit, int) or limit <= 0:
        return '—'
    return f'{lines}/{limit} ({round(lines / limit * 100)}%)'


def _total_chars(record: dict) -> int:
    total = 0
    for row in record['rows']:
        chars = row.get('chars')
        if isinstance(chars, int):
            total += chars
    return total


def _feedback(record: dict) -> str:
    feedback = record.get('feedback')
    if not isinstance(feedback, dict):
        return '—'
    zh, en = feedback.get('zh'), feedback.get('en')
    if isinstance(zh, int) and isinstance(en, int):
        return f'{zh}/{en}'
    return '—'


def _delta(record: dict, previous: dict | None) -> str:
    if previous is None:
        return '—'
    diff = _total_chars(record) - _total_chars(previous)
    if diff == 0:
        return '0'
    return f'{diff:+d}'


def render(records: list[dict], *, limit: int = 8) -> str:
    if not records:
        return '### AGENTS 片段预算趋势\n\n_历史为空：先跑 `dart run tool/agent_budget.dart --record`。_\n'
    shown = records[-limit:]
    first_index = len(records) - len(shown)
    lines = [
        '### AGENTS 片段预算趋势',
        '',
        f'数据：`{DEFAULT_HISTORY}`（一个 CLI 版本一行；阈值在 `packages/cli/catalog/agent_budget.yaml`）',
        '',
        '| CLI 版本 | 记录时间 | zh/full 行 | en/full 行 | zh/minimal | en/minimal | 合计字符 | 字符 Δ | 反馈行 |',
        '|---|---|---:|---:|---:|---:|---:|---:|---:|',
    ]
    for offset, record in enumerate(shown):
        previous = records[first_index + offset - 1] if first_index + offset > 0 else None
        measured_at = str(record.get('measuredAt', '—')).replace('T', ' ')[:19]
        lines.append(
            '| '
            + ' | '.join(
                [
                    str(record['generator']),
                    measured_at,
                    _cell(record, 'zh', 'full'),
                    _cell(record, 'en', 'full'),
                    _cell(record, 'zh', 'minimal'),
                    _cell(record, 'en', 'minimal'),
                    str(_total_chars(record)),
                    _delta(record, previous),
                    _feedback(record),
                ]
            )
            + ' |'
        )
    latest = records[-1]
    lines += [
        '',
        f'最新记录：`{latest["generator"]}`（{_total_chars(latest)} 字符）',
        '',
    ]
    return '\n'.join(lines)


def cli_version(pubspec: pathlib.Path) -> str | None:
    if not pubspec.exists():
        return None
    for line in pubspec.read_text().splitlines():
        if line.startswith('version:'):
            return line.split(':', 1)[1].strip()
    return None


def main(argv: list[str]) -> int:
    history_path = pathlib.Path(DEFAULT_HISTORY)
    summary_path: pathlib.Path | None = None
    pubspec_path = pathlib.Path(DEFAULT_CLI_PUBSPEC)
    limit = 8

    index = 0
    while index < len(argv):
        arg = argv[index]
        if arg == '--history' and index + 1 < len(argv):
            history_path = pathlib.Path(argv[index + 1])
            index += 2
        elif arg == '--summary' and index + 1 < len(argv):
            summary_path = pathlib.Path(argv[index + 1])
            index += 2
        elif arg == '--pubspec' and index + 1 < len(argv):
            pubspec_path = pathlib.Path(argv[index + 1])
            index += 2
        elif arg == '--limit' and index + 1 < len(argv):
            try:
                limit = int(argv[index + 1])
            except ValueError:
                print(f'--limit 需要整数：{argv[index + 1]}', file=sys.stderr)
                return 2
            index += 2
        elif arg in ('-h', '--help'):
            print(__doc__)
            return 0
        else:
            print(f'未知参数：{arg}', file=sys.stderr)
            return 2

    if limit <= 0:
        print('--limit 必须 > 0', file=sys.stderr)
        return 2
    if not history_path.exists():
        print(f'✗ 缺少 {history_path}：趋势数据断了（跑 dart run tool/agent_budget.dart --record）', file=sys.stderr)
        return 1
    try:
        records = load_records(history_path.read_text(), str(history_path))
    except ValueError as error:
        print(f'✗ {error}', file=sys.stderr)
        return 1
    if not records:
        print(f'✗ {history_path} 为空：先跑 --record', file=sys.stderr)
        return 1

    markdown = render(records, limit=limit)

    version = cli_version(pubspec_path)
    if version is not None and records[-1]['generator'] != version:
        print(
            f'::warning::{history_path} 最新记录是 {records[-1]["generator"]}，'
            f'当前 CLI 是 {version}：发布前跑 `dart run tool/agent_budget.dart --record` 并提交',
        )

    print(markdown)
    if summary_path is not None:
        with summary_path.open('a') as summary:
            summary.write(markdown + '\n')
    return 0


if __name__ == '__main__':
    raise SystemExit(main(sys.argv[1:]))
