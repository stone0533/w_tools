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
EXPECTED_QUANTIFIER = 'some-with-excludes'

# 这些正向规则决定「哪些改动会触发重量级 job」。少一条就可能让整类改动静默跳过门禁，
# 所以把它们列成必须存在的清单；有意改过滤器时同步改这里（同源守卫）。
REQUIRED_FILTERS = {
    'code': [
        'packages/**/*.dart',
        'packages/**/pubspec.yaml',
        # 测试资产 / 输出契约 / 发布白名单：只改它们也要跑包测试与 dry-run。
        'packages/**/test/**',
        'packages/**/schema/**',
        'packages/**/*.json',
        'packages/**/.pubignore',
        'packages/cli/templates/**',
        'packages/cli/catalog/**',
        'lib/**',
        'test/**',
        'pubspec.yaml',
        '.pubignore',
        '.github/workflows/ci.yml',
    ],
    'static': [
        'scripts/**/*.sh',
        'scripts/**/*.py',
        'scripts/packages.manifest',
        'scripts/tests/**',
        'docs/feedback/**',
        'docs/modules/components.md',
        '.fvmrc',
    ],
}

# required 必须等这些 job；任何一项从 needs 里掉了，分支保护就可能提前放行。
REQUIRED_JOBS = ('matrix', 'changes', 'docs', 'umbrella', 'api-bump', 'min_sdk', 'packages')

# 这些 job 按路径门控，if 必须仍然引用 code / static；否则会被无条件 skip。
GATED_JOB_CONDITIONS = {
    'umbrella': ('needs.changes.outputs.code', 'needs.changes.outputs.static'),
    'min_sdk': ('needs.changes.outputs.code',),
    'packages': ('needs.changes.outputs.code',),
}

# docs job 每次 PR 都跑；把 meta 检查放这里，避免「过滤器坏了 → umbrella skip → 自检也不跑」。
DOCS_JOB_COMMANDS = (
    'scripts/check_docs.sh',
    'scripts/release_check.sh',
    'scripts/ci_matrix.py --check',
    'scripts/check_gate_coverage.py',
)


def filter_config(workflow: dict) -> dict:
    steps = (((workflow.get('jobs') or {}).get('changes') or {}).get('steps') or [])
    for step in steps:
        if isinstance(step, dict) and step.get('id') == 'filter':
            return step.get('with') or {}
    return {}


def filter_patterns(workflow: dict) -> dict[str, list[str]]:
    """把 `filters:` 文本解析成 {group: [pattern]}。"""
    text = str(filter_config(workflow).get('filters') or '')
    groups: dict[str, list[str]] = {}
    current = ''
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        if line.endswith(':') and not line.startswith('-'):
            current = line[:-1].strip()
            groups.setdefault(current, [])
            continue
        if line.startswith('- ') and current:
            groups[current].append(line[2:].strip().strip("'\""))
    return groups


def required_filter_errors(workflow: dict) -> list[str]:
    """过滤器必须包含关键正向规则，并且 quantifier 必须是 some-with-excludes。"""
    config = filter_config(workflow)
    if not config:
        return []  # 缺 filter 由 path_filter_errors 报，避免重复
    errors: list[str] = []
    quantifier = config.get('predicate-quantifier')
    if quantifier != EXPECTED_QUANTIFIER:
        errors.append(
            f'ci.yml: changes filter 的 predicate-quantifier 是 {quantifier!r}，'
            f'必须是 {EXPECTED_QUANTIFIER!r}（否则 `!` 排除会吞掉正向规则）'
        )
    groups = filter_patterns(workflow)
    for group, required in REQUIRED_FILTERS.items():
        missing = [pattern for pattern in required if pattern not in groups.get(group, [])]
        if missing:
            errors.append(
                f'ci.yml: {group} 过滤器缺少关键正向规则：{", ".join(missing)}；'
                '删除会让对应改动静默跳过重量级 job'
            )
    return errors


def required_job_errors(workflow: dict) -> list[str]:
    """required 聚合 job 与各门控 job 的接线不能被静默削弱。"""
    jobs = workflow.get('jobs') or {}
    required = jobs.get('required') or {}
    needs = required.get('needs')
    if isinstance(needs, str):
        needs = [needs]
    need_set = set(needs or [])
    errors: list[str] = []
    missing = [name for name in REQUIRED_JOBS if name not in need_set]
    if missing:
        errors.append(
            f'ci.yml: required.needs 缺少 {", ".join(missing)}；'
            '分支保护可能在这些 job 完成前就通过'
        )

    for job, needles in GATED_JOB_CONDITIONS.items():
        condition = str((jobs.get(job) or {}).get('if') or '')
        for needle in needles:
            if needle not in condition:
                errors.append(
                    f'ci.yml: {job}.if 不再引用 {needle}；'
                    '路径过滤失效时这个 job 会被无条件 skip'
                )

    docs_steps = (jobs.get('docs') or {}).get('steps') or []
    docs_commands = '\n'.join(
        line
        for step in docs_steps
        if isinstance(step, dict)
        for line in str(step.get('run') or '').splitlines()
        if not line.lstrip().startswith('#')
    )
    for command in DOCS_JOB_COMMANDS:
        if command not in docs_commands:
            errors.append(
                f'ci.yml: docs job 必须运行 `{command}`；'
                '它每次 PR 都跑，是过滤器/门禁接线失效时的兜底'
            )
    return errors


EXPECTED_CHANGES_OUTPUTS = {
    'code': "${{ steps.filter.outputs.code || 'true' }}",
    'static': "${{ steps.filter.outputs.static || 'true' }}",
}
EXPECTED_GATED_IFS = {
    'umbrella': "needs.changes.outputs.code == 'true' || needs.changes.outputs.static == 'true'",
    'min_sdk': "needs.changes.outputs.code == 'true'",
    'packages': "needs.changes.outputs.code == 'true'",
    # api-bump 在 push main 时允许 skipped；改错 / 改成 false 时 PR 上的
    # check_version_bump / check_pr_scope 会静默消失。
    'api-bump': "github.event_name == 'pull_request'",
}
PR_TEMPLATE = root / '.github/PULL_REQUEST_TEMPLATE.md'
RELEASE_STATUS_WORKFLOW = root / '.github/workflows/release-status.yml'
REQUIRED_CHECK_NAME = 'Required checks'

# packages 的 analyze / test 步骤有合法的 matrix 条件；把这些条件也钉死，
# 避免 `if: false` / `&& false` 把某个包类型的测试静默关掉。
EXPECTED_PACKAGE_STEP_IFS = {
    'Analyze (Flutter package)': "matrix.kind == 'flutter'",
    'Analyze (pure Dart package)': "matrix.kind == 'dart'",
    'Compile generated UI templates': "matrix.package == 'cli'",
    'Analyze example (published with package)': (
        "matrix.kind == 'flutter' && hashFiles(format('packages/{0}/example/pubspec.yaml', "
        "matrix.package)) != ''"
    ),
    'Test example (if present)': (
        "matrix.kind == 'flutter' && hashFiles(format('packages/{0}/example/test/**', "
        "matrix.package)) != ''"
    ),
    'Test (Flutter package)': "matrix.kind == 'flutter'",
    'Test (pure Dart package)': "matrix.kind == 'dart'",
}


def _normalized(value: object) -> str:
    return ' '.join(str(value or '').split())


def wiring_errors(workflow: dict) -> list[str]:
    """outputs / 门控 if / required 判定必须是精确的那几句，而不是「包含某个子串」。"""
    jobs = workflow.get('jobs') or {}
    errors: list[str] = []

    outputs = (jobs.get('changes') or {}).get('outputs') or {}
    for key, expected in EXPECTED_CHANGES_OUTPUTS.items():
        actual = _normalized(outputs.get(key))
        if actual != expected:
            errors.append(
                f'ci.yml: changes.outputs.{key} 是 {actual!r}，必须是 {expected!r}；'
                '改错会让门控 job 被静默 skip'
            )

    for job, expected in EXPECTED_GATED_IFS.items():
        actual = _normalized((jobs.get(job) or {}).get('if'))
        if actual != expected:
            errors.append(
                f'ci.yml: {job}.if 是 {actual!r}，必须是 {expected!r}；'
                '子串匹配挡不住 `&& false` / `!= true`'
            )

    required = jobs.get('required') or {}
    if _normalized(required.get('if')) != 'always()':
        errors.append(
            'ci.yml: required.if 必须是 always()；'
            '否则依赖失败时 Required checks 可能被 skip'
        )
    if _normalized(required.get('name')) != REQUIRED_CHECK_NAME:
        errors.append(
            f'ci.yml: required.name 必须是 {REQUIRED_CHECK_NAME!r}；'
            '改名后所有 PR 会永久 pending'
        )
    run_text = '\n'.join(
        str(step.get('run') or '')
        for step in required.get('steps') or []
        if isinstance(step, dict)
    )
    for job in REQUIRED_JOBS:
        if f'needs.{job}.result' not in run_text:
            errors.append(
                f'ci.yml: required 的判定没有读取 needs.{job}.result；'
                '掏空判定脚本会让全部门禁失效'
            )
    if 'exit 1' not in run_text:
        errors.append('ci.yml: required 的判定没有失败分支（exit 1）')
    return errors


UNCONDITIONAL_GATE_JOBS = ('required', 'min_sdk', 'umbrella', 'api-bump', 'docs')
CONDITIONAL_GATE_STEPS = (
    ('matrix', 'ci_matrix.py --github-output'),
    ('packages', 'publish_package.sh'),
)


def _gate_step_errors(job: str, step: dict) -> list[str]:
    errors: list[str] = []
    if 'if' in step:
        errors.append(
            f'ci.yml: {job} 的门禁步骤带了 if（{step.get("if")}）：'
            '条件不满足时门禁会静默跳过'
        )
    if step.get('continue-on-error'):
        errors.append(
            f'ci.yml: {job} 的门禁步骤开了 continue-on-error：失败会被吞掉'
        )
    return errors


def gate_step_errors(workflow: dict) -> list[str]:
    """门禁步骤不能被 `if: false` / `continue-on-error` 静默关掉。

    覆盖 required / min_sdk / umbrella / api-bump / docs 的全部步骤，以及
    matrix 的 emit、packages 的 publish dry-run。`packages` 的 analyze / test
    有合法的 `matrix.*` 条件，不在这里一刀切。
    """
    jobs = workflow.get('jobs') or {}
    errors: list[str] = []
    for job in UNCONDITIONAL_GATE_JOBS:
        for step in jobs.get(job, {}).get('steps') or []:
            if isinstance(step, dict):
                errors.extend(_gate_step_errors(job, step))
    for job, needle in CONDITIONAL_GATE_STEPS:
        for step in jobs.get(job, {}).get('steps') or []:
            if isinstance(step, dict) and needle in str(step.get('run') or ''):
                errors.extend(_gate_step_errors(job, step))
    return errors


def package_step_errors(workflow: dict) -> list[str]:
    """packages 的 analyze / test 步骤必须保留原来的 matrix 条件。"""
    jobs = workflow.get('jobs') or {}
    errors: list[str] = []
    for step in (jobs.get('packages') or {}).get('steps') or []:
        if not isinstance(step, dict):
            continue
        name = str(step.get('name') or '')
        expected = EXPECTED_PACKAGE_STEP_IFS.get(name)
        if expected is None:
            continue
        actual = _normalized(step.get('if'))
        if actual != expected:
            errors.append(
                f'ci.yml: packages 的「{name}」if 是 {actual!r}，必须是 {expected!r}；'
                '改错会让该包类型的测试静默跳过'
            )
        if step.get('continue-on-error'):
            errors.append(
                f'ci.yml: packages 的「{name}」开了 continue-on-error：失败会被吞掉'
            )
    return errors


def matrix_emit_errors(workflow: dict) -> list[str]:
    """矩阵必须真的由 ci_matrix.py 生成，不能换成手写 JSON。"""
    job = (workflow.get('jobs') or {}).get('matrix') or {}
    outputs = job.get('outputs') or {}
    errors: list[str] = []
    if _normalized(outputs.get('include')) != '${{ steps.emit.outputs.include }}':
        errors.append('ci.yml: matrix.outputs.include 必须来自 steps.emit.outputs.include')
    emit = next(
        (
            step
            for step in job.get('steps') or []
            if isinstance(step, dict) and step.get('id') == 'emit'
        ),
        None,
    )
    if emit is None:
        errors.append('ci.yml: matrix job 缺少 id=emit 的步骤')
    else:
        run = str(emit.get('run') or '')
        if 'scripts/ci_matrix.py --github-output' not in run:
            errors.append('ci.yml: matrix 的 emit 步骤必须调用 scripts/ci_matrix.py --github-output')
        if '$GITHUB_OUTPUT' not in run:
            errors.append('ci.yml: matrix 的 emit 步骤必须写入 $GITHUB_OUTPUT')
    return errors


def pr_template_errors(path: pathlib.Path | None = None) -> list[str]:
    """PR 模板是 check_pr_scope 的输入契约：改动类型段与四类勾选不能丢。"""
    target = path or PR_TEMPLATE
    if not target.is_file():
        return ['缺少 .github/PULL_REQUEST_TEMPLATE.md（PR 分类门禁没有输入）']
    text = target.read_text()
    errors: list[str] = []
    if '## 改动类型' not in text:
        errors.append('PULL_REQUEST_TEMPLATE.md: 缺少「## 改动类型」段（check_pr_scope 依赖它）')
    for box in ('内部重构', '公开变化', '删除 / 废弃', '新增包'):
        if box not in text:
            errors.append(f'PULL_REQUEST_TEMPLATE.md: 缺少改动类型「{box}」')
    return errors


def release_status_workflow_errors(path: pathlib.Path | None = None) -> list[str]:
    """周检是唯一能发现「快照漂移 / 仓库落后线上」的门禁，不能被静默删掉或写坏。

    不只看命令文本：`on.schedule` 被删、job / step 带 `if` 或 `continue-on-error`
    都会让周检静默消失（三轮审计 §16）。
    """
    target = path or RELEASE_STATUS_WORKFLOW
    if not target.is_file():
        return ['缺少 .github/workflows/release-status.yml（每周线上核对会消失）']
    import yaml

    try:
        workflow = yaml.safe_load(target.read_text()) or {}
    except yaml.YAMLError as error:
        return [f'.github/workflows/release-status.yml 不是合法 YAML：{error}']

    errors: list[str] = []
    jobs = workflow.get('jobs') or {}
    status = jobs.get('status') or {}
    steps = [step for step in (status.get('steps') or []) if isinstance(step, dict)]
    run_step = next(
        (
            step
            for step in steps
            if 'scripts/release_status.py --online --check' in str(step.get('run') or '')
        ),
        None,
    )
    if run_step is None:
        errors.append(
            '.github/workflows/release-status.yml: status job 必须运行 '
            '`python3 scripts/release_status.py --online --check`'
        )
    if 'if' in status:
        errors.append(
            '.github/workflows/release-status.yml: status job 不能带 if；'
            '否则周检会被静默跳过'
        )
    if run_step is not None:
        if 'if' in run_step:
            errors.append(
                '.github/workflows/release-status.yml: 周检步骤不能带 if；'
                '否则会静默跳过'
            )
        if run_step.get('continue-on-error'):
            errors.append(
                '.github/workflows/release-status.yml: 周检步骤不能开 continue-on-error；'
                '否则失败会被吞掉'
            )

    triggers = workflow.get('on')
    if triggers is None:
        triggers = workflow.get(True)  # PyYAML 把裸 `on:` 解析成布尔键
    schedule = triggers.get('schedule') if isinstance(triggers, dict) else None
    crons = {
        str(item['cron'])
        for item in (schedule or [])
        if isinstance(item, dict) and item.get('cron')
    }
    if '0 1 * * 1' not in crons:
        errors.append(
            '.github/workflows/release-status.yml: 必须保留 on.schedule 的 cron '
            "'0 1 * * 1'（每周一线上核对），否则周检会退化成手动"
        )
    return errors


def path_filter_errors(workflow: dict) -> list[str]:
    """CI 路径过滤器只能写正向规则。

    `predicate-quantifier: some-with-excludes` 没有「再包含」语义：一条
    `!packages/**/*.md` 会把后面正向列出的 `packages/cli/templates/**/*.md`
    一起挡掉（模板改错时重量级 job 全 skip）。这里把这类回归变成可单测的检查，
    而不是只写在 yml 注释里。
    """
    groups = filter_patterns(workflow)
    if not groups:
        return ['ci.yml: 找不到 changes job 的 filter 定义（路径门控无法校验）']
    errors: list[str] = []
    for group, patterns in groups.items():
        for pattern in patterns:
            if pattern.startswith('!'):
                errors.append(
                    f'ci.yml: 过滤器 {group} 含排除规则 {pattern}；'
                    'some-with-excludes 没有再包含语义，请改成纯正向列表',
                )
    return errors


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
        # example_test 列决定本地 preflight 是否跑该包 example 的测试；CI 则按文件存在判断。
        # 两边不同源时会出现「CI 跑了、本地没跑」或「列写着 example 但目录里没有测试」。
        has_example_tests = (directory / 'example' / 'test').is_dir()
        if row['example'] == 'example' and not has_example_tests:
            errors.append(
                f"packages.manifest:{row['line']}: {row['path']} 标记 example_test=example，"
                '但 example/test 目录不存在（preflight 会在这一步失败）',
            )
        if row['example'] == '-' and has_example_tests:
            errors.append(
                f"packages.manifest:{row['line']}: {row['path']} 有 example/test，"
                '但 example_test 列是 -（本地 preflight 不会跑它）',
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

    # 新增包还必须进根 pubspec 的 workspace，否则根目录 pub get / analyze 解析不到它。
    workspace = {
        str(entry).rstrip('/')
        for entry in (root_pubspec.get('workspace') or [])
    }
    manifest_paths = {row['path'].rstrip('/') for row in rows}
    for path in sorted(manifest_paths - workspace):
        errors.append(f'packages.manifest: {path} 不在根 pubspec.yaml 的 workspace 里')
    for path in sorted(workspace - manifest_paths):
        errors.append(f'root pubspec.yaml workspace: {path} 不在 packages.manifest 里')

    for directory in sorted((root / 'packages').iterdir()):
        if directory.is_dir() and directory.name not in listed:
            errors.append(f'packages/{directory.name}: 目录存在但不在 packages.manifest 里')

    workflow = yaml.safe_load(ci_path.read_text())
    jobs = workflow.get('jobs') or {}
    errors.extend(path_filter_errors(workflow))
    errors.extend(required_filter_errors(workflow))
    errors.extend(required_job_errors(workflow))
    # 上面几条只校验「文本里出现过」；下面几条把语义也钉死：
    # outputs / if / required 判定 / 门禁 step / 矩阵生成 / PR 模板 / 周检。
    errors.extend(wiring_errors(workflow))
    errors.extend(gate_step_errors(workflow))
    errors.extend(package_step_errors(workflow))
    errors.extend(matrix_emit_errors(workflow))
    errors.extend(pr_template_errors())
    errors.extend(release_status_workflow_errors())

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
