#!/usr/bin/env python3
"""检查会随包发布的 example 能否独立解析。

为什么需要它：包内的 `example/` 会被 pub 一起发布，但 CI 的 example analyze/test
都在仓库里跑——`../packages/...` 这类 workspace 路径存在，所以看起来是绿的；
从 pub cache 里解包后这些路径不存在，`pub get` 直接失败。

规则（只检查会发布的 `example/pubspec.yaml`，不检查本地专用的
`example/pubspec_overrides.yaml`）：

1. `dependencies` / `dev_dependencies` 里的 `path:` 必须落在当前包目录内；
   跨越到兄弟包（如 `../../map`、`../packages/qr`）的路径不能留在发布物里。
2. `example/pubspec.yaml` 不得带 `dependency_overrides`；本地路径 override 放到
   `example/pubspec_overrides.yaml`，发布时由 `publish_package.sh` 排除。

用法：
    python3 scripts/check_example_paths.py

退出码：0 通过；1 有违规；2 参数 / 读取错误。
"""
from __future__ import annotations

import pathlib
import sys

import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEPENDENCY_SECTIONS = ('dependencies', 'dev_dependencies')


def example_dirs(root: pathlib.Path) -> list[tuple[pathlib.Path, pathlib.Path]]:
    """返回 (example 目录, 所属包根目录)。"""
    pairs: list[tuple[pathlib.Path, pathlib.Path]] = []
    root_example = root / 'example'
    if (root_example / 'pubspec.yaml').is_file():
        pairs.append((root_example, root))
    for package in sorted((root / 'packages').iterdir()):
        example = package / 'example'
        if (example / 'pubspec.yaml').is_file():
            pairs.append((example, package))
    return pairs


def _inside(target: pathlib.Path, package_root: pathlib.Path) -> bool:
    target = target.resolve()
    package_root = package_root.resolve()
    return target == package_root or package_root in target.parents


def example_errors(example: pathlib.Path, package_root: pathlib.Path) -> list[str]:
    """返回一个 example 的发布形态错误（相对路径，便于定位）。"""
    pubspec = example / 'pubspec.yaml'
    try:
        data = yaml.safe_load(pubspec.read_text()) or {}
    except (OSError, yaml.YAMLError) as error:
        return [f'{pubspec}: 读取失败（{error}）']
    if not isinstance(data, dict):
        return [f'{pubspec}: 不是 YAML 映射']

    errors: list[str] = []
    if 'dependency_overrides' in data:
        errors.append(
            f'{pubspec}: 发布物里不能带 dependency_overrides；'
            '本地路径覆盖请放到 example/pubspec_overrides.yaml（发布脚本会排除）',
        )

    for section in DEPENDENCY_SECTIONS:
        dependencies = data.get(section) or {}
        if not isinstance(dependencies, dict):
            continue
        for name, value in dependencies.items():
            if not isinstance(value, dict) or 'path' not in value:
                continue
            path = value['path']
            if not isinstance(path, str) or not path.strip():
                errors.append(f'{pubspec}: {section}.{name}.path 为空')
                continue
            target = (example / path).resolve()
            if not _inside(target, package_root):
                errors.append(
                    f'{pubspec}: {section}.{name} 指向包外路径 {path!r}'
                    f'（{target} 不在 {package_root.resolve()} 内）；'
                    '发布物里应为 hosted 约束 + pubspec_overrides.yaml',
                )
    return errors


def check(root: pathlib.Path = ROOT) -> list[str]:
    errors: list[str] = []
    for example, package_root in example_dirs(root):
        errors.extend(example_errors(example, package_root))
    return errors


def main() -> int:
    try:
        errors = check()
    except OSError as error:
        print(f'✗ 读取 example 目录失败：{error}', file=sys.stderr)
        return 2
    if errors:
        for error in errors:
            print(f'✗ {error}', file=sys.stderr)
        print(f'\n发布形态检查失败：{len(errors)} 项', file=sys.stderr)
        return 1
    print('发布形态检查通过（example 的 path 依赖都在包内，且没有 dependency_overrides）')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
