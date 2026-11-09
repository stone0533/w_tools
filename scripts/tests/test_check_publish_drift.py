from __future__ import annotations

import pathlib
import sys
import tempfile
import textwrap
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from check_publish_drift import (  # noqa: E402
    classify_file,
    compare_trees,
    exit_code_for,
    strip_dart,
    verdict,
)


class StripDartTest(unittest.TestCase):
    def test_removes_line_and_block_comments(self):
        text = 'void main() {\n  // 注释\n  run(); /* 块注释 */\n}\n'
        stripped = strip_dart(text)
        self.assertNotIn('注释', stripped)
        self.assertIn('void main()', stripped)
        self.assertIn('run();', stripped)

    def test_keeps_double_slash_inside_strings(self):
        old = "const url = 'https://example.com/a';"
        new = "const url = 'https://example.com/b';"
        self.assertNotEqual(strip_dart(old), strip_dart(new))

    def test_keeps_block_comment_markers_inside_strings(self):
        old = "const s = '/* 不是注释 */'; var a = 1;"
        new = "const s = '/* 不是注释 */'; var a = 2;"
        self.assertNotEqual(strip_dart(old), strip_dart(new))


class ClassifyFileTest(unittest.TestCase):
    def test_identical_file_is_not_a_change(self):
        text = 'void main() {}\n'
        self.assertIsNone(classify_file('lib/a.dart', text, text))

    def test_comment_only_dart_change_is_comment_drift(self):
        old = 'void main() {}\n'
        new = '/// 新增说明\nvoid main() {}\n'
        self.assertEqual(classify_file('lib/a.dart', old, new), 'comment')

    def test_code_dart_change_is_code_drift(self):
        old = 'void main() { run(1); }\n'
        new = 'void main() { run(2); }\n'
        self.assertEqual(classify_file('lib/a.dart', old, new), 'code')

    def test_whitespace_only_dart_change_is_comment_drift(self):
        old = 'void main() {\n  run();\n}\n'
        new = 'void main() {\n\n  run();\n}\n'
        self.assertEqual(classify_file('lib/a.dart', old, new), 'comment')

    def test_markdown_change_is_docs_drift(self):
        self.assertEqual(classify_file('README.md', 'a\n', 'b\n'), 'docs')
        self.assertEqual(classify_file('CHANGELOG.md', 'a\n', 'b\n'), 'docs')

    def test_pubspec_change_is_code_drift(self):
        self.assertEqual(
            classify_file('pubspec.yaml', 'version: 1.0.0\n', 'version: 1.0.1\n'),
            'code',
        )

    def test_non_dart_identical_is_not_a_change(self):
        self.assertIsNone(classify_file('README.md', 'same\n', 'same\n'))


class CompareTreesTest(unittest.TestCase):
    def _tree(self, root: pathlib.Path, files: dict[str, str]) -> pathlib.Path:
        for rel, content in files.items():
            path = root / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
        return root

    def test_returns_empty_when_trees_match(self):
        with tempfile.TemporaryDirectory() as a, tempfile.TemporaryDirectory() as b:
            files = {'pubspec.yaml': 'name: x\n', 'lib/a.dart': 'void main() {}\n'}
            old = self._tree(pathlib.Path(a), files)
            new = self._tree(pathlib.Path(b), files)
            self.assertEqual(compare_trees(old, new), {})

    def test_reports_comment_and_code_changes(self):
        with tempfile.TemporaryDirectory() as a, tempfile.TemporaryDirectory() as b:
            old = self._tree(
                pathlib.Path(a),
                {
                    'pubspec.yaml': 'name: x\nversion: 1.0.0\n',
                    'lib/a.dart': 'void main() { run(1); }\n',
                    'README.md': 'old\n',
                },
            )
            new = self._tree(
                pathlib.Path(b),
                {
                    'pubspec.yaml': 'name: x\nversion: 1.0.1\n',
                    'lib/a.dart': '/// doc\nvoid main() { run(1); }\n',
                    'README.md': 'new\n',
                },
            )
            changes = compare_trees(old, new)
            self.assertEqual(changes['lib/a.dart'], 'comment')
            self.assertEqual(changes['README.md'], 'docs')
            self.assertEqual(changes['pubspec.yaml'], 'code')
            self.assertEqual(verdict(changes), 'code')

    def test_missing_or_new_file_is_code_drift(self):
        with tempfile.TemporaryDirectory() as a, tempfile.TemporaryDirectory() as b:
            old = self._tree(pathlib.Path(a), {'pubspec.yaml': 'name: x\n'})
            new = self._tree(
                pathlib.Path(b),
                {'pubspec.yaml': 'name: x\n', 'lib/new.dart': 'void main() {}\n'},
            )
            self.assertEqual(compare_trees(old, new), {'lib/new.dart': 'code'})

    def test_ignores_paths_outside_compare_roots(self):
        with tempfile.TemporaryDirectory() as a, tempfile.TemporaryDirectory() as b:
            old = self._tree(pathlib.Path(a), {'test/a_test.dart': 'old\n'})
            new = self._tree(pathlib.Path(b), {'test/a_test.dart': 'new\n'})
            self.assertEqual(compare_trees(old, new), {})


class ExitCodeTest(unittest.TestCase):
    def test_no_drift_passes(self):
        self.assertEqual(exit_code_for({}, check=True), 0)

    def test_comment_drift_passes_even_with_check(self):
        self.assertEqual(exit_code_for({'lib/a.dart': 'comment'}, check=True), 0)

    def test_code_drift_fails_with_check(self):
        self.assertEqual(exit_code_for({'lib/a.dart': 'code'}, check=True), 1)

    def test_code_drift_passes_without_check(self):
        self.assertEqual(exit_code_for({'lib/a.dart': 'code'}, check=False), 0)

    def test_docs_drift_passes_even_with_check(self):
        self.assertEqual(exit_code_for({'README.md': 'docs'}, check=True), 0)


class CompareRootsTest(unittest.TestCase):
    def test_package_roots(self):
        from check_publish_drift import COMPARE_ROOTS

        for required in ('pubspec.yaml', 'README.md', 'CHANGELOG.md', 'lib', 'example'):
            self.assertIn(required, COMPARE_ROOTS)


if __name__ == '__main__':
    unittest.main()


class NormalizePubspecTest(unittest.TestCase):
    def test_removes_workspace_block_and_resolution(self):
        from check_publish_drift import normalize_pubspec

        text = (
            'name: w_tools_core\n'
            'workspace:\n'
            '  - packages/core\n'
            '  - packages/ui\n'
            'resolution: workspace\n'
            'environment:\n'
            '  sdk: ^3.10.0\n'
        )
        out = normalize_pubspec(text)
        self.assertNotIn('workspace:', out)
        self.assertNotIn('resolution:', out)
        self.assertIn('name: w_tools_core', out)
        self.assertIn('sdk: ^3.10.0', out)


class ExclusionsTest(unittest.TestCase):
    def test_ignores_publish_excluded_paths(self):
        with tempfile.TemporaryDirectory() as root:
            base = pathlib.Path(root)
            (base / 'example/.dart_tool').mkdir(parents=True)
            (base / 'example/build').mkdir(parents=True)
            (base / 'example/test').mkdir(parents=True)
            (base / 'lib').mkdir(parents=True)
            files = {
                'example/.dart_tool/x.json': '{}',
                'example/build/y.bin': 'x',
                'example/test/a_test.dart': 'void main() {}',
                'example/pubspec.lock': 'lock',
                'lib/a.dart': 'void main() {}',
            }
            for rel, content in files.items():
                path = base / rel
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content)
            other = pathlib.Path(tempfile.mkdtemp())
            self.addCleanup(lambda: __import__('shutil').rmtree(other, ignore_errors=True))
            changes = compare_trees(base, other)
            self.assertEqual(set(changes), {'lib/a.dart'})
            self.assertEqual(changes['lib/a.dart'], 'code')


class BinaryTest(unittest.TestCase):
    def test_binary_difference_is_code_drift(self):
        with tempfile.TemporaryDirectory() as a, tempfile.TemporaryDirectory() as b:
            for root, payload in ((a, b'\x89PNG\x00'), (b, b'\x89PNG\x01')):
                path = pathlib.Path(root) / 'lib' / 'x.bin'
                path.parent.mkdir(parents=True)
                path.write_bytes(payload)
            self.assertEqual(compare_trees(pathlib.Path(a), pathlib.Path(b)), {'lib/x.bin': 'code'})
