import json
import pathlib
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = ROOT / 'scripts' / 'agents_budget_trend.py'


def make_record(version: str, *, lines: int = 70, chars: int = 1000) -> dict:
    return {
        'schema': 'w_tools_cli.agent_budget/1',
        'schemaVersion': 1,
        'generator': version,
        'measuredAt': '2026-11-10T00:00:00.000Z',
        'rows': [
            {
                'lang': 'zh',
                'profile': 'full',
                'lines': lines,
                'chars': chars,
                'limitLines': 90,
                'limitChars': 6000,
            },
            {
                'lang': 'en',
                'profile': 'full',
                'lines': 82,
                'chars': 5738,
                'limitLines': 100,
                'limitChars': 7000,
            },
        ],
        'feedback': {'zh': 2, 'en': 2, 'maxLines': 4},
    }


class AgentsBudgetTrendTest(unittest.TestCase):
    def _run(self, history, *args, pubspec_version: str = '1.18.0'):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = pathlib.Path(tmp)
            if history is not None:
                (tmp_path / 'history.jsonl').write_text(history)
            pubspec = tmp_path / 'pubspec.yaml'
            pubspec.write_text(f'name: w_tools_cli\nversion: {pubspec_version}\n')
            return subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    '--history',
                    str(tmp_path / 'history.jsonl'),
                    '--pubspec',
                    str(pubspec),
                    *args,
                ],
                capture_output=True,
                text=True,
            )

    def test_renders_table_with_delta(self):
        history = (
            json.dumps(make_record('1.17.2', lines=65, chars=900), ensure_ascii=False)
            + '\n'
            + json.dumps(make_record('1.18.0', lines=70, chars=1000), ensure_ascii=False)
            + '\n'
        )
        result = self._run(history)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('| 1.17.2 |', result.stdout)
        self.assertIn('| 1.18.0 |', result.stdout)
        self.assertIn('70/90 (78%)', result.stdout)
        self.assertIn('+100', result.stdout)

    def test_missing_history_fails_with_hint(self):
        result = self._run(None)
        self.assertEqual(result.returncode, 1)
        self.assertIn('--record', result.stderr)

    def test_bad_line_reports_line_number(self):
        history = json.dumps(make_record('1.18.0')) + '\n{broken\n'
        result = self._run(history)
        self.assertEqual(result.returncode, 1)
        self.assertIn(':2', result.stderr)

    def test_wrong_schema_fails(self):
        record = make_record('1.18.0')
        record['schema'] = 'something_else/1'
        result = self._run(json.dumps(record) + '\n')
        self.assertEqual(result.returncode, 1)
        self.assertIn('schema', result.stderr)

    def test_stale_history_warns_but_passes(self):
        history = json.dumps(make_record('1.17.2')) + '\n'
        result = self._run(history, pubspec_version='1.18.0')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('::warning::', result.stdout)
        self.assertIn('1.17.2', result.stdout)

    def test_summary_file_appends_markdown(self):
        history = json.dumps(make_record('1.18.0')) + '\n'
        with tempfile.TemporaryDirectory() as tmp:
            summary = pathlib.Path(tmp) / 'summary.md'
            result = self._run(history, '--summary', str(summary))
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('AGENTS 片段预算趋势', summary.read_text())


if __name__ == '__main__':
    unittest.main()
