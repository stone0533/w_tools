#!/usr/bin/env python3
"""检测「pub.dev 已发布归档」与仓库的**同版本内容漂移**。

`release_status.py` 只比版本号：仓库和线上都是 3.1.0，它显示「已发布」，
但归档里的 `lib/` 可能和仓库不一致（文档修复没发出去，或仓库有未发布改动）。
本脚本补这一层：版本相同时下载 `latest.archive_url`，解包后按白名单比对。

分级（这是重点）：
- **code drift**：去掉注释 / 空行后仍有差异（lib 代码、pubspec、LICENSE …）→ 必须抬版本；
  `--check` 时 exit 1。
- **docs drift**：只有 Markdown（README / CHANGELOG）差异 → 只警告，可留到下次功能版本。
- **comment drift**：只有 dartdoc / 注释 / 空行差异 → 只警告，不为一段注释单独发 patch。

只比对会随包发布的内容（`COMPARE_ROOTS`）；`test/` / `docs/` / `scripts/` 不参与。

用法：
    python3 scripts/check_publish_drift.py                 # 报告，不判失败
    python3 scripts/check_publish_drift.py --check         # code drift 时 exit 1
    python3 scripts/check_publish_drift.py --package toast # 只看一个包

退出码：0 无 code drift；1 有 code drift（仅 --check）；2 网络不可达 / 用法错误。
"""
from __future__ import annotations

import argparse
import io
import json
import pathlib
import re
import sys
import tarfile
import tempfile
import time
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
MANIFEST = ROOT / 'scripts' / 'packages.manifest'
PUB_API = 'https://pub.dev/api/packages/'
COMPARE_ROOTS = ('pubspec.yaml', 'README.md', 'CHANGELOG.md', 'LICENSE', 'lib', 'example')
ROOT_PACKAGE = 'w_tools'
# 与 scripts/publish_package.sh 的 rsync 排除项保持一致：这些内容不随包发布。
EXCLUDED_DIRS = {
    '.git', '.dart_tool', 'build', 'coverage', 'test', 'docs', 'scripts',
    '.github', '.w_tools', '.idea',
}
EXCLUDED_FILES = {
    'pubspec.lock',
    'pubspec_overrides.yaml',
    '.flutter-plugins',
    '.flutter-plugins-dependencies',
    '.DS_Store',
}


class PackageNotFound(Exception):
    def __init__(self, name: str) -> None:
        super().__init__(name)
        self.name = name


def strip_dart(text: str) -> str:
    """去掉 Dart 注释，保留字符串字面量（含字符串里的 `//` / `/* */`）。

    不做完美解析：只要对两侧文本施加**同一个**确定性变换，用于相等比较即可。
    拿不准时宁可判成 code drift（保守方向），也不放过真实代码差异。
    """
    out: list[str] = []
    i = 0
    n = len(text)
    while i < n:
        char = text[i]
        if char == '/' and i + 1 < n and text[i + 1] == '/':
            newline = text.find('\n', i)
            i = n if newline < 0 else newline
            continue
        if char == '/' and i + 1 < n and text[i + 1] == '*':
            end = text.find('*/', i + 2)
            i = n if end < 0 else end + 2
            continue
        if char in ('"', "'"):
            triple = text[i : i + 3] == char * 3
            if triple:
                end = text.find(char * 3, i + 3)
                j = n if end < 0 else end + 3
            else:
                j = i + 1
                while j < n:
                    if text[j] == '\\':
                        j += 2
                        continue
                    if text[j] == char:
                        j += 1
                        break
                    j += 1
            out.append(text[i:j])
            i = j
            continue
        out.append(char)
        i += 1
    return ''.join(out)


def _normalize_dart(text: str) -> str:
    lines = [line.rstrip() for line in strip_dart(text).splitlines()]
    return '\n'.join(line for line in lines if line)


def classify_file(rel: str, old: str, new: str) -> str | None:
    """返回 None / 'comment' / 'docs' / 'code'。

    - `comment`：dart 注释 / 空行差异，可延后；
    - `docs`：Markdown 文档差异（README / CHANGELOG），提醒但不强制发版；
    - `code`：其余差异（lib 代码、pubspec、LICENSE 等），必须抬版本。
    """
    if old == new:
        return None
    if rel.endswith('.dart') and _normalize_dart(old) == _normalize_dart(new):
        return 'comment'
    if rel.endswith('.md'):
        return 'docs'
    return 'code'


def normalize_pubspec(text: str) -> str:
    """按 publish_package.sh 的暂存规则归一化：去掉 `workspace:` 块与 `resolution: workspace`。

    发布出去的 pubspec 一定和仓库不同（这是有意的），不归一化会把每个包都判成漂移。
    """
    out: list[str] = []
    skipping = False
    for line in text.splitlines(keepends=True):
        if re.match(r'^workspace:\s*$', line):
            skipping = True
            continue
        if skipping:
            if re.match(r'^\s+-\s+', line):
                continue
            skipping = False
        out.append(line)
    normalized = ''.join(out)
    return re.sub(r'^resolution:\s*workspace\s*\n', '', normalized, flags=re.M)


def _excluded(rel: str) -> bool:
    parts = rel.split('/')
    if any(part in EXCLUDED_DIRS for part in parts[:-1]):
        return True
    return parts[-1] in EXCLUDED_FILES


def _files_under(root: pathlib.Path, roots: tuple[str, ...]) -> dict[str, pathlib.Path]:
    files: dict[str, pathlib.Path] = {}
    for entry in roots:
        path = root / entry
        if path.is_file():
            files[entry] = path
        elif path.is_dir():
            for file in path.rglob('*'):
                if not file.is_file():
                    continue
                rel = file.relative_to(root).as_posix()
                if _excluded(rel):
                    continue
                files[rel] = file
    return files


def compare_trees(
    old_root: pathlib.Path,
    new_root: pathlib.Path,
    roots: tuple[str, ...] = COMPARE_ROOTS,
) -> dict[str, str]:
    """比较两个目录树；返回 {相对路径: 'code' | 'comment'}。"""
    old_files = _files_under(old_root, roots)
    new_files = _files_under(new_root, roots)
    changes: dict[str, str] = {}
    for rel in sorted(set(old_files) | set(new_files)):
        old_path = old_files.get(rel)
        new_path = new_files.get(rel)
        if old_path is None or new_path is None:
            changes[rel] = 'code'
            continue
        old_bytes = old_path.read_bytes()
        new_bytes = new_path.read_bytes()
        if old_bytes == new_bytes:
            continue
        try:
            old_text = old_bytes.decode()
            new_text = new_bytes.decode()
        except UnicodeDecodeError:
            changes[rel] = 'code'
            continue
        if rel == 'pubspec.yaml':
            old_text = normalize_pubspec(old_text)
            new_text = normalize_pubspec(new_text)
        kind = classify_file(rel, old_text, new_text)
        if kind is not None:
            changes[rel] = kind
    return changes


def verdict(changes: dict[str, str]) -> str:
    kinds = set(changes.values())
    for candidate in ('code', 'docs', 'comment'):
        if candidate in kinds:
            return candidate
    return 'none'


def exit_code_for(changes: dict[str, str], *, check: bool) -> int:
    return 1 if check and verdict(changes) == 'code' else 0


def manifest_packages() -> list[tuple[str, pathlib.Path]]:
    packages: list[tuple[str, pathlib.Path]] = []
    for raw in MANIFEST.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        name, path = line.split('|')[:2]
        packages.append((name, ROOT / path))
    packages.append((ROOT_PACKAGE, ROOT))
    return packages


def fetch_latest(name: str) -> tuple[str, str]:
    last_error: Exception | None = None
    for attempt in range(2):
        try:
            with urllib.request.urlopen(PUB_API + name, timeout=8) as response:
                payload = json.load(response)
            latest = payload['latest']
            return latest['version'], latest['archive_url']
        except urllib.error.HTTPError as error:
            if error.code == 404:
                raise PackageNotFound(name) from error
            last_error = error
        except (urllib.error.URLError, TimeoutError, KeyError, json.JSONDecodeError, OSError) as error:
            last_error = error
        if attempt < 1:
            time.sleep(1)
    raise ConnectionError(f'{name}: {last_error}')


def local_version(package_dir: pathlib.Path) -> str | None:
    for line in (package_dir / 'pubspec.yaml').read_text().splitlines():
        if line.startswith('version:'):
            return line.split(':', 1)[1].strip()
    return None


def download_archive(url: str, target: pathlib.Path, attempts: int = 3) -> None:
    """下载并解包归档；storage 主机偶尔 EOF，重试后仍失败交给调用方降级。"""
    payload = b''
    last_error: Exception | None = None
    for attempt in range(attempts):
        try:
            with urllib.request.urlopen(url, timeout=60) as response:
                payload = response.read()
            break
        except (urllib.error.URLError, TimeoutError, OSError) as error:
            last_error = error
            if attempt + 1 < attempts:
                time.sleep(1)
    if not payload:
        raise ConnectionError(f'{url}: {last_error}')
    with tarfile.open(fileobj=io.BytesIO(payload)) as archive:
        archive.extractall(target)


def describe(changes: dict[str, str]) -> str:
    labels = {'code': 'code', 'docs': 'docs', 'comment': 'comment'}
    parts: list[str] = []
    for kind in ('code', 'docs', 'comment'):
        files = [rel for rel, value in changes.items() if value == kind]
        if files:
            parts.append(f'{labels[kind]}: ' + ', '.join(files))
    return '; '.join(parts)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--check', action='store_true', help='有 code drift 时返回 1')
    parser.add_argument('--package', help='只看一个包（裸名，如 toast；根包用 w_tools）')
    args = parser.parse_args(argv)

    wanted = args.package.removeprefix('w_tools_') if args.package else None
    packages = [
        (name, path)
        for name, path in manifest_packages()
        if wanted is None or name.removeprefix('w_tools_') == wanted
    ]
    if not packages:
        print(f'✗ 未知包：{args.package}（可选：packages.manifest 里的裸名或 w_tools）', file=sys.stderr)
        return 2

    failures = 0
    reported = 0
    compared = 0
    code_drift = False
    for name, package_dir in packages:
        version = local_version(package_dir)
        try:
            published, archive_url = fetch_latest(name)
        except PackageNotFound:
            print(f'{name}: 待首发（pub.dev 404），跳过')
            reported += 1
            continue
        except ConnectionError as error:
            print(f'{name}: 取 pub.dev 失败（{error}），跳过', file=sys.stderr)
            failures += 1
            continue
        reported += 1
        if version != published:
            print(f'{name}: 本地 {version} / 线上 {published}（版本不同，内容比对交给 release_status）')
            continue
        try:
            with tempfile.TemporaryDirectory() as temp:
                archive_root = pathlib.Path(temp)
                download_archive(archive_url, archive_root)
                changes = compare_trees(archive_root, package_dir)
        except (ConnectionError, tarfile.TarError) as error:
            print(f'{name}: 下载归档失败（{error}），跳过', file=sys.stderr)
            failures += 1
            continue
        compared += 1
        kind = verdict(changes)
        if kind == 'none':
            print(f'{name} {version}: 无漂移')
        elif kind == 'comment':
            print(f'{name} {version}: comment drift（仅注释/空行，可延后）→ {describe(changes)}')
        elif kind == 'docs':
            print(f'{name} {version}: docs drift（仅 Markdown，可延后）→ {describe(changes)}')
        else:
            code_drift = True
            print(f'{name} {version}: CODE DRIFT（必须抬版本）→ {describe(changes)}')

    if reported == 0:
        print('✗ 没有任何包可比对（网络不可达？）', file=sys.stderr)
        return 2
    if failures and compared == 0:
        print('✗ 全部包都取不到 pub.dev，按网络不可达处理', file=sys.stderr)
        return 2
    return 1 if args.check and code_drift else 0


if __name__ == '__main__':
    raise SystemExit(main())
