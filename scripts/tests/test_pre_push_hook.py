import pathlib
import subprocess
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class PrePushHookTest(unittest.TestCase):
    def test_main_is_blocked(self):
        result = subprocess.run(
            ['bash', str(ROOT / '.githooks/pre-push')],
            input='refs/heads/main abc refs/heads/main def\n',
            text=True,
            capture_output=True,
            encoding='utf-8',
            errors='replace',
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('main', result.stderr)

    def test_feature_branch_is_allowed(self):
        result = subprocess.run(
            ['bash', str(ROOT / '.githooks/pre-push')],
            input='refs/heads/feat abc refs/heads/feat def\n',
            text=True,
            capture_output=True,
            encoding='utf-8',
            errors='replace',
        )
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == '__main__':
    unittest.main()
