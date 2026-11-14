import pathlib
import subprocess
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = ROOT / 'scripts' / '_run_with_timeout.py'


def run(*args):
    return subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        text=True,
        capture_output=True,
        encoding='utf-8',
        errors='replace',
    )


class RunWithTimeoutTest(unittest.TestCase):
    def test_passes_child_exit_code(self):
        result = run('--', sys.executable, '-c', 'import sys; sys.exit(7)')
        self.assertEqual(result.returncode, 7)

    def test_streams_output(self):
        result = run('--', sys.executable, '-c', "print('hello')")
        self.assertEqual(result.returncode, 0)
        self.assertIn('hello', result.stdout)

    def test_idle_timeout_kills_silent_child(self):
        result = run(
            '--idle-timeout',
            '0.2',
            '--total-timeout',
            '5',
            '--label',
            'silent',
            '--',
            sys.executable,
            '-c',
            'import time; time.sleep(30)',
        )
        self.assertEqual(result.returncode, 124)
        self.assertIn('无输出', result.stderr)
        self.assertIn('先查 pub.dev', result.stderr)

    def test_total_timeout_kills_chatty_child(self):
        result = run(
            '--idle-timeout',
            '5',
            '--total-timeout',
            '0.3',
            '--label',
            'chatty',
            '--',
            sys.executable,
            '-c',
            'import time\nwhile True:\n    print("tick", flush=True)\n    time.sleep(0.05)',
        )
        self.assertEqual(result.returncode, 124)
        self.assertIn('总时长', result.stderr)

    def test_missing_command_is_usage_error(self):
        result = run('--')
        self.assertEqual(result.returncode, 2)


if __name__ == '__main__':
    unittest.main()
