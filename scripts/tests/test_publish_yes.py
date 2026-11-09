from __future__ import annotations

import os
import pathlib
import shutil
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = ROOT / 'scripts' / 'publish_package.sh'


class PublishYesTest(unittest.TestCase):
    def setUp(self):
        self.tmp = pathlib.Path(tempfile.mkdtemp(prefix='pub_yes_'))
        self.addCleanup(lambda: shutil.rmtree(self.tmp, ignore_errors=True))
        self.bin = self.tmp / 'bin'
        self.bin.mkdir()
        self.log = self.tmp / 'runner.log'
        for name in ('dart', 'flutter'):
            runner = self.bin / name
            runner.write_text(f'#!/usr/bin/env bash\nprintf "%s\\n" "$@" > "{self.log}"\nexit 0\n')
            runner.chmod(0o755)
        self.snapshots = self.tmp / 'snapshots'

    def _run(self, *args: str) -> subprocess.CompletedProcess:
        env = dict(os.environ)
        env['PATH'] = f'{self.bin}:{env["PATH"]}'
        env['W_TOOLS_SNAPSHOT_DIR'] = str(self.snapshots)
        return subprocess.run(
            ['bash', str(SCRIPT), 'packages/toast', *args],
            cwd=ROOT,
            env=env,
            capture_output=True,
            text=True,
            encoding='utf-8',
            errors='replace',
        )

    def test_help_documents_yes(self):
        result = subprocess.run(
            ['bash', str(SCRIPT), '--help'],
            cwd=ROOT,
            capture_output=True,
            text=True,
            encoding='utf-8',
            errors='replace',
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('--yes', result.stdout)

    def test_yes_passes_force_to_pub_publish(self):
        # 用脚本自己的 --force 跳过发布前保护（干净 main / release_check），
        # 让本次只验证 `--yes` 是否把 `--force` 传给 pub publish。
        result = self._run('--yes', '--force', '--reason', 'unit test')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(self.log.is_file(), result.stdout + result.stderr)
        args = self.log.read_text().splitlines()
        self.assertIn('publish', args)
        self.assertIn('--force', args)

    def test_without_yes_does_not_force(self):
        result = self._run('--force', '--reason', 'unit test')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        args = self.log.read_text().splitlines()
        self.assertIn('publish', args)
        self.assertNotIn('--force', args)

    def test_dry_run_does_not_need_force(self):
        result = self._run('--yes', '--dry-run')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        args = self.log.read_text().splitlines()
        self.assertIn('--dry-run', args)
        self.assertNotIn('--force', args)


if __name__ == '__main__':
    unittest.main()
