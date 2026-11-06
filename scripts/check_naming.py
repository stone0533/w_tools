#!/usr/bin/env python3
"""命名门禁：规则在 docs/naming.md，可放行的存量名字在 scripts/naming_baseline.yaml。

只做可判定的事：
1. 公开 `W*Config`（barrel 导出）必须在基线 configs 里，且基线不能有已不存在的行；
2. 库包公开类型必须以 `W` 开头，例外在基线 prefixes 里，同样双向检查；
3. Dart 文件名必须是 snake_case。

“公开”以 barrel 导出为准：`hide` 掉的迁移壳、只在 `lib/src` 里可见的实现不算公开，
不参与命名门禁。角色语义、成员命名、后缀是否用对仍靠 review（docs/naming.md §7）。
"""
from __future__ import annotations

import pathlib
import re
import sys

import yaml

root = pathlib.Path(__file__).resolve().parent.parent
BASELINE = root / 'scripts' / 'naming_baseline.yaml'

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from check_public_catalog import exported_types  # noqa: E402

# 工具包是给维护者用的 CLI / 设备工具，不是消费方 API，不套 W 前缀。
# 新增工具包时同步这里与 check_public_catalog.py 的 SKIP。
TOOL_PACKAGES = {'cli', 'figma', 'device', 'e2e'}

CONFIG = re.compile(r'W\w*Config')
DART_FILE = re.compile(r'[a-z0-9_]+(?:\.[a-z0-9_]+)*\.dart')


def load_baseline() -> tuple[dict[str, str], dict[str, str]]:
    if not BASELINE.exists():
        sys.exit('✗ 缺少 scripts/naming_baseline.yaml')
    try:
        data = yaml.safe_load(BASELINE.read_text(encoding='utf-8')) or {}
    except yaml.YAMLError as error:
        sys.exit(f'✗ scripts/naming_baseline.yaml 不是合法 YAML：{error}')
    if not isinstance(data, dict):
        sys.exit('✗ scripts/naming_baseline.yaml 顶层应为映射')
    configs = data.get('configs') or {}
    prefixes = data.get('prefixes') or {}
    keys = [*configs, *prefixes] if isinstance(configs, dict) and isinstance(prefixes, dict) else []
    if not isinstance(configs, dict) or not isinstance(prefixes, dict):
        sys.exit('✗ scripts/naming_baseline.yaml 的 configs / prefixes 应为「名字: 说明」映射')
    if not all(isinstance(key, str) for key in keys):
        sys.exit('✗ scripts/naming_baseline.yaml 的键必须是字符串')
    return configs, prefixes


configs, prefixes = load_baseline()
errors: list[str] = []

for name in sorted(configs):
    if not CONFIG.fullmatch(name):
        errors.append(f'scripts/naming_baseline.yaml: configs 里的 `{name}` 不是 W*Config')
for name in sorted(prefixes):
    if name.startswith('W'):
        errors.append(f'scripts/naming_baseline.yaml: prefixes 里的 `{name}` 不是无前缀类型')

found_configs: dict[str, str] = {}
found_non_w: dict[str, str] = {}
for package in sorted((root / 'packages').iterdir()):
    if not (package / 'lib').is_dir() or package.name in TOOL_PACKAGES:
        continue
    for name in exported_types(package):
        if CONFIG.fullmatch(name):
            found_configs[name] = package.name
        elif not name.startswith('W'):
            found_non_w[name] = package.name

for name, package in sorted(found_configs.items()):
    if name not in configs:
        errors.append(
            f'{package}: 公开 Config `{name}` 未在 scripts/naming_baseline.yaml 登记'
        )
for name in sorted(set(configs) - set(found_configs)):
    errors.append(
        f'scripts/naming_baseline.yaml: `{name}` 已不在公开 API 中（改名 / 删除后删行）'
    )
for name, package in sorted(found_non_w.items()):
    if name not in prefixes:
        errors.append(
            f'{package}: 公开类型 `{name}` 没有 W 前缀（确需保留就登记 prefixes）'
        )
for name in sorted(set(prefixes) - set(found_non_w)):
    errors.append(
        f'scripts/naming_baseline.yaml: prefixes 里的 `{name}` 已不在公开 API 中'
    )

for path in sorted((root / 'packages').rglob('*.dart')):
    if {'.dart_tool', 'build'} & set(path.parts):
        continue
    if not DART_FILE.fullmatch(path.name):
        errors.append(f'{path.relative_to(root)}: 文件名不是 snake_case')

if errors:
    print('命名检查失败（规则见 docs/naming.md）：', file=sys.stderr)
    for error in errors:
        print(f'  ✗ {error}', file=sys.stderr)
    print(
        '  新名字先按 docs/naming.md §3.3 选角色；例外是存量债务，只减不增。',
        file=sys.stderr,
    )
    sys.exit(1)

print(
    f'✓ 命名检查通过（{len(found_configs)} 个公开 Config、'
    f'{len(found_non_w)} 个前缀豁免、文件名 snake_case）'
)
