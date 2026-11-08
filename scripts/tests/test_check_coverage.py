import pathlib
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = ROOT / 'scripts' / 'check_coverage.py'


class CheckCoverageTest(unittest.TestCase):
    def _run(self, lcov: str, *args: str) -> subprocess.CompletedProcess:
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / 'lcov.info'
            path.write_text(lcov)
            return subprocess.run(
                [sys.executable, str(SCRIPT), '--lcov', str(path), *args],
                capture_output=True,
                text=True,
            )

    def test_pass_above_floor(self):
        result = self._run('SF:lib/a.dart\nLF:100\nLH:95\nend_of_record\n', '--min-lines', '90')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('95.0%', result.stdout)

    def test_fail_below_floor(self):
        result = self._run('SF:lib/a.dart\nLF:100\nLH:80\nend_of_record\n', '--min-lines', '90')
        self.assertEqual(result.returncode, 1)
        self.assertIn('80.0%', result.stderr)

    def test_missing_report(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), '--lcov', '/nonexistent/lcov.info', '--min-lines', '90'],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn('lcov.info', result.stderr)
