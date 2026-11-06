import pathlib
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from release_status import changelog_first, classify, version_tuple


class ReleaseStatusTest(unittest.TestCase):
    def test_published(self):
        self.assertEqual(classify('1.2.3', '1.2.3'), '已发布')

    def test_pending(self):
        self.assertEqual(classify('1.3.0', '1.2.3'), '待发布')

    def test_behind(self):
        self.assertEqual(classify('1.2.3', '1.3.0'), '落后')

    def test_unknown_without_online(self):
        self.assertEqual(classify('1.2.3', None), '未核对')

    def test_version_tuple_ignores_prerelease_suffix(self):
        self.assertEqual(version_tuple('7.0.0'), (7, 0, 0))
        self.assertEqual(version_tuple('1.0.0-dev.1'), (1, 0, 0, 1))

    def test_changelog_first_skips_title_and_unreleased(self):
        with tempfile.TemporaryDirectory() as temp:
            path = pathlib.Path(temp) / 'CHANGELOG.md'
            path.write_text('# Changelog\n\n## Unreleased\n\n- wip\n\n## 1.2.3\n\n- done\n')
            self.assertEqual(changelog_first(path), '1.2.3')


if __name__ == '__main__':
    unittest.main()
