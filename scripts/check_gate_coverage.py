#!/usr/bin/env python3
"""门禁覆盖自检：每个 scripts/ 下的检查脚本都必须有真实入口，并在 scripts/README 有登记。

为什么要这条：门禁清单曾在三处手写（`scripts/README.md` 的表格、`preflight.sh` 的执行顺序、
`check_docs.sh` 的子集、`ci.yml` 的 job）。历史上 `check_public_catalog` / `check_deprecations`
就是「文档说在跑、CI 里其实没跑」。本脚本不生成清单，只保证：

1. 每个 `scripts/*.sh|py`（`_` 开头的是被 import 的 helper，不算）都出现在至少一个入口里：
   `preflight.sh` / `check_docs.sh` / `release_check.sh` / `.github/workflows/*.yml`；
2. 人工执行、不进门禁的脚本必须在 `MANUAL` 里写明理由（并且文件确实存在）；
3. 每个脚本都在 `scripts/README.md` 里出现（读者能找到「什么时候跑它」）。

它本身由 `preflight.sh` 调用，所以新增检查脚本忘了接线会当场失败。
"""
from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SCRIPTS = ROOT / 'scripts'
README = SCRIPTS / 'README.md'

ENTRYPOINTS = [
    SCRIPTS / 'preflight.sh',
    SCRIPTS / 'check_docs.sh',
    SCRIPTS / 'release_check.sh',
]
ENTRYPOINTS += sorted((ROOT / '.github' / 'workflows').glob('*.yml'))

# 人工执行、刻意不进门禁的脚本：value 是理由（空理由会失败，避免「先登记再说」）。
MANUAL = {
    'apply_snapshots.sh': '发布一批后把 .w_tools/release-snapshots 应用到 scripts/api_snapshots，人工执行',
    'install-gh.sh': '一次性安装 / 登录向导，人工执行',
    'install_git_hooks.sh': '首次检出时安装 .githooks，人工执行',
    'check_pr_checks.sh': '发布前用 gh 确认 PR Required checks，人工执行',
    'list_removals.py': '准备大版本时列出待删弃用项，人工执行',
}


def script_files() -> list[str]:
    names = [
        path.name
        for path in sorted(SCRIPTS.iterdir())
        if path.is_file() and path.suffix in ('.sh', '.py') and not path.name.startswith('_')
    ]
    return names


def entrypoint_text() -> str:
    """入口文件里「真的会执行」的行；整行注释不算接线。

    以前整文件拼接，脚本名只出现在注释 / 说明里也算有入口（例如
    `# 以后要跑 check_x.py`），覆盖自检就形同虚设。
    """
    lines: list[str] = []
    for path in ENTRYPOINTS:
        if not path.is_file():
            continue
        for line in path.read_text().splitlines():
            if line.lstrip().startswith('#'):
                continue
            lines.append(line)
    return '\n'.join(lines)


def invoked(name: str, text: str) -> bool:
    """脚本名必须出现在 bash / sh / dart / python3 的同一行命令里，而不是 echo 文案里。"""
    pattern = re.compile(
        rf'(?:^|[\s;&|(])(?:bash|sh|dart|python3?)\b[^\n]*?'
        rf'(?<![\w.-]){re.escape(name)}(?![\w.-])',
        re.MULTILINE,
    )
    return pattern.search(text) is not None


def coverage_errors(
    names: list[str],
    entry_text: str,
    readme_text: str,
    manual: dict[str, str] | None = None,
) -> list[str]:
    manual = MANUAL if manual is None else manual
    errors: list[str] = []
    for name in names:
        if name in manual:
            if not manual[name].strip():
                errors.append(f'{name}: MANUAL 里没有写理由（人工脚本也要说明为什么）')
        elif not invoked(name, entry_text):
            errors.append(
                f'{name}: 没有任何入口在跑它（preflight / check_docs / release_check / workflow）；'
                '接线，或在 check_gate_coverage.py 的 MANUAL 里写明理由',
            )
        if not re.search(rf'(?<![\w.-]){re.escape(name)}(?![\w.-])', readme_text):
            errors.append(f'{name}: scripts/README.md 没有登记（读者不知道什么时候该跑）')
    for name in sorted(manual):
        if name not in names:
            errors.append(f'MANUAL 登记了不存在的脚本 {name}（删掉这一行）')
    return errors


def main() -> int:
    errors = coverage_errors(script_files(), entrypoint_text(), README.read_text())
    if errors:
        for error in errors:
            print(f'✗ {error}', file=sys.stderr)
        print(f'\n门禁覆盖检查失败：{len(errors)} 项', file=sys.stderr)
        return 1
    print('门禁覆盖检查通过（每个脚本都有入口，并在 scripts/README 登记）')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
