#!/usr/bin/env python3
"""检查发布物（tarball / pub cache）里的 Markdown 相对链接是否还能解析。

`check_docs.sh` 的「相对链接」只验证链接在**本地仓库**能解析；pub.dev 渲染
README / CHANGELOG 时会把相对链接改写成 repository 下的 GitHub URL，所以
pub.dev 页面通常没问题。真正会断的是**发布物本身**：根包 `.pubignore` 与
`scripts/publish_package.sh` 会排掉 `docs/` / `scripts/` / `packages/` 等目录，
读者打开 pub cache 里的 README / CHANGELOG 时，相对链接指向的文件不存在。

规则：
- 根包发布物里的 Markdown（`README.md` / `CHANGELOG.md` / `CONTRIBUTING.md` /
  `example/**/*.md`）：相对链接必须落在根包发布物内，且不指向 `.pubignore` /
  发布脚本排除的顶层路径；
- 每个 `packages/<pkg>` 的 Markdown：相对链接不得跳出该包目录，也不得指向包内
  会被发布脚本排除的 `test/`、`docs/`、`scripts/`、`build/` 等子目录；
- 指向本仓库的 GitHub 绝对 URL：路径必须在当前检出里存在（不校验外部 URL / 锚点）；
- 绝对 URL、`mailto:`、纯锚点之外的外部链接不检查。

发布物布局是 `.pubignore` 与 `scripts/publish_package.sh` 的共同结果；这里用显式
常量表达，避免让门禁去解析 shell 脚本。
"""
from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

# 根包发布物里不存在的顶层路径：.pubignore 的排除项 + 发布脚本删除的 packages/。
ROOT_EXCLUDED_DIRS = {
    'docs',
    'scripts',
    'packages',
    'test',
    '.github',
    '.w_tools',
    'coverage',
    'build',
    '.dart_tool',
    '.idea',
}
ROOT_EXCLUDED_FILES = {'AGENTS.md', 'devtools_options.yaml'}

# publish_package.sh 的 rsync 对每个包同样排掉这些目录。
PACKAGE_EXCLUDED_DIRS = {
    'test',
    'build',
    '.dart_tool',
    'coverage',
    '.idea',
    'docs',
    'scripts',
    '.github',
    '.w_tools',
}

# 根包会随发布物一起发出的 Markdown（不扫描 docs/ 这类被排除的目录）。
ROOT_MARKDOWN_FILES = ('README.md', 'CHANGELOG.md', 'CONTRIBUTING.md')

LINK = re.compile(r'!?\[[^\]]*\]\(([^)\s]+)\)')
ABSOLUTE = re.compile(r'^[a-zA-Z][a-zA-Z0-9+.-]*:')
REPO_URL = re.compile(
    r'https://github\.com/stone0533/w_tools/(?:blob|tree)/main/([A-Za-z0-9_./%\-]+)'
)

HINT = '在 tarball / pub cache 中不可用，请改用 GitHub 绝对 URL'


def relative_targets(readme: pathlib.Path):
    """逐行产出行号与相对链接目标（去掉锚点/查询串）。"""
    for number, line in enumerate(readme.read_text().splitlines(), start=1):
        for match in LINK.finditer(line):
            target = match.group(1).strip().strip('<>')
            if not target or target.startswith('#'):
                continue
            if ABSOLUTE.match(target):
                continue
            yield number, target.split('#', 1)[0].split('?', 1)[0]


def _relative_to_root(path: pathlib.Path, root: pathlib.Path) -> pathlib.PurePath | None:
    try:
        return path.resolve().relative_to(root.resolve())
    except ValueError:
        return None


def _root_markdown(root: pathlib.Path):
    for name in ROOT_MARKDOWN_FILES:
        path = root / name
        if path.is_file():
            yield path
    example = root / 'example'
    if example.is_dir():
        yield from sorted(example.rglob('*.md'))


def _package_markdown(root: pathlib.Path):
    """产出会随子包发布物发出的 Markdown。

    根 `.pubignore` 与发布脚本排掉的目录不参与扫描；`packages/cli/templates/`
    这类会一起发布的目录仍然要查。
    """
    for package_dir in sorted((root / 'packages').glob('*')):
        if not package_dir.is_dir():
            continue
        for path in sorted(package_dir.rglob('*.md')):
            relative = path.relative_to(package_dir)
            if any(part in PACKAGE_EXCLUDED_DIRS for part in relative.parts[:-1]):
                continue
            yield package_dir, path


def _is_excluded(relative: pathlib.PurePath, root: pathlib.Path) -> bool:
    first = relative.parts[0] if relative.parts else ''
    if first in ROOT_EXCLUDED_DIRS:
        return True
    return str(relative) in ROOT_EXCLUDED_FILES


def root_errors(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    for readme in _root_markdown(root):
        for number, target in relative_targets(readme):
            resolved = readme.parent / target
            relative = _relative_to_root(resolved, root)
            if relative is None:
                errors.append(
                    f'{readme.relative_to(root)}:{number}: 相对链接 {target} '
                    f'指向仓库外；{HINT}'
                )
                continue
            if _is_excluded(relative, root):
                errors.append(
                    f'{readme.relative_to(root)}:{number}: 相对链接 {target} '
                    f'指向不随根包发布的路径；{HINT}'
                )
    return errors


def package_errors(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    for package_dir, readme in _package_markdown(root):
        package_root = package_dir.resolve()
        for number, target in relative_targets(readme):
            resolved = (readme.parent / target).resolve()
            try:
                relative = resolved.relative_to(package_root)
            except ValueError:
                errors.append(
                    f'{readme.relative_to(root)}:{number}: 相对链接 {target} '
                    f'跳出包目录；{HINT} 或包内文件'
                )
                continue
            first = relative.parts[0] if relative.parts else ''
            if first in PACKAGE_EXCLUDED_DIRS:
                errors.append(
                    f'{readme.relative_to(root)}:{number}: 相对链接 {target} '
                    f'指向不随包发布的 {first}/；{HINT} 或包内文件'
                )
    return errors


def _published_markdown(root: pathlib.Path):
    yield from _root_markdown(root)
    for _, path in _package_markdown(root):
        yield path


def absolute_errors(root: pathlib.Path) -> list[str]:
    """本仓库 GitHub 绝对 URL 的路径必须存在（不校验外部 URL / 锚点）。"""
    errors: list[str] = []
    for readme in _published_markdown(root):
        for number, line in enumerate(readme.read_text().splitlines(), start=1):
            for match in REPO_URL.finditer(line):
                target = match.group(1).rstrip('/')
                if not (root / target).exists():
                    errors.append(
                        f'{readme.relative_to(root)}:{number}: 绝对链接路径不存在：'
                        f'{target}（请修正 URL）'
                    )
    return errors


def find_errors(root: pathlib.Path = ROOT) -> list[str]:
    return root_errors(root) + package_errors(root) + absolute_errors(root)


def main() -> int:
    errors = find_errors(ROOT)
    if errors:
        print('发布物 Markdown 相对链接不可用：', file=sys.stderr)
        for error in errors:
            print(f'  ✗ {error}', file=sys.stderr)
        return 1
    print('发布物 Markdown 相对链接检查通过')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
