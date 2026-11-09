import os
import pathlib
import subprocess
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class PrePushHookTest(unittest.TestCase):
    def _run(self, refspec: str) -> subprocess.CompletedProcess:
        return subprocess.run(
            ['bash', str(ROOT / '.githooks/pre-push')],
            input=refspec,
            text=True,
            capture_output=True,
            encoding='utf-8',
            errors='replace',
            env={**os.environ, 'PRE_PUSH_SKIP_VERSION_CHECK': '1'},
        )

    def test_main_is_blocked(self):
        result = self._run('refs/heads/main abc refs/heads/main def\n')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('main', result.stderr)

    def test_feature_branch_is_allowed(self):
        result = self._run('refs/heads/feat abc refs/heads/feat def\n')
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == '__main__':
    unittest.main()
