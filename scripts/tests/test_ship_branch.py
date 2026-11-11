from __future__ import annotations

import os
import pathlib
import shutil
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SHIP = ROOT / 'scripts/ship.sh'
GH_HELPER = ROOT / 'scripts/_gh.sh'
PR_READY = ROOT / 'scripts/check_pr_ready.sh'


class ShipAutoBranchTest(unittest.TestCase):
    def _repo(self) -> tuple[pathlib.Path, dict[str, str]]:
        temp = pathlib.Path(tempfile.mkdtemp(prefix='ship_branch_'))
        self.addCleanup(lambda: shutil.rmtree(temp, ignore_errors=True))
        (temp / 'scripts').mkdir()
        for source in (SHIP, GH_HELPER, PR_READY):
            shutil.copy(source, temp / 'scripts' / source.name)
        bin_dir = temp / 'bin'
        bin_dir.mkdir()
        gh = bin_dir / 'gh'
        gh.write_text('#!/usr/bin/env bash\nexit 0\n')
        gh.chmod(0o755)
        subprocess.run(['git', 'init', '-q'], cwd=temp, check=True)
        # 把复制进来的脚本先提交，否则 ship.sh 的 git add -A 会把它们当成本次改动。
        subprocess.run(['git', 'add', '.'], cwd=temp, check=True)
        subprocess.run(
            [
                'git',
                '-c',
                'user.name=test',
                '-c',
                'user.email=test@example.com',
                'commit',
                '-m',
                'init',
            ],
            cwd=temp,
            check=True,
            capture_output=True,
        )
        # CI 的 git init 默认分支可能是 master；ship.sh 的自动分支只认 main。
        subprocess.run(['git', 'branch', '-m', 'main'], cwd=temp, check=True)
        env = dict(os.environ)
        env['PATH'] = f'{bin_dir}:{env["PATH"]}'
        env['GIT_AUTHOR_NAME'] = 'test'
        env['GIT_AUTHOR_EMAIL'] = 'test@example.com'
        env['GIT_COMMITTER_NAME'] = 'test'
        env['GIT_COMMITTER_EMAIL'] = 'test@example.com'
        return temp, env

    def _run(self, repo: pathlib.Path, env: dict[str, str], *args: str):
        return subprocess.run(
            ['bash', str(repo / 'scripts/ship.sh'), *args],
            cwd=repo,
            env=env,
            capture_output=True,
            text=True,
            encoding='utf-8',
            errors='replace',
        )

    def _branch(self, repo: pathlib.Path) -> str:
        return subprocess.run(
            ['git', 'branch', '--show-current'],
            cwd=repo,
            capture_output=True,
            text=True,
            encoding='utf-8',
        ).stdout.strip()

    def test_creates_branch_from_conventional_message(self):
        repo, env = self._repo()
        result = self._run(
            repo,
            env,
            '-m',
            'fix: auto branch demo',
            '--type',
            'internal',
            '--yes',
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self._branch(repo), 'fix/auto-branch-demo')

    def test_dry_run_prints_branch_without_creating_it(self):
        repo, env = self._repo()
        before = self._branch(repo)
        result = self._run(
            repo,
            env,
            '-m',
            'fix: dry run demo',
            '--type',
            'internal',
            '--dry-run',
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('fix/dry-run-demo', result.stdout)
        self.assertEqual(self._branch(repo), before)

    def test_branch_override_wins(self):
        repo, env = self._repo()
        result = self._run(
            repo,
            env,
            '-m',
            'fix: ignored slug',
            '--type',
            'internal',
            '--branch',
            'chore/custom-branch',
            '--yes',
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self._branch(repo), 'chore/custom-branch')


if __name__ == '__main__':
    unittest.main()
