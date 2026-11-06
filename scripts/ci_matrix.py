#!/usr/bin/env python3
"""CI 包矩阵的单一来源 + 门禁清单漂移检查。

CI 的包矩阵以前是手写的：`scripts/packages.manifest` 加了 app_getx / map_google 后
矩阵没同步，这两个包的测试只在本地跑。这里把矩阵改成从 manifest 生成，
并加一条检查挡住“再手抄一份”的回归。

用法：
    python3 scripts/ci_matrix.py --github-output   # 追加 include=[...] 到 $GITHUB_OUTPUT
    python3 scripts/ci_matrix.py --json            # 人读的 JSON
    python3 scripts/ci_matrix.py --check           # manifest ↔ 目录 ↔ CI 工作流 ↔ 根聚合约束一致性
"""
from __future__ import annotations

import json
import pathlib
import sys

root = pathlib.Path(__file__).resolve().parent.parent
manifest_path = root / 'scripts/packages.manifest'
ci_path = root / '.github/workflows/ci.yml'
RUNNERS = {'flutter', 'dart'}
EXPECTED_MATRIX_INCLUDE = '${{ fromJSON(needs.matrix.outputs.include) }}'


def read_manifest() -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for number, raw in enumerate(manifest_path.read_text().splitlines(), start=1):
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        fields = line.split('|')
        if len(fields) != 5:
            raise SystemExit(f'packages.manifest:{number}: 应有 5 列，实际 {len(fields)} 列')
        name, path, runner, aggregate, example = fields
        rows.append({
            'name': name,
            'path': path,
            'runner': runner,
            'aggregate': aggregate,
            'example': example,
            'line': str(number),
        })
    return rows


def matrix(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    return [{'package': row['path'].split('/')[-1], 'kind': row['runner']} for row in rows]


def check(rows: list[dict[str, str]]) -> list[str]:
    import yaml  # 只有 --check 需要；matrix job 只跑 --github-output，不依赖 PyYAML

    errors: list[str] = []
    listed: set[str] = set()

    for row in rows:
        directory = root / row['path']
        if not directory.is_dir():
            errors.append(f"packages.manifest:{row['line']}: 路径不存在 {row['path']}")
            continue
        listed.add(directory.name)
        expected = f'w_tools_{directory.name}'
        if row['name'] != expected:
            errors.append(
                f"packages.manifest:{row['line']}: 包名 {row['name']} 与目录不一致（应为 {expected}）",
            )
        if row['runner'] not in RUNNERS:
            errors.append(
                f"packages.manifest:{row['line']}: 未知 runner {row['runner']}（应为 flutter / dart）",
            )
        if row['aggregate'] not in ('root', '-'):
            errors.append(
                f"packages.manifest:{row['line']}: root_aggregate 应为 root / -，实际 {row['aggregate']}",
            )
        if row['example'] not in ('example', '-'):
            errors.append(
                f"packages.manifest:{row['line']}: example_test 应为 example / -，实际 {row['example']}",
            )

    # `root_aggregate` 必须与根 pubspec 的真实依赖一致，否则 release_check 会按错的清单校验。
    root_pubspec = yaml.safe_load((root / 'pubspec.yaml').read_text()) or {}
    aggregated_in_root = {
        str(name)
        for name in (root_pubspec.get('dependencies') or {})
        if str(name).startswith('w_tools_')
    }
    aggregated_in_manifest = {row['name'] for row in rows if row['aggregate'] == 'root'}
    for name in sorted(aggregated_in_manifest - aggregated_in_root):
        errors.append(
            f'packages.manifest: {name} 标记 root 聚合，但根 pubspec.yaml 没有依赖它',
        )
    for name in sorted(aggregated_in_root - aggregated_in_manifest):
        errors.append(
            f'root pubspec.yaml 依赖 {name}，但 packages.manifest 没有标记 root 聚合',
        )

    for directory in sorted((root / 'packages').iterdir()):
        if directory.is_dir() and directory.name not in listed:
            errors.append(f'packages/{directory.name}: 目录存在但不在 packages.manifest 里')

    workflow = yaml.safe_load(ci_path.read_text())
    jobs = workflow.get('jobs') or {}

    matrix_job = jobs.get('matrix') or {}
    outputs = matrix_job.get('outputs') or {}
    if 'include' not in outputs:
        errors.append('ci.yml: matrix job 必须输出 include（由 scripts/ci_matrix.py 生成）')

    packages_job = jobs.get('packages') or {}
    needs = packages_job.get('needs')
    if not (needs == 'matrix' or (isinstance(needs, list) and 'matrix' in needs)):
        errors.append('ci.yml: packages job 必须 needs matrix（矩阵从 manifest 生成）')
    if 'changes' not in jobs:
        errors.append('ci.yml: 缺少 changes job（纯文档改动不应跑重量级包矩阵）')
    strategy = (packages_job.get('strategy') or {}).get('matrix') or {}
    if strategy.get('include') != EXPECTED_MATRIX_INCLUDE:
        errors.append(
            'ci.yml: packages.strategy.matrix.include 必须是 '
            f'{EXPECTED_MATRIX_INCLUDE}，不要再手写包清单',
        )

    runs = '\n'.join(
        step.get('run', '')
        for job in jobs.values()
        for step in (job.get('steps') or [])
        if isinstance(step, dict)
    )
    if 'scripts/preflight.sh' not in runs:
        errors.append('ci.yml: 静态门禁必须调用 scripts/preflight.sh（不要再手抄检查步骤）')

    # 本地 fvm 与 CI 的 Flutter 版本必须同源，否则依赖解析会分叉。
    fvmrc_path = root / '.fvmrc'
    if not fvmrc_path.exists():
        errors.append('.fvmrc 缺失：在仓库根用 fvm use <version> 固定 Flutter 版本')
    else:
        try:
            pinned = json.loads(fvmrc_path.read_text()).get('flutter')
        except json.JSONDecodeError:
            pinned = None
            errors.append('.fvmrc 不是合法 JSON')
        ci_version = (workflow.get('env') or {}).get('FLUTTER_VERSION')
        if pinned and ci_version and str(pinned) != str(ci_version):
            errors.append(
                f'.fvmrc 固定 Flutter {pinned}，ci.yml 的 FLUTTER_VERSION 是 {ci_version}',
            )

    return errors


def main() -> int:
    args = sys.argv[1:]
    rows = read_manifest()

    if '--check' in args:
        errors = check(rows)
        if errors:
            for error in errors:
                print(f'✗ {error}', file=sys.stderr)
            print(f'\nCI / 包清单一致性检查失败：{len(errors)} 项', file=sys.stderr)
            return 1
        print(f'CI / 包清单一致性检查通过（{len(rows)} 个包）')
        return 0

    payload = json.dumps(matrix(rows), ensure_ascii=False)
    if '--github-output' in args:
        print(f'include={payload}')
    else:
        print(json.dumps({'include': matrix(rows)}, ensure_ascii=False, indent=2))
    return 0


if __name__ == '__main__':
    sys.exit(main())
