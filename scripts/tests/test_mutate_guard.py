import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = ROOT / 'scripts' / 'mutate_guard.sh'


def run(*args):
    return subprocess.run(
        ['bash', str(SCRIPT), *args],
        cwd=ROOT,
        text=True,
        capture_output=True,
        encoding='utf-8',
        errors='replace',
    )


class MutateGuardTest(unittest.TestCase):
    def test_red_baseline_is_invalid(self):
        """变异前用例本来就红，不能把“仍然红”当成变异被杀死。"""
        with tempfile.TemporaryDirectory() as temp:
            source = pathlib.Path(temp) / 'guard.txt'
            source.write_text('guard = 1\n')
            result = run(
                '--file', str(source),
                '--from', 'guard = 1', '--to', 'guard = 2',
                '--', 'bash', '-c', 'exit 1',
            )
            self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
            self.assertIn('基线', result.stderr)
            self.assertEqual(source.read_text(), 'guard = 1\n')

    def test_killed_mutation_passes(self):
        with tempfile.TemporaryDirectory() as temp:
            tempdir = pathlib.Path(temp)
            source = tempdir / 'guard.txt'
            source.write_text('guard = 1\n')
            check = tempdir / 'check.sh'
            check.write_text('#!/usr/bin/env bash\ngrep -q "guard = 1" "$1"\n')
            check.chmod(0o755)
            result = run(
                '--file', str(source),
                '--from', 'guard = 1', '--to', 'guard = 2',
                '--', 'bash', str(check), str(source),
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn('变异被杀死', result.stdout)
            self.assertEqual(source.read_text(), 'guard = 1\n')

    def test_alive_mutation_fails(self):
        with tempfile.TemporaryDirectory() as temp:
            tempdir = pathlib.Path(temp)
            source = tempdir / 'guard.txt'
            source.write_text('guard = 1\n')
            check = tempdir / 'check.sh'
            check.write_text('#!/usr/bin/env bash\nexit 0\n')
            check.chmod(0o755)
            result = run(
                '--file', str(source),
                '--from', 'guard = 1', '--to', 'guard = 2',
                '--', 'bash', str(check), str(source),
            )
            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
            self.assertIn('变异存活', result.stdout + result.stderr)
            self.assertEqual(source.read_text(), 'guard = 1\n')

    def test_expected_feature_must_appear(self):
        with tempfile.TemporaryDirectory() as temp:
            tempdir = pathlib.Path(temp)
            source = tempdir / 'guard.txt'
            source.write_text('guard = 1\n')
            check = tempdir / 'check.sh'
            check.write_text('#!/usr/bin/env bash\ngrep -q "guard = 1" "$1"\n')
            check.chmod(0o755)
            result = run(
                '--file', str(source),
                '--from', 'guard = 1', '--to', 'guard = 2',
                '--expect', 'not-in-output',
                '--', 'bash', str(check), str(source),
            )
            self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
            self.assertIn('没有预期特征', result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
