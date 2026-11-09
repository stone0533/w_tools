from __future__ import annotations

import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
HOOK = ROOT / '.githooks' / 'commit-msg'


def run_hook(message: str) -> subprocess.CompletedProcess:
    with tempfile.NamedTemporaryFile('w', suffix='.txt', delete=False) as handle:
        handle.write(message)
        path = handle.name
    try:
        return subprocess.run(
            ['bash', str(HOOK), path],
            capture_output=True,
            text=True,
            encoding='utf-8',
            errors='replace',
        )
    finally:
        pathlib.Path(path).unlink()


class CommitMsgHookTest(unittest.TestCase):
    def test_accepts_conventional_prefixes(self):
        for message in (
            'fix(cli): doctor 输出补齐 skipped\n',
            'feat(toast)!: 新增 showModal\n',
            'docs: 补发布流程\n',
            'chore(release): toast 2.1.0\n',
            'test(scripts): 补用例\n',
            'refactor: 收口 helper\n',
            'perf: 减少一次遍历\n',
            'build: 版本约束\n',
            'ci: 加门禁\n',
            'style: 格式化\n',
        ):
            result = run_hook(message)
            self.assertEqual(result.returncode, 0, f'{message!r}: {result.stderr}')

    def test_accepts_merge_and_revert(self):
        for message in (
            'Merge branch main into feat/x\n',
            'Merge pull request #57 from stone0533/fix/feedback-50-53\n',
            'Revert "feat: 某功能"\n',
            'fixup! feat: 某功能\n',
            'squash! fix: 某修复\n',
        ):
            self.assertEqual(run_hook(message).returncode, 0, message)

    def test_rejects_missing_prefix(self):
        result = run_hook('update some files\n')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('conventional', result.stderr)

    def test_rejects_prefix_without_description(self):
        self.assertNotEqual(run_hook('fix:\n').returncode, 0)
        self.assertNotEqual(run_hook('fix(cli):\n').returncode, 0)

    def test_rejects_unknown_prefix(self):
        self.assertNotEqual(run_hook('featx: 某功能\n').returncode, 0)


if __name__ == '__main__':
    unittest.main()
