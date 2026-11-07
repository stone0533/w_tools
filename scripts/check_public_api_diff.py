#!/usr/bin/env python3
"""公开 API 快照 diff：删除 / 可空性 / 类型变化必须进 CHANGELOG Breaking 或 migration。

基线是**已发布版本**的公开 API（`scripts/api_snapshots/w_tools_<pkg>-<version>.txt`）；
缺基线直接失败，不再静默跳过——否则该包的门禁等于不存在。
CHANGELOG 段按 pubspec 的版本号选取，避免把新变更写进已经发布的历史段。

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

# 没有 barrel 的包：公开 API 门禁对它不适用。`w_tools_cli` 是可执行工具（入口在 bin/），
# lib/ 下只有 src/，没有 w_tools_cli.dart。显式登记后打印「不适用」并跳过 ——
# 空 surface 绝不能当成「与快照一致」的 ✓（否则这个包的门禁等于不存在）。
NO_PUBLIC_API = {'cli'}

# `w_tools_<pkg>-<version>.txt`；版本允许预发布后缀（`8.0.0-dev.1`）。
# 不能用 `stem.rsplit('-', 1)`：`-dev.1` 会被截成 `1`，新基线永远不会被当成最新。
SNAPSHOT_NAME = re.compile(
    r'^w_tools_(?P<package>.+?)-(?P<version>\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?)\.txt$'
)


def snapshot_version_of(path: pathlib.Path) -> str:
    """从快照文件名取版本号；不符合命名时退回旧的 rsplit 行为。"""
    match = SNAPSHOT_NAME.match(path.name)
    if match:
        return match.group('version')
    return path.stem.rsplit('-', 1)[-1]


DECL = re.compile(r'\b(?:class|enum|mixin|extension|typedef)\s+([A-Z][A-Za-z0-9_]*)')
FIELD = re.compile(r'^(.+?)\s+([a-zA-Z]\w*)\s*(?:=|;|$)')
GETTER = re.compile(r'^([A-Za-z_][\w<>,?. ]*?)\s+get\s+([a-zA-Z]\w*)')
MODIFIER = re.compile(r'^(?:static\s+)?(?:final|const|late\s+final)\s+')
ENUM_VALUE = re.compile(r'^\s*([A-Za-z]\w*)\s*(?:,|;|$)', re.M)
# 解析私有 getter 时，行尾的 `: null;` 曾被 FIELD 正则误当成成员名；
# 这些是 Dart 保留字，不可能是真实成员名，统一排除（含旧快照的 `.null` 伪条目）。
RESERVED_MEMBER_NAMES = {'null', 'true', 'false', 'this', 'super'}


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
                    if (
                        field_name not in {'operator', 'Function'}
                        and field_name not in RESERVED_MEMBER_NAMES
                        and not field_name.startswith('_')
                    ):
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
        # 旧基线（5.1.1 等）里可能有 `X.null` 这类解析伪成员，忽略它们，
        # 否则删掉一个私有 getter 会被判成公开 API 删除。
        if key.rsplit('.', 1)[-1] in RESERVED_MEMBER_NAMES:
            continue
        old = baseline[key]
        new = current.get(key)
        if new is None:
            changes.append((key, old, None))
        elif old != new:
            changes.append((key, old, new))
    return changes


def _current_version_text(changelog: str, version: str | None = None) -> str:
    """取“本次变更”所在的 CHANGELOG 段。

    优先精确匹配 pubspec 的版本号；没有时退到 `## Unreleased`；再退到第一段。
    不能只取“第一个非 Unreleased 段”：版本没抬时那段是**已发布**的历史，
    把新变更写进去会让仓库与 pub.dev 上的旧版本说明分叉。
    """
    matches = list(re.finditer(r'(?m)^##\s+(\S+)', changelog))
    if not matches:
        return changelog
    match = None
    if version:
        match = next((m for m in matches if m.group(1) == version), None)
    if match is None:
        match = next((m for m in matches if m.group(1).lower() == 'unreleased'), matches[0])
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
    version: str | None = None,
    allow_migration: bool = True,
) -> list[str]:
    version_text = _current_version_text(changelog, version)
    breaking = _section(version_text, 'Breaking') + '\n' + _section(version_text, 'Removed')
    notes = breaking + '\n' + (migration if allow_migration else '')
    added = _section(version_text, 'Added') + '\n' + _section(version_text, 'Changed')
    errors: list[str] = []
    for key, old, new in changes:
        type_name = key.split('.', 1)[0]
        type_exists = current is not None and type_name in current
        # 只认完整成员名（`WButton.color`）：裸成员名 `color` / `text` 这类
        # 几乎必然出现在迁移文档的普通句子里，会变成免检通道。
        mentioned = key in notes
        if not type_exists:
            # 整个类型被删除/改名：类型名出现在 Breaking/Removed 或 migration 即可。
            mentioned = mentioned or type_name in notes
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
        version = snapshot_version_of(path)
        return tuple(int(part) for part in version.split('.') if part.isdigit())

    return max(paths, key=key) if paths else None


def _snapshot_path(package: str) -> pathlib.Path | None:
    return latest_snapshot(list(SNAPSHOTS.glob(f'w_tools_{package}-*.txt')))


def latest_snapshot_version(package: str) -> str | None:
    """最新基线对应的版本号（没有基线时返回 None）。"""
    path = _snapshot_path(package)
    return snapshot_version_of(path) if path is not None else None


def _load_snapshot(path: pathlib.Path) -> dict[str, str]:
    out: dict[str, str] = {}
    for line in path.read_text().splitlines():
        if not line or line.startswith('#'):
            continue
        key, _, value = line.partition('\t')
        out[key] = value
    return out


def _write_snapshot(
    package_dir: pathlib.Path,
    package: str,
    version: str,
    output_dir: pathlib.Path | None = None,
) -> pathlib.Path:
    target = output_dir or SNAPSHOTS
    target.mkdir(parents=True, exist_ok=True)
    path = target / f'w_tools_{package}-{version}.txt'
    surface = api_surface(package_dir)
    lines = [f'# w_tools_{package} {version}'] + [f'{k}\t{v}' for k, v in sorted(surface.items())]
    path.write_text('\n'.join(lines) + '\n')
    return path


def _pubspec_version(package_dir: pathlib.Path) -> str:
    pubspec = (package_dir / 'pubspec.yaml').read_text()
    match = re.search(r'(?m)^version:\s*(\S+)', pubspec)
    return match.group(1) if match else ''


def _major(version: str | None) -> int | None:
    if not version:
        return None
    match = re.match(r'(\d+)', version)
    return int(match.group(1)) if match else None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--package', required=True, help='manifest 裸名，如 ui')
    parser.add_argument('--snapshot-from', help='从该包目录生成快照')
    parser.add_argument('--version', help='快照版本（与 --snapshot-from 一起用）')
    parser.add_argument(
        '--output-dir',
        help='快照写入目录（默认 scripts/api_snapshots）；发布脚本用它写 .w_tools/release-snapshots',
    )
    parser.add_argument(
        '--latest-snapshot',
        action='store_true',
        help='只打印该包最新 API 快照版本（没有则打印空行）；发布脚本的基线守卫用',
    )
    args = parser.parse_args()

    if args.latest_snapshot:
        print(latest_snapshot_version(args.package) or '')
        return 0

    package_dir = ROOT / 'packages' / args.package
    if args.snapshot_from:
        if not args.version:
            print('--snapshot-from 需要 --version', file=sys.stderr)
            return 2
        source = pathlib.Path(args.snapshot_from)
        if not (source / 'pubspec.yaml').is_file():
            print(
                f'✗ {source} 不像包目录（缺 pubspec.yaml）：拒绝写快照。'
                '请指向解包后的归档 / 包目录本身',
                file=sys.stderr,
            )
            return 2
        source_version = _pubspec_version(source)
        if source_version and source_version != args.version:
            print(
                f'✗ --version {args.version} 与来源 {source} 的 pubspec 版本 '
                f'{source_version} 不一致；快照版本必须等于来源版本',
                file=sys.stderr,
            )
            return 2
        surface = api_surface(source)
        if not surface and args.package not in NO_PUBLIC_API:
            # 空基线会让这个包的公开 API 门禁永久空转（diff_api({}, current) 恒为 []）。
            print(
                f'✗ {source} 解析不到任何公开 API（缺 lib/w_tools_*.dart barrel）：'
                '拒绝写空基线',
                file=sys.stderr,
            )
            return 1
        output_dir = pathlib.Path(args.output_dir) if args.output_dir else None
        path = _write_snapshot(
            source, args.package, args.version, output_dir
        )
        try:
            shown = path.relative_to(ROOT)
        except ValueError:
            shown = path
        print(f'✓ 写入 API 快照 {shown}')
        return 0

    snapshot = _snapshot_path(args.package)
    if snapshot is None:
        # 不能静默跳过：缺基线时这个门禁对整包失效，而外部看到的是 ✓。
        print(
            f'✗ w_tools_{args.package} 没有 API 快照，公开 API 变更无法校验。\n'
            f'  基线必须来自**已发布**版本：解包 pub.dev 归档后运行\n'
            f'  python3 scripts/check_public_api_diff.py --snapshot-from <解包目录> '
            f'--package {args.package} --version <已发布版本>',
            file=sys.stderr,
        )
        return 1
    baseline = _load_snapshot(snapshot)
    if not baseline and args.package not in NO_PUBLIC_API:
        # 0 字节 / 只有 header 的基线会让 diff_api({}, current) 恒为 []：门禁永久空转。
        print(
            f'✗ w_tools_{args.package} 的 API 快照 {snapshot.name} 是空的：'
            '空基线会让公开 API 门禁永久空转。请从 pub.dev 归档重新生成：\n'
            f'  python3 scripts/check_public_api_diff.py --snapshot-from <解包目录> '
            f'--package {args.package} --version <已发布版本>',
            file=sys.stderr,
        )
        return 1
    current = api_surface(package_dir)
    if not current:
        if args.package in NO_PUBLIC_API:
            print(
                f'! {args.package}: 没有 barrel 公开 API（已登记为不适用），'
                '跳过快照比对（不是 ✓）',
            )
            return 0
        print(
            f'✗ w_tools_{args.package} 解析不到任何公开 API：lib/ 下缺 w_tools_*.dart barrel，'
            '这个包的门禁会空转。补 barrel，或在 check_public_api_diff.NO_PUBLIC_API 里显式登记。',
            file=sys.stderr,
        )
        return 1
    changes = diff_api(baseline, current)
    if not changes:
        print(f'✓ {args.package} 公开 API 与 {snapshot.name} 一致')
        return 0

    changelog_path = package_dir / 'CHANGELOG.md'
    changelog = changelog_path.read_text() if changelog_path.exists() else ''
    version = _pubspec_version(package_dir)
    major = _major(version)
    migration_path = (
        ROOT / 'docs/migrations' / f'{args.package}-{major if major is not None else 0}.0.md'
    )
    migration = migration_path.read_text() if migration_path.exists() else ''
    # 旧 major 的迁移文档不能给当前 major 的破坏性变更背书：只有跨 major 时才计入。
    published_major = _major(latest_snapshot_version(args.package))
    allow_migration = (
        major is not None and published_major is not None and major > published_major
    )
    errors = check_notes(
        changes, changelog, migration, current, version or None, allow_migration
    )
    if errors:
        print(f'公开 API 变化未记录（{len(errors)} 条）：', file=sys.stderr)
        for error in errors:
            print(f'  ✗ {error}', file=sys.stderr)
        print(
            f'  应写进 packages/{args.package}/CHANGELOG.md 的 '
            f'"## {version}" 的 ### Breaking / ### Removed，或 docs/migrations/。',
            file=sys.stderr,
        )
        return 1
    print(f'✓ {args.package} 公开 API 变化均已记录（{len(changes)} 条）')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
