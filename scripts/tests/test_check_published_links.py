import pathlib
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))

import check_published_links as mod


class PublishedLinksTest(unittest.TestCase):
    def test_repository_readmes_have_no_links_outside_package(self):
        self.assertEqual(mod.find_errors(ROOT), [])

    def test_root_readme_rejects_excluded_repo_directory(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / 'docs').mkdir()
            (root / 'docs' / 'guide.md').write_text('guide')
            (root / 'README.md').write_text('[guide](docs/guide.md)\n')
            errors = mod.find_errors(root)
            self.assertEqual(len(errors), 1, errors)
            self.assertIn('docs/guide.md', errors[0])

    def test_root_readme_allows_shipped_files_and_absolute_urls(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / 'docs').mkdir()
            (root / 'docs' / 'README.md').write_text('docs')
            (root / 'README.md').write_text(
                '[contrib](CONTRIBUTING.md)\n'
                '[example](example/)\n'
                '[docs](https://github.com/stone0533/w_tools/blob/main/docs/README.md)\n'
                '[anchor](#install)\n'
            )
            self.assertEqual(mod.find_errors(root), [])

    def test_absolute_repo_url_missing_path_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / 'README.md').write_text(
                '[missing](https://github.com/stone0533/w_tools/blob/main/docs/nope.md)\n'
            )
            errors = mod.find_errors(root)
            self.assertEqual(len(errors), 1, errors)
            self.assertIn('绝对链接路径不存在', errors[0])

    def test_absolute_repo_url_existing_path_is_allowed(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / 'docs').mkdir()
            (root / 'docs' / 'guide.md').write_text('guide')
            (root / 'README.md').write_text(
                '[guide](https://github.com/stone0533/w_tools/blob/main/docs/guide.md)\n'
            )
            self.assertEqual(mod.find_errors(root), [])

    def test_root_changelog_and_contributing_are_scanned(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / 'docs').mkdir()
            (root / 'docs' / 'guide.md').write_text('guide')
            (root / 'CONTRIBUTING.md').write_text('[guide](docs/guide.md)\n')
            (root / 'CHANGELOG.md').write_text('[guide](docs/guide.md)\n')
            errors = mod.find_errors(root)
            self.assertEqual(len(errors), 2, errors)
            rendered = '\n'.join(errors)
            self.assertIn('CONTRIBUTING.md:1', rendered)
            self.assertIn('CHANGELOG.md:1', rendered)

    def test_root_absolute_path_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / 'README.md').write_text('[guide](/docs/guide.md)\n')
            errors = mod.find_errors(root)
            self.assertEqual(len(errors), 1, errors)
            self.assertIn('仓库外', errors[0])

    def test_package_changelog_escape_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            ui = root / 'packages' / 'ui'
            ui.mkdir(parents=True)
            (root / 'docs').mkdir()
            (root / 'docs' / 'ui.md').write_text('ui')
            (ui / 'CHANGELOG.md').write_text('[module](../../docs/ui.md)\n')
            errors = mod.find_errors(root)
            self.assertEqual(len(errors), 1, errors)
            self.assertIn('packages/ui/CHANGELOG.md:1', errors[0])

    def test_package_readme_rejects_excluded_subdirectory(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            ui = root / 'packages' / 'ui'
            ui.mkdir(parents=True)
            (ui / 'README.md').write_text('[fixture](test/fixture.md)\n')
            errors = mod.find_errors(root)
            self.assertEqual(len(errors), 1, errors)
            self.assertIn('test/', errors[0])

    def test_package_markdown_in_excluded_subdirectory_is_ignored(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            ui = root / 'packages' / 'ui'
            (ui / 'test').mkdir(parents=True)
            (root / 'docs').mkdir()
            (root / 'docs' / 'ui.md').write_text('ui')
            (ui / 'test' / 'README.md').write_text('[module](../../../docs/ui.md)\n')
            self.assertEqual(mod.find_errors(root), [])

    def test_package_readme_cannot_escape_package_directory(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            ui = root / 'packages' / 'ui'
            ui.mkdir(parents=True)
            (root / 'docs').mkdir()
            (root / 'docs' / 'ui.md').write_text('ui')
            (ui / 'README.md').write_text('[module](../../docs/ui.md)\n')
            errors = mod.find_errors(root)
            self.assertEqual(len(errors), 1, errors)
            self.assertIn('packages/ui/README.md', errors[0])

    def test_package_readme_allows_files_inside_package(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            ui = root / 'packages' / 'ui'
            (ui / 'example').mkdir(parents=True)
            (ui / 'example' / 'README.md').write_text('example')
            (ui / 'README.md').write_text('[example](example/README.md)\n')
            self.assertEqual(mod.find_errors(root), [])

    def test_pubignore_top_level_entries_are_covered(self):
        """新增 .pubignore 排除项时，链接检查的常量不能落后。"""
        for raw in (ROOT / '.pubignore').read_text().splitlines():
            entry = raw.strip()
            if not entry or entry.startswith('#') or '*' in entry:
                continue
            if entry.endswith('/'):
                self.assertIn(entry.rstrip('/'), mod.ROOT_EXCLUDED_DIRS)
            else:
                self.assertTrue(
                    entry in mod.ROOT_EXCLUDED_FILES or entry in mod.ROOT_EXCLUDED_DIRS,
                    f'.pubignore 的 {entry} 没有同步到 check_published_links 常量',
                )


if __name__ == '__main__':
    unittest.main()
