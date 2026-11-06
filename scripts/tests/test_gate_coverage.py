import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from check_gate_coverage import coverage_errors


class GateCoverageTest(unittest.TestCase):
    def test_script_with_entrypoint_and_readme_passes(self):
        errors = coverage_errors(['check_docs.sh'], 'bash scripts/check_docs.sh', '| check_docs.sh |', {})
        self.assertEqual(errors, [])

    def test_script_without_entrypoint_fails(self):
        errors = coverage_errors(['check_new.py'], 'bash scripts/preflight.sh', '| check_new.py |', {})
        self.assertEqual(len(errors), 1)
        self.assertIn('没有任何入口', errors[0])

    def test_script_without_readme_row_fails(self):
        errors = coverage_errors(['check_docs.sh'], 'bash scripts/check_docs.sh', '', {})
        self.assertEqual(len(errors), 1)
        self.assertIn('scripts/README.md 没有登记', errors[0])

    def test_manual_scripts_need_a_reason(self):
        self.assertEqual(
            coverage_errors(['manual.sh'], 'nothing', '| manual.sh |', {'manual.sh': '人工执行'}),
            [],
        )
        errors = coverage_errors(['manual.sh'], 'nothing', '| manual.sh |', {'manual.sh': ' '})
        self.assertTrue(any('没有写理由' in error for error in errors))

    def test_stale_manual_entry_fails(self):
        errors = coverage_errors(['check_docs.sh'], 'bash scripts/check_docs.sh', 'scripts/check_docs.sh',
                                 {'gone.py': '已经不存在的脚本'})
        self.assertEqual(len(errors), 1)
        self.assertIn('MANUAL 登记了不存在的脚本 gone.py', errors[0])

    def test_comment_mention_does_not_count_as_entrypoint(self):
        errors = coverage_errors(
            ['check_new.py'], '# 以后要跑 check_new.py\nbash scripts/preflight.sh',
            '| check_new.py |', {},
        )
        self.assertEqual(len(errors), 1)
        self.assertIn('没有任何入口', errors[0])

    def test_echo_mention_does_not_count_as_entrypoint(self):
        errors = coverage_errors(
            ['check_new.py'], 'echo "记得跑 check_new.py"\nbash scripts/preflight.sh',
            '| check_new.py |', {},
        )
        self.assertEqual(len(errors), 1)
        self.assertIn('没有任何入口', errors[0])

    def test_python_invocation_counts_as_entrypoint(self):
        errors = coverage_errors(
            ['check_new.py'], 'run "x" python3 scripts/check_new.py', '| check_new.py |', {},
        )
        self.assertEqual(errors, [])


if __name__ == '__main__':
    unittest.main()
