import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = ROOT / 'scripts/apply_snapshots.sh'


def run(*args):
    return subprocess.run(
        ['bash', str(SCRIPT), *args],
        text=True,
        capture_output=True,
        encoding='utf-8',
        errors='replace',
    )


class ApplySnapshotsTest(unittest.TestCase):
    def test_missing_pending_dir_is_a_noop(self):
        with tempfile.TemporaryDirectory() as temp:
            pending = pathlib.Path(temp) / 'missing'
            target = pathlib.Path(temp) / 'out'
            result = run('--from', str(pending), '--to', str(target))
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('没有待应用快照', result.stdout)
            self.assertFalse(target.exists())

    def test_empty_pending_dir_is_a_noop(self):
        with tempfile.TemporaryDirectory() as temp:
            pending = pathlib.Path(temp) / 'pending'
            pending.mkdir()
            target = pathlib.Path(temp) / 'out'
            result = run('--from', str(pending), '--to', str(target))
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('为空', result.stdout)

    def test_moves_snapshots_and_leaves_other_files(self):
        with tempfile.TemporaryDirectory() as temp:
            pending = pathlib.Path(temp) / 'pending'
            target = pathlib.Path(temp) / 'out'
            pending.mkdir()
            (pending / 'w_tools_ui-7.0.0.txt').write_text('# w_tools_ui 7.0.0\n')
            (pending / 'notes.txt').write_text('not a snapshot')
            result = run('--from', str(pending), '--to', str(target))
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((target / 'w_tools_ui-7.0.0.txt').exists())
            self.assertFalse((pending / 'w_tools_ui-7.0.0.txt').exists())
            self.assertTrue((pending / 'notes.txt').exists())
            self.assertIn('git switch -c chore/release-snapshots', result.stdout)

    def test_multiple_snapshots_apply_together(self):
        with tempfile.TemporaryDirectory() as temp:
            pending = pathlib.Path(temp) / 'pending'
            target = pathlib.Path(temp) / 'out'
            pending.mkdir()
            (pending / 'w_tools_ui-7.0.0.txt').write_text('ui\n')
            (pending / 'w_tools_api-5.0.0.txt').write_text('api\n')
            result = run('--from', str(pending), '--to', str(target))
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(
                sorted(path.name for path in target.iterdir()),
                ['w_tools_api-5.0.0.txt', 'w_tools_ui-7.0.0.txt'],
            )

    def test_prints_merge_hint(self):
        with tempfile.TemporaryDirectory() as temp:
            pending = pathlib.Path(temp) / 'pending'
            target = pathlib.Path(temp) / 'out'
            pending.mkdir()
            (pending / 'w_tools_toast-2.1.0.txt').write_text('# header\n')
            result = run('--from', str(pending), '--to', str(target))
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((target / 'w_tools_toast-2.1.0.txt').is_file())
            # 仓库 allow_auto_merge=false；快照 PR 打印的必须是可直接执行的 --merge。
            self.assertIn('gh pr merge --merge', result.stdout)
            self.assertNotIn('gh pr merge --auto', result.stdout)


if __name__ == '__main__':
    unittest.main()
