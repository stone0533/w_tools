#!/usr/bin/env python3
"""公开面预算：不让 async 7.0 之前的“每个派生状态一个 API”重新长回来。

对比 `packages/<pkg>` 当前公开 API 与**最新已发布快照**：

- patch：不允许新增 / 删除 / 修改公开 API（行为修复可以，接口不变）；
- minor：新增成员净增 <= 预算；新增公开类型必须登记 `exceptions`（带 ADR）；
  新增 enum value / sealed 子类型是 breaking addition，必须抬 major；
- major：同 minor，但允许删除；
- 版本没抬（pubspec == 快照）时出现公开 API 变化直接失败。

`cli` 没有 barrel，接口是命令 / catalog / 模板，`mode: tool` 跳过成员计数；
根包 `w_tools` 只重导出，不纳入本脚本（避免同一 API 重复计数）。

用法：
  python3 scripts/check_api_budget.py
  python3 scripts/check_api_budget.py --package async
"""
from __future__ import annotations

import argparse
import math
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

import yaml  # noqa: E402

from _dart_exports import exported_types, strip_comments  # noqa: E402

from check_public_api_diff import (  # noqa: E402
    SNAPSHOTS as _DEFAULT_SNAPSHOTS,
    _load_snapshot,
    _pubspec_version,
    api_surface,
    latest_snapshot,
    snapshot_version_of,
)

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONFIG = ROOT / 'scripts' / 'api_budget.yaml'
MANIFEST = ROOT / 'scripts' / 'packages.manifest'
SNAPSHOTS = _DEFAULT_SNAPSHOTS

VALID_MODES = {'library', 'tool'}


class BudgetConfigError(Exception):
    """配置 / manifest 本身有问题：不是某个包的预算超了。"""


def parse_version(text: str | None) -> tuple[int, int, int] | None:
    if not text:
        return None
    match = re.match(r'^(\d+)\.(\d+)\.(\d+)', text.strip())
    if not match:
        return None
    return tuple(int(part) for part in match.groups())  # type: ignore[return-value]


def release_kind(current: str | None, baseline: str | None) -> str:
    current_v = parse_version(current)
    baseline_v = parse_version(baseline)
    if current_v is None or baseline_v is None:
        return 'unknown'
    if current_v == baseline_v:
        return 'same'
    if current_v < baseline_v:
        return 'behind'
    if current_v[0] > baseline_v[0]:
        return 'major'
    if current_v[1] > baseline_v[1]:
        return 'minor'
    return 'patch'


def public_types(surface: dict[str, str]) -> set[str]:
    return {key for key in surface if '.' not in key}


def public_members(surface: dict[str, str]) -> set[str]:
    return {key for key in surface if '.' in key}


def surface_delta(baseline: dict[str, str], current: dict[str, str]) -> dict[str, list[str]]:
    baseline_types = public_types(baseline)
    current_types = public_types(current)
    baseline_members = public_members(baseline)
    current_members = public_members(current)
    return {
        'new_types': sorted(current_types - baseline_types),
        'removed_types': sorted(baseline_types - current_types),
        'new_members': sorted(current_members - baseline_members),
        'removed_members': sorted(baseline_members - current_members),
        'changed': sorted(
            key for key in baseline if key in current and baseline[key] != current[key]
        ),
    }


def new_enum_values(
    delta: dict[str, list[str]],
    baseline: dict[str, str],
    current: dict[str, str],
) -> list[str]:
    """已有 enum 新增 value：exhaustive switch 会编译失败，属于 breaking addition。

    新 enum 类型自己的 value 不算 breaking（没有既有 switch 覆盖它）。
    """
    values: list[str] = []
    for key in delta['new_members']:
        parent = key.split('.', 1)[0]
        if current.get(parent) == 'enum' and baseline.get(parent) == 'enum':
            values.append(key)
    return values


def _source_text(package_dir: pathlib.Path) -> str:
    return '\n'.join(
        strip_comments(path.read_text())
        for path in (package_dir / 'lib').rglob('*.dart')
    )


def exported_sealed_types(package_dir: pathlib.Path) -> set[str]:
    exported = set(exported_types(package_dir))
    sealed = set(
        re.findall(r'\bsealed\s+(?:class|mixin)\s+([A-Z]\w*)', _source_text(package_dir))
    )
    return sealed & exported


def new_sealed_subtypes(
    package_dir: pathlib.Path,
    baseline: dict[str, str],
    new_types: list[str],
) -> list[str]:
    """新增类型若继承 / 实现 / mixin 了**已存在**的导出 sealed 类型，属于 breaking。

    新 sealed 类型自己的新子类型不算 breaking（没有既有 switch 覆盖它）。
    解析器只看本包源码；跨包 sealed 基类不在这里识别（已知局限）。
    """
    sealed = exported_sealed_types(package_dir) & set(public_types(baseline))
    if not sealed or not new_types:
        return []
    text = _source_text(package_dir)
    out: list[str] = []
    for name in new_types:
        declaration = re.search(
            rf'\b(?:class|mixin|enum|extension|typedef)\s+{re.escape(name)}\b([^{{;]*)',
            text,
        )
        if not declaration:
            continue
        supers: set[str] = set()
        for clause in re.finditer(
            r'\b(?:extends|implements|with)\s+([^{{;]+)', declaration.group(1)
        ):
            segment = re.split(
                r'\b(?:extends|implements|with|on)\b', clause.group(1)
            )[0]
            for part in segment.split(','):
                candidate = part.strip().split('<', 1)[0].strip()
                if re.match(r'^[A-Z]\w*$', candidate):
                    supers.add(candidate)
        if supers & sealed:
            out.append(name)
    return out


def allowed_growth(entry: dict, defaults: dict, baseline_members: int) -> int:
    if 'growth' in entry:
        return int(entry['growth'])
    ratio = float(entry.get('growth_ratio', defaults.get('growth_ratio', 0.03)))
    low = int(entry.get('min_growth', defaults.get('min_growth', 3)))
    high = int(entry.get('max_growth', defaults.get('max_growth', 12)))
    return max(low, min(high, math.ceil(baseline_members * ratio)))


def load_config(path: pathlib.Path) -> dict:
    if not path.is_file():
        raise BudgetConfigError(
            f'缺少 {path.relative_to(ROOT) if path.is_absolute() and ROOT in path.parents else path}。'
            '预算门禁不能静默关闭；补上默认值 / 包清单，或从 git 恢复。'
        )
    try:
        data = yaml.safe_load(path.read_text()) or {}
    except yaml.YAMLError as error:
        raise BudgetConfigError(f'{path} 不是合法 YAML：{error}') from error
    if not isinstance(data, dict):
        raise BudgetConfigError(f'{path} 顶层必须是 mapping')
    defaults = data.get('defaults') or {}
    packages = data.get('packages') or {}
    exceptions = data.get('exceptions') or []
    if not isinstance(defaults, dict) or not isinstance(packages, dict):
        raise BudgetConfigError(f'{path} 的 defaults / packages 必须是 mapping')
    if not isinstance(exceptions, list):
        raise BudgetConfigError(f'{path} 的 exceptions 必须是 list')
    mode = defaults.get('mode', 'library')
    if mode not in VALID_MODES:
        raise BudgetConfigError(f'{path}: defaults.mode={mode!r} 不合法（{sorted(VALID_MODES)}）')
    for field in ('min_growth', 'max_growth'):
        if field not in defaults:
            continue
        try:
            value = int(defaults[field])
        except (TypeError, ValueError):
            raise BudgetConfigError(f'{path}: defaults.{field} 必须是整数') from None
        if value < 0:
            raise BudgetConfigError(f'{path}: defaults.{field} 不能为负')
    if 'growth_ratio' in defaults:
        try:
            if float(defaults['growth_ratio']) <= 0:
                raise ValueError
        except (TypeError, ValueError):
            raise BudgetConfigError(f'{path}: defaults.growth_ratio 必须是正数') from None
    if int(defaults.get('min_growth', 3)) > int(defaults.get('max_growth', 12)):
        raise BudgetConfigError(f'{path}: defaults.min_growth 不能大于 max_growth')
    for name, entry in packages.items():
        if entry is None:
            packages[name] = {}
            continue
        if not isinstance(entry, dict):
            raise BudgetConfigError(f'{path}: packages.{name} 必须是 mapping')
        entry_mode = entry.get('mode', mode)
        if entry_mode not in VALID_MODES:
            raise BudgetConfigError(f'{path}: packages.{name}.mode={entry_mode!r} 不合法')
        for field in ('growth', 'min_growth', 'max_growth'):
            if field not in entry:
                continue
            try:
                value = int(entry[field])
            except (TypeError, ValueError):
                raise BudgetConfigError(
                    f'{path}: packages.{name}.{field} 必须是整数'
                ) from None
            if value < 0:
                raise BudgetConfigError(
                    f'{path}: packages.{name}.{field} 不能为负'
                )
        if 'growth_ratio' in entry:
            try:
                if float(entry['growth_ratio']) <= 0:
                    raise ValueError
            except (TypeError, ValueError):
                raise BudgetConfigError(
                    f'{path}: packages.{name}.growth_ratio 必须是正数'
                ) from None
    for item in exceptions:
        if not isinstance(item, dict):
            raise BudgetConfigError(f'{path}: exceptions 的每一项必须是 mapping')
        for field in ('package', 'type', 'adr'):
            if not item.get(field):
                raise BudgetConfigError(f'{path}: exceptions 缺 {field}: {item!r}')
    return {'defaults': defaults, 'packages': packages, 'exceptions': exceptions}


def manifest_packages(path: pathlib.Path) -> list[str]:
    if not path.is_file():
        raise BudgetConfigError(f'缺少 {path}')
    names: list[str] = []
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        name = line.split('|', 1)[0].strip()
        if name:
            names.append(name.removeprefix('w_tools_'))
    if not names:
        raise BudgetConfigError(f'{path} 没有包条目')
    return names


def snapshot_path(package: str) -> pathlib.Path | None:
    return latest_snapshot(list(SNAPSHOTS.glob(f'w_tools_{package}-*.txt')))


def _exception_for(exceptions: list[dict], package: str, type_name: str) -> dict | None:
    return next(
        (
            item
            for item in exceptions
            if item.get('package') == package and item.get('type') == type_name
        ),
        None,
    )


def _validate_exception(item: dict, package: str, type_name: str, current_version: str) -> str | None:
    adr = str(item.get('adr', ''))
    if not adr:
        return f'{package}.{type_name}: 例外缺 adr'
    if not (ROOT / adr).is_file():
        return f'{package}.{type_name}: 例外指向的 ADR 不存在：{adr}'
    until = item.get('until')
    if until:
        until_v = parse_version(str(until))
        current_v = parse_version(current_version)
        if until_v is None:
            return f'{package}.{type_name}: until={until!r} 不是版本号'
        if current_v is not None and current_v > until_v:
            return f'{package}.{type_name}: 例外在 {until} 已到期（当前 {current_version}）'
    return None


def check_package(
    package: str,
    entry: dict,
    defaults: dict,
    exceptions: list[dict],
) -> tuple[list[str], list[str], str]:
    """返回 (errors, notes, summary)。"""
    mode = entry.get('mode', defaults.get('mode', 'library'))
    package_dir = ROOT / 'packages' / package
    if mode == 'tool':
        # tool 只能用于没有 barrel 的包；否则就是绕过成员预算的暗门。
        if package_dir.is_dir() and api_surface(package_dir):
            return [
                f'{package}: mode=tool 但解析到公开 barrel；请改为 mode=library，'
                '或确认这个包确实没有 Dart 公开 API'
            ], [], ''
        return [], [], f'- {package}: tool 包，跳过成员预算（CLI 面走人工评审）'
    snapshot = snapshot_path(package)
    if snapshot is None:
        return [], [], f'- {package}: 没有 API 快照，跳过（首发）'

    baseline = _load_snapshot(snapshot)
    current = api_surface(package_dir)
    if not current:
        return [f'{package}: 解析不到公开 API（lib/ 下缺 barrel）'], [], ''

    baseline_version = snapshot_version_of(snapshot)
    current_version = _pubspec_version(package_dir)
    kind = release_kind(current_version, baseline_version)
    if kind == 'unknown':
        return [f'{package}: 版本无法解析（本地 {current_version!r} / 快照 {baseline_version!r}）'], [], ''
    if kind == 'behind':
        return [
            f'{package}: 本地 {current_version} 低于最新快照 {baseline_version}；先同步 / 抬版本'
        ], [], ''

    delta = surface_delta(baseline, current)
    new_types = delta['new_types']
    new_members = delta['new_members']
    removed_members = delta['removed_members']
    removed_types = delta['removed_types']
    changed = delta['changed']
    net_members = len(new_members) - len(removed_members)

    errors: list[str] = []
    notes: list[str] = []

    if kind in {'patch', 'same'}:
        if new_types or removed_types or new_members or removed_members:
            reason = (
                '版本没抬（pubspec == 最新快照）'
                if kind == 'same'
                else 'patch 版本不允许新增 / 删除公开 API'
            )
            errors.append(f'{package}: {reason}')
            for key in new_types:
                errors.append(f'  + 类型 {key}')
            for key in removed_types:
                errors.append(f'  - 类型 {key}')
            for key in new_members:
                errors.append(f'  + {key}')
            for key in removed_members:
                errors.append(f'  - {key}')
        if changed:
            if kind == 'same':
                errors.append(
                    f'{package}: 版本没抬，但有 {len(changed)} 个签名 / 默认值变化；'
                    '公开 API 变化至少抬 minor'
                )
            else:
                errors.append(
                    f'{package}: patch 版本不允许公开 API 变化'
                    f'（{len(changed)} 个签名 / 默认值）'
                )
            for key in changed:
                errors.append(f'  ~ {key}')

    if kind == 'minor' and (removed_types or removed_members):
        errors.append(f'{package}: minor 不允许删除公开 API；删除 / 改名请抬 major')
        for key in removed_types:
            errors.append(f'  - 类型 {key}')
        for key in removed_members:
            errors.append(f'  - {key}')

    enum_values = new_enum_values(delta, baseline, current)
    sealed_subtypes = new_sealed_subtypes(package_dir, baseline, new_types)
    if kind == 'minor' and (enum_values or sealed_subtypes):
        errors.append(
            f'{package}: 新增 enum value / sealed 子类型是 breaking addition；'
            '请抬 major（exhaustive switch 会失败）'
        )
        for key in enum_values:
            errors.append(f'  + enum {key}')
        for key in sealed_subtypes:
            errors.append(f'  + sealed 子类型 {key}')

    if kind in {'minor', 'major'}:
        if changed:
            notes.append(
                f'{package}: {len(changed)} 个签名 / 默认值变化，'
                '逐条确认是否 breaking'
            )
        allowed = allowed_growth(entry, defaults, len(public_members(baseline)))
        if net_members > allowed:
            errors.append(
                f'{package}: 新增成员净增 {net_members} > 预算 {allowed}'
                f'（基线 {len(public_members(baseline))} 条，{kind}）'
            )
            for key in new_members:
                errors.append(f'  + {key}')
        elif new_members or removed_members:
            notes.append(f'{package}: 成员净增 {net_members:+d} / 预算 {allowed}')

        for type_name in new_types:
            exception = _exception_for(exceptions, package, type_name)
            if exception is None:
                errors.append(
                    f'{package}: 新增公开类型 {type_name} 未登记例外；'
                    '先写 ADR，再在 scripts/api_budget.yaml 的 exceptions 里指向它'
                )
                continue
            problem = _validate_exception(
                exception, package, type_name, current_version or ''
            )
            if problem:
                errors.append(problem)

    for item in exceptions:
        if item.get('package') != package:
            continue
        if item.get('type') not in new_types:
            notes.append(
                f'{package}: 例外 {item.get("type")} 已不是新增类型，'
                '可以删掉（类型进入快照后不应继续占用例外）'
            )

    if errors:
        summary = f'✗ {package}: {current_version}（基线 {baseline_version}，{kind}）'
    elif kind in {'patch', 'same'} and not new_members and not removed_members and not new_types and not removed_types:
        summary = f'✓ {package}: {current_version} 公开 API 未变'
    else:
        summary = (
            f'✓ {package}: {current_version}（基线 {baseline_version}，{kind}）'
            f' 类型 {len(new_types):+d} / 成员 {net_members:+d}'
        )
    return errors, notes, summary


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--package', help='只查一个包（短名，如 async）')
    args = parser.parse_args()

    try:
        config = load_config(CONFIG)
        packages = manifest_packages(MANIFEST)
    except BudgetConfigError as error:
        print(f'✗ {error}', file=sys.stderr)
        return 2

    configured = config['packages']
    missing = [name for name in packages if name not in configured]
    extra = sorted(set(configured) - set(packages))
    errors: list[str] = []
    if missing:
        errors.append(
            'scripts/api_budget.yaml 缺少 manifest 包：' + ', '.join(missing)
            + '（没有 barrel 的包写 mode: tool）'
        )
    if extra:
        errors.append('scripts/api_budget.yaml 有 manifest 之外的包：' + ', '.join(extra))

    selected = packages
    if args.package:
        wanted = args.package.removeprefix('w_tools_')
        if wanted not in packages:
            print(f'✗ --package {args.package} 不在 packages.manifest', file=sys.stderr)
            return 2
        selected = [wanted]

    if errors:
        for error in errors:
            print(f'✗ {error}', file=sys.stderr)
        return 2

    failed_packages: set[str] = set()
    for name in selected:
        package_errors, notes, summary = check_package(
            name,
            configured[name],
            config['defaults'],
            config['exceptions'],
        )
        if summary:
            print(summary)
        for note in notes:
            print(f'  ! {note}')
        for error in package_errors:
            if not error.startswith('  '):
                print(f'✗ {error}', file=sys.stderr)
                failed_packages.add(name)
            else:
                print(error, file=sys.stderr)

    if failed_packages:
        print(
            f'\n公开面预算失败：{len(failed_packages)} 个包。'
            '先做删除测试 / one-in-one-out；新增类型先写 ADR 并在 '
            'scripts/api_budget.yaml 登记例外。',
            file=sys.stderr,
        )
        return 1
    print(f'\n公开面预算通过（{len(selected)} 个包）')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
