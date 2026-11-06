import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


def run(cwd, *args):
    return subprocess.run(args, cwd=cwd, text=True, capture_output=True, encoding='utf-8', errors='replace')


class GitSyncIntegrationTest(unittest.TestCase):
    def test_no_upstream_fails(self):
        with tempfile.TemporaryDirectory() as temp:
            repo = pathlib.Path(temp)
            run(repo, 'git', 'init', '-q')
            run(repo, 'git', 'config', 'user.email', 'test@example.com')
            run(repo, 'git', 'config', 'user.name', 'Test')
            (repo / 'a.txt').write_text('a')
            run(repo, 'git', 'add', '.')
            run(repo, 'git', 'commit', '-qm', 'init')
            result = run(repo, 'bash', str(ROOT / 'scripts/check_git_sync.sh'), '.')
            self.assertNotEqual(result.returncode, 0)

    def test_synced_repo_passes_and_ahead_fails(self):
        with tempfile.TemporaryDirectory() as temp:
            base = pathlib.Path(temp)
            remote = base / 'remote.git'
            repo = base / 'repo'
            run(base, 'git', 'init', '--bare', '-q', str(remote))
            run(base, 'git', 'init', '-q', str(repo))
            run(repo, 'git', 'config', 'user.email', 'test@example.com')
            run(repo, 'git', 'config', 'user.name', 'Test')
            (repo / 'a.txt').write_text('a')
            run(repo, 'git', 'add', '.')
            run(repo, 'git', 'commit', '-qm', 'init')
            run(repo, 'git', 'remote', 'add', 'origin', str(remote))
            run(repo, 'git', 'push', '-qu', 'origin', 'HEAD:main')
            run(repo, 'git', 'branch', '--set-upstream-to=origin/main', 'main')

            result = run(repo, 'bash', str(ROOT / 'scripts/check_git_sync.sh'), '.')
            self.assertEqual(result.returncode, 0, result.stderr)

            (repo / 'b.txt').write_text('b')
            run(repo, 'git', 'add', '.')
            run(repo, 'git', 'commit', '-qm', 'ahead')
            result = run(repo, 'bash', str(ROOT / 'scripts/check_git_sync.sh'), '.')
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('未 push', result.stderr)


if __name__ == '__main__':
    unittest.main()
