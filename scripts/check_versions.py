#!/usr/bin/env python3
"""校验版本约束的单一真相：根 pubspec 与 init 的 versions.dart 必须等于当前版本。

为什么需要它：一个版本号会同时出现在
- `packages/<pkg>/pubspec.yaml`（事实源）；
- 根 `pubspec.yaml` 的 `w_tools_<pkg>: ^x.y.z`（聚合层下界）；
- `packages/cli/lib/src/init/versions.dart` 的 `subpackageConstraints` / `cliConstraint`
  （`init` 写给消费方的 dev 约束）。

以前这些地方分别由 `release_check` 和 cli 测试覆盖，但 CLI 自己的 `cliConstraint`
两边都没有真正校验（测试硬编码了过期值），1.17.0 发布后一直停在 ^1.16.0。
这里统一检查，规则只有一个：**caret 下界必须等于当前 pubspec 版本**。

用法：
    python3 scripts/check_versions.py

退出码：0 通过；1 有漂移；2 读取失败。
"""
from __future__ import annotations

import pathlib
import re
import sys

import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent


def package_versions(root: pathlib.Path = ROOT) -> dict[str, str]:
    """从 packages.manifest + 各包 pubspec 读出当前版本。"""
    versions: dict[str, str] = {}
    manifest = (root / 'scripts' / 'packages.manifest').read_text()
    for raw in manifest.splitlines():
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        fields = line.split('|')
        if len(fields) != 5:
            raise ValueError(f'packages.manifest 行应有 5 列：{line}')
        name, path = fields[0], fields[1]
        pubspec = root / path / 'pubspec.yaml'
        data = yaml.safe_load(pubspec.read_text()) or {}
        version = data.get('version')
        if not isinstance(version, str) or not version:
            raise ValueError(f'{pubspec}: 缺 version')
        versions[name] = version
    return versions


def root_constraints(root: pathlib.Path = ROOT) -> dict[str, str]:
    data = yaml.safe_load((root / 'pubspec.yaml').read_text()) or {}
    dependencies = data.get('dependencies') or {}
    return {
        str(name): str(value)
        for name, value in dependencies.items()
        if str(name).startswith('w_tools_')
    }


def versions_dart_text(root: pathlib.Path = ROOT) -> str:
    return (root / 'packages' / 'cli' / 'lib' / 'src' / 'init' / 'versions.dart').read_text()


def dart_map(text: str) -> dict[str, str]:
    match = re.search(
        r'const\s+subpackageConstraints\s*=\s*<String,\s*String>\{(.*?)\};',
        text,
        re.S,
    )
    if not match:
        raise ValueError('versions.dart: 找不到 subpackageConstraints')
    return dict(re.findall(r"'([^']+)'\s*:\s*'([^']+)'", match.group(1)))


def dart_const(text: str, name: str) -> str | None:
    match = re.search(
        rf"const\s+(?:String\s+)?{re.escape(name)}\s*=\s*'([^']+)'",
        text,
    )
    return match.group(1) if match else None


def constraint_errors(root: pathlib.Path = ROOT) -> list[str]:
    versions = package_versions(root)
    constraints = root_constraints(root)
    text = versions_dart_text(root)
    map_constraints = dart_map(text)
    errors: list[str] = []

    aggregated = set()
    manifest = (root / 'scripts' / 'packages.manifest').read_text()
    for raw in manifest.splitlines():
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        fields = line.split('|')
        if len(fields) == 5 and fields[3] == 'root':
            aggregated.add(fields[0])

    for name in sorted(aggregated):
        expected = f'^{versions[name]}'
        actual = constraints.get(name)
        if actual is None:
            errors.append(f'根 pubspec.yaml 缺 {name}: {expected}')
        elif actual != expected:
            errors.append(f'根 pubspec.yaml: {name} 是 {actual}，应为 {expected}')
        if name not in map_constraints:
            errors.append(f'versions.dart 的 subpackageConstraints 缺 {name}（根包聚合的子包必须能被 init 引入）')

    for name, actual in sorted(map_constraints.items()):
        if name not in versions:
            errors.append(f'versions.dart: {name} 不在 packages.manifest 里')
            continue
        expected = f'^{versions[name]}'
        if actual != expected:
            errors.append(f'versions.dart: {name} 是 {actual}，应为 {expected}')

    for name, const_name in (
        ('w_tools_cli', 'cliConstraint'),
        ('w_tools_device', 'wToolsDeviceConstraint'),
    ):
        expected = f'^{versions[name]}'
        actual = dart_const(text, const_name)
        if actual is None:
            errors.append(f'versions.dart: 找不到 {const_name}')
        elif actual != expected:
            errors.append(f'versions.dart: {const_name} 是 {actual}，应为 {expected}')

    return errors


def main() -> int:
    try:
        errors = constraint_errors()
    except (OSError, ValueError, yaml.YAMLError) as error:
        print(f'✗ 读取版本约束失败：{error}', file=sys.stderr)
        return 2
    if errors:
        for error in errors:
            print(f'✗ {error}', file=sys.stderr)
        print(f'\n版本约束检查失败：{len(errors)} 项', file=sys.stderr)
        return 1
    print('版本约束检查通过（根 pubspec / versions.dart 下界都等于当前版本）')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
