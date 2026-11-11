from __future__ import annotations

import os
import pathlib
import shutil
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class GhWaitChecksTest(unittest.TestCase):
    def setUp(self):
        self.tmp = pathlib.Path(tempfile.mkdtemp(prefix='gh_wait_'))
        self.addCleanup(lambda: shutil.rmtree(self.tmp, ignore_errors=True))
        self.bin = self.tmp / 'bin'
        self.bin.mkdir()
        self.count = self.tmp / 'count'
        fake = self.bin / 'gh'
        fake.write_text(
            '#!/usr/bin/env bash\n'
            'set -e\n'
            'if [ "$1" = "pr" ] && [ "$2" = "view" ]; then\n'
            '  n=0\n'
            '  if [ -f "$FAKE_GH_COUNT" ]; then n=$(cat "$FAKE_GH_COUNT"); fi\n'
            '  n=$((n + 1))\n'
            '  echo "$n" > "$FAKE_GH_COUNT"\n'
            '  if [ "$n" -lt 2 ]; then echo 0; else echo 1; fi\n'
            '  exit 0\n'
            'fi\n'
            'if [ "$1" = "pr" ] && [ "$2" = "checks" ]; then\n'
            '  echo checks-watched\n'
            '  exit 0\n'
            'fi\n'
            'echo "unexpected gh: $*" >&2\n'
            'exit 1\n',
        )
        fake.chmod(0o755)

    def _run(self, timeout: int) -> subprocess.CompletedProcess:
        env = dict(os.environ)
        env['PATH'] = f'{self.bin}:{env["PATH"]}'
        env['FAKE_GH_COUNT'] = str(self.count)
        env['GH_WAIT_INTERVAL'] = '1'
        return subprocess.run(
            [
                'bash',
                '-c',
                f'source "{ROOT}/scripts/_gh.sh"; gh_wait_checks 42 {timeout}',
            ],
            cwd=ROOT,
            env=env,
            capture_output=True,
            text=True,
            encoding='utf-8',
            errors='replace',
        )

    def test_waits_until_checks_register_then_watches(self):
        result = self._run(timeout=10)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('checks-watched', result.stdout)

    def test_timeout_without_checks_fails(self):
        # 让 fake gh 永远返回 0：文件计数只增不减，但输出固定 0。
        fake = self.bin / 'gh'
        fake.write_text(
            '#!/usr/bin/env bash\n'
            'if [ "$1" = "pr" ] && [ "$2" = "view" ]; then echo 0; exit 0; fi\n'
            'exit 1\n',
        )
        fake.chmod(0o755)
        result = self._run(timeout=1)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('没有注册任何 checks', result.stderr)


if __name__ == '__main__':
    unittest.main()
