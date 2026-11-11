import os
import pathlib
import shutil
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
            # 快照 PR 交给 ship.sh：它会等 checks 注册后再 merge；不要教裸 gh pr checks。
            self.assertIn('bash scripts/ship.sh --type internal --merge --yes', result.stdout)
            self.assertNotIn('gh pr checks --required', result.stdout)
            self.assertNotIn('gh pr merge --auto', result.stdout)

    def test_ship_creates_branch_and_delegates_to_ship(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / 'scripts').mkdir()
            shutil.copy(SCRIPT, root / 'scripts/apply_snapshots.sh')
            log = root / 'ship.log'
            fake = root / 'scripts/ship.sh'
            fake.write_text(
                '#!/usr/bin/env bash\nprintf "%s\\n" "$@" > "$SHIP_LOG"\n',
            )
            subprocess.run(['git', 'init', '-q'], cwd=root, check=True)
            subprocess.run(
                [
                    'git',
                    '-c',
                    'user.name=test',
                    '-c',
                    'user.email=test@example.com',
                    'commit',
                    '--allow-empty',
                    '-m',
                    'init',
                ],
                cwd=root,
                check=True,
                capture_output=True,
            )
            pending = root / 'pending'
            pending.mkdir()
            (pending / 'w_tools_ui-7.0.0.txt').write_text('ui\n')
            target = root / 'scripts/api_snapshots'
            env = dict(os.environ)
            env['SHIP_LOG'] = str(log)
            result = subprocess.run(
                [
                    'bash',
                    str(root / 'scripts/apply_snapshots.sh'),
                    '--ship',
                    '--from',
                    str(pending),
                    '--to',
                    str(target),
                ],
                cwd=root,
                env=env,
                capture_output=True,
                text=True,
                encoding='utf-8',
                errors='replace',
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            args = log.read_text().splitlines()
            self.assertIn('chore(release): ui 7.0.0 API 基线', args)
            self.assertIn('--type', args)
            self.assertIn('internal', args)
            self.assertIn('--merge', args)
            branch = subprocess.run(
                ['git', 'branch', '--show-current'],
                cwd=root,
                capture_output=True,
                text=True,
                encoding='utf-8',
            ).stdout.strip()
            self.assertTrue(branch.startswith('chore/release-snapshots-'), branch)


if __name__ == '__main__':
    unittest.main()
