#!/usr/bin/env python3
"""公开 API 快照 diff：删除 / 可空性 / 类型变化必须进 CHANGELOG Breaking 或 migration。

用法：
  python3 scripts/check_public_api_diff.py --package ui
  python3 scripts/check_public_api_diff.py --snapshot-from /tmp/ui_arch --package ui --version 6.1.1
"""
from __future__ import annotations

import argparse
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from _dart_exports import exported_types, strip_comments  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
SNAPSHOTS = ROOT / 'scripts/api_snapshots'

DECL = re.compile(r'\b(?:class|enum|mixin|extension|typedef)\s+([A-Z][A-Za-z0-9_]*)')
FIELD = re.compile(r'^(.+?)\s+([a-zA-Z]\w*)\s*(?:=|;|$)')
GETTER = re.compile(r'^([A-Za-z_][\w<>,?. ]*?)\s+get\s+([a-zA-Z]\w*)')
MODIFIER = re.compile(r'^(?:static\s+)?(?:final|const|late\s+final)\s+')
ENUM_VALUE = re.compile(r'^\s*([A-Za-z]\w*)\s*(?:,|;|$)', re.M)


def _body(text: str, start: int) -> str:
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
                return text[brace + 1:i]
    return ''


def _normalize(value: str) -> str:
    return re.sub(r'\s+', ' ', value).strip()


METHOD = re.compile(r'^([A-Za-z_][\w<>,?. ]*)\s+([a-zA-Z]\w*)\s*\((.*)\)')


def _close_paren(signature: str, open_paren: int) -> int:
    depth = 0
    for pos in range(open_paren, len(signature)):
        if signature[pos] == '(':
            depth += 1
        elif signature[pos] == ')':
            depth -= 1
            if depth == 0:
                return pos
    return -1


def _gather_signature(lines: list[str], index: int, initial: str) -> tuple[str, int, list[str]]:
    signature = initial
    consumed = [lines[index].strip()]
    balance = signature.count('(') - signature.count(')')
    while balance > 0 and index + 1 < len(lines):
        index += 1
        next_line = lines[index].strip()
        consumed.append(next_line)
        signature += ' ' + next_line
        balance += next_line.count('(') - next_line.count(')')
    return signature, index, consumed


def _members(type_name: str, body: str) -> dict[str, str]:
    out: dict[str, str] = {}
    lines = body.splitlines()
    depth = 0
    index = 0
    while index < len(lines):
        line = lines[index].strip()
        consumed = [line]
        if depth == 0 and line and not line.startswith(('//', '@', 'return ', 'if ', 'for ', 'while ', 'switch ', 'assert ')):
            candidate = MODIFIER.sub('', line)
            candidate = re.sub(r'^(?:factory|external)\s+', '', candidate)
            candidate = re.sub(r'^const\s+', '', candidate)
            constructor = re.match(
                rf'^{re.escape(type_name)}(?:\.([a-zA-Z_]\w*))?\s*\(', candidate
            )
            getter = GETTER.match(candidate)
            if constructor:
                signature, index, consumed = _gather_signature(lines, index, candidate)
                open_paren = signature.find('(')
                close_paren = _close_paren(signature, open_paren) if open_paren >= 0 else -1
                if open_paren >= 0 and close_paren > open_paren:
                    params = signature[open_paren + 1:close_paren]
                    name = constructor.group(1)
                    out[f'{type_name}.{name}' if name else f'{type_name}.new'] = (
                        f'({_normalize(params)})'
                    )
            elif getter:
                name = getter.group(2)
                if not name.startswith('_') and name not in {'hashCode', 'runtimeType'}:
                    out[f'{type_name}.{name}'] = _normalize(getter.group(1))
            elif '(' in candidate.split('=', 1)[0].split(';', 1)[0] and 'Function(' not in candidate:
                signature, index, consumed = _gather_signature(lines, index, candidate)
                open_paren = signature.find('(')
                close_paren = _close_paren(signature, open_paren) if open_paren >= 0 else -1
                if open_paren >= 0 and close_paren > open_paren:
                    head = signature[:open_paren].strip()
                    method = re.match(r'^(.+?)\s+([a-zA-Z_]\w*)$', head)
                    if method:
                        return_type, method_name = method.groups()
                        if method_name not in {'operator', 'Function'} and not method_name.startswith('_'):
                            params = signature[open_paren + 1:close_paren]
                            out[f'{type_name}.{method_name}'] = (
                                f'{_normalize(return_type)} ({_normalize(params)})'
                            )
            elif '=' in candidate or ';' in candidate:
                field = FIELD.match(candidate)
                if field:
                    field_type, field_name = field.group(1), field.group(2)
                    if field_name not in {'operator', 'Function'} and not field_name.startswith('_'):
                        out[f'{type_name}.{field_name}'] = _normalize(field_type)
        if (
            depth == 0
            and '=>' in line
            and not line.rstrip().endswith(';')
            and not consumed[-1].rstrip().endswith(';')
        ):
            while index + 1 < len(lines):
                index += 1
                next_line = lines[index].strip()
                consumed.append(next_line)
                if next_line.endswith(';'):
                    break
        for consumed_line in consumed:
            depth += consumed_line.count('{') - consumed_line.count('}')
        index += 1
    return out


def api_surface(package_dir: pathlib.Path) -> dict[str, str]:
    exported = exported_types(package_dir)
    out: dict[str, str] = {}
    for path in (package_dir / 'lib').rglob('*.dart'):
        text = strip_comments(path.read_text())
        for match in DECL.finditer(text):
            name = match.group(1)
            if name not in exported:
                continue
            kind = match.group(0).split()[0]
            if kind == 'typedef':
                end = text.find(';', match.start())
                if end >= 0:
                    out[name] = _normalize(text[match.start():end + 1])
                continue
            out[name] = kind
            body = _body(text, match.start())
            out.update(_members(name, body))
            if kind == 'enum':
                for value in ENUM_VALUE.finditer(body):
                    out[f'{name}.{value.group(1)}'] = 'enum'
    return out


def diff_api(baseline: dict[str, str], current: dict[str, str]) -> list[tuple[str, str, str | None]]:
    changes: list[tuple[str, str, str | None]] = []
    for key in sorted(baseline):
        old = baseline[key]
        new = current.get(key)
        if new is None:
            changes.append((key, old, None))
        elif old != new:
            changes.append((key, old, new))
    return changes


def _current_version_text(changelog: str) -> str:
    matches = list(re.finditer(r'(?m)^##\s+(\S+)', changelog))
    if not matches:
        return changelog
    match = next((m for m in matches if m.group(1).lower() != 'unreleased'), matches[0])
    following = [m for m in matches if m.start() > match.start()]
    end = following[0].start() if following else len(changelog)
    return changelog[match.start():end]


def _section(text: str, title: str) -> str:
    match = re.search(rf'(?m)^###\s+{re.escape(title)}\s*$', text)
    if not match:
        return ''
    rest = text[match.end():]
    next_match = re.search(r'(?m)^###\s+', rest)
    return rest[:next_match.start()] if next_match else rest


def check_notes(
    changes: list[tuple[str, str, str | None]],
    changelog: str,
    migration: str,
    current: dict[str, str] | None = None,
) -> list[str]:
    version_text = _current_version_text(changelog)
    breaking = _section(version_text, 'Breaking') + '\n' + _section(version_text, 'Removed')
    notes = breaking + '\n' + migration
    added = _section(version_text, 'Added') + '\n' + _section(version_text, 'Changed')
    errors: list[str] = []
    for key, old, new in changes:
        type_name = key.split('.', 1)[0]
        member = key.split('.', 1)[1] if '.' in key else ''
        type_exists = current is not None and type_name in current
        mentioned = key in notes or (member and member in notes)
        if not type_exists:
            # 整个类型被删除/改名：类型名出现在 Breaking/Removed 或 migration 即可。
            mentioned = mentioned or type_name in notes
        if key.endswith('.new') and type_name in notes:
            mentioned = True
        if mentioned:
            continue
        # 构造器新增可选参数是 additive：允许记在 Added/Changed；构造器删除仍要 Breaking。
        if key.endswith('.new') and new is not None and current is not None and key in current:
            if key in added or type_name in added:
                continue
        change = '删除' if new is None else f'{old} → {new}'
        errors.append(f'{key}（{change}）未出现在 CHANGELOG Breaking/Removed 或 migration')
    return errors


def latest_snapshot(paths: list[pathlib.Path]) -> pathlib.Path | None:
    def key(path: pathlib.Path) -> tuple[int, ...]:
        version = path.stem.rsplit('-', 1)[-1]
        return tuple(int(part) for part in version.split('.') if part.isdigit())

    return max(paths, key=key) if paths else None


def _snapshot_path(package: str) -> pathlib.Path | None:
    return latest_snapshot(list(SNAPSHOTS.glob(f'w_tools_{package}-*.txt')))


def _load_snapshot(path: pathlib.Path) -> dict[str, str]:
    out: dict[str, str] = {}
    for line in path.read_text().splitlines():
        if not line or line.startswith('#'):
            continue
        key, _, value = line.partition('\t')
        out[key] = value
    return out


def _write_snapshot(package_dir: pathlib.Path, package: str, version: str) -> pathlib.Path:
    SNAPSHOTS.mkdir(parents=True, exist_ok=True)
    path = SNAPSHOTS / f'w_tools_{package}-{version}.txt'
    surface = api_surface(package_dir)
    lines = [f'# w_tools_{package} {version}'] + [f'{k}\t{v}' for k, v in sorted(surface.items())]
    path.write_text('\n'.join(lines) + '\n')
    return path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--package', required=True, help='manifest 裸名，如 ui')
    parser.add_argument('--snapshot-from', help='从该包目录生成快照')
    parser.add_argument('--version', help='快照版本（与 --snapshot-from 一起用）')
    args = parser.parse_args()

    package_dir = ROOT / 'packages' / args.package
    if args.snapshot_from:
        if not args.version:
            print('--snapshot-from 需要 --version', file=sys.stderr)
            return 2
        path = _write_snapshot(pathlib.Path(args.snapshot_from), args.package, args.version)
        print(f'✓ 写入 API 快照 {path.relative_to(ROOT)}')
        return 0

    snapshot = _snapshot_path(args.package)
    if snapshot is None:
        print(f'! w_tools_{args.package} 没有 API 快照，跳过')
        return 0
    baseline = _load_snapshot(snapshot)
    current = api_surface(package_dir)
    changes = diff_api(baseline, current)
    if not changes:
        print(f'✓ {args.package} 公开 API 与 {snapshot.name} 一致')
        return 0

    changelog_path = package_dir / 'CHANGELOG.md'
    changelog = changelog_path.read_text() if changelog_path.exists() else ''
    pubspec = (package_dir / 'pubspec.yaml').read_text()
    major_match = re.search(r'(?m)^version:\s*(\d+)\.', pubspec)
    major = major_match.group(1) if major_match else '0'
    migration_path = ROOT / 'docs/migrations' / f'{args.package}-{major}.0.md'
    migration = migration_path.read_text() if migration_path.exists() else ''
    errors = check_notes(changes, changelog, migration, current)
    if errors:
        print(f'公开 API 变化未记录（{len(errors)} 条）：', file=sys.stderr)
        for error in errors:
            print(f'  ✗ {error}', file=sys.stderr)
        return 1
    print(f'✓ {args.package} 公开 API 变化均已记录（{len(changes)} 条）')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
