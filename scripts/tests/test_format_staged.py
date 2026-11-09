from __future__ import annotations

import pathlib
import shutil
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = ROOT / 'scripts' / 'format_staged.sh'
HOOK = ROOT / '.githooks' / 'pre-commit'


def _git(repo: pathlib.Path, *args: str) -> None:
    subprocess.run(['git', *args], cwd=repo, check=True, capture_output=True, text=True)


class FormatStagedTest(unittest.TestCase):
    def setUp(self):
        self.repo = pathlib.Path(tempfile.mkdtemp(prefix='fmt_staged_'))
        self.addCleanup(lambda: shutil.rmtree(self.repo, ignore_errors=True))
        _git(self.repo, 'init', '-q')
        _git(self.repo, 'config', 'user.email', 'test@example.com')
        _git(self.repo, 'config', 'user.name', 'test')

    def _run(self, script: pathlib.Path) -> subprocess.CompletedProcess:
        return subprocess.run(
            ['bash', str(script)],
            cwd=self.repo,
            capture_output=True,
            text=True,
            encoding='utf-8',
            errors='replace',
        )

    def test_unformatted_staged_dart_file_is_rejected(self):
        path = self.repo / 'a.dart'
        path.write_text('void  main( ){}\n')
        _git(self.repo, 'add', 'a.dart')
        result = self._run(SCRIPT)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('a.dart', result.stdout + result.stderr)

    def test_formatted_staged_dart_file_passes(self):
        path = self.repo / 'a.dart'
        path.write_text('void main() {}\n')
        _git(self.repo, 'add', 'a.dart')
        result = self._run(SCRIPT)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_no_staged_dart_files_passes(self):
        (self.repo / 'README.md').write_text('hi\n')
        _git(self.repo, 'add', 'README.md')
        result = self._run(SCRIPT)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_hook_delegates_to_script(self):
        self.assertTrue(HOOK.is_file())
        path = self.repo / 'a.dart'
        path.write_text('void  main( ){}\n')
        _git(self.repo, 'add', 'a.dart')
        result = self._run(HOOK)
        self.assertNotEqual(result.returncode, 0)


if __name__ == '__main__':
    unittest.main()
