import pathlib
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from check_deprecations import check_file, find_remove_in, parse_version


class FindRemoveInTest(unittest.TestCase):
    def test_adjacent_deprecations_do_not_borrow(self):
        lines = [
            '/// remove-in: 4.0.0',
            '@Deprecated("use a2")',
            'void a() {}',
            '',
            '@Deprecated("use b2")',
            'void b() {}',
        ]
        self.assertEqual(find_remove_in(lines, 1), (4, 0, 0))
        self.assertIsNone(find_remove_in(lines, 4))

    def test_blank_line_breaks_the_block(self):
        lines = [
            '/// remove-in: 4.0.0',
            '',
            '@Deprecated("x")',
            'void x() {}',
        ]
        self.assertIsNone(find_remove_in(lines, 2))

    def test_comment_and_annotation_block_is_followed_upwards(self):
        lines = [
            '/// 说明',
            '/// remove-in: 5.0.0',
            '@override',
            '@Deprecated("x")',
            'void x() {}',
        ]
        self.assertEqual(find_remove_in(lines, 3), (5, 0, 0))

    def test_code_line_breaks_the_block(self):
        lines = [
            '/// remove-in: 4.0.0',
            'final int unrelated = 1;',
            '@Deprecated("x")',
            'void x() {}',
        ]
        self.assertIsNone(find_remove_in(lines, 2))

    def test_parse_version_rejects_non_semver(self):
        self.assertEqual(parse_version('3.1.2'), (3, 1, 2))
        self.assertIsNone(parse_version('v3.1.2'))


class CheckFileTest(unittest.TestCase):
    def _check(self, source: str, version=(3, 0, 0)) -> list[str]:
        import check_deprecations as mod

        with tempfile.TemporaryDirectory() as temp:
            path = pathlib.Path(temp) / 'a.dart'
            path.write_text(source)
            old_root = mod.root
            mod.root = path.parent
            errors: list[str] = []
            try:
                check_file(path, version, errors)
            finally:
                mod.root = old_root
            return errors

    def test_missing_remove_in_is_reported(self):
        errors = self._check(
            'class WDemo {\n'
            '  /// 说明\n'
            '  @Deprecated("use x")\n'
            '  void a() {}\n'
            '}\n'
        )
        self.assertEqual(len(errors), 1)
        self.assertIn('缺 remove-in', errors[0])

    def test_expired_remove_in_is_reported(self):
        errors = self._check(
            'class WDemo {\n'
            '  /// remove-in: 2.0.0\n'
            '  @Deprecated("use x")\n'
            '  void a() {}\n'
            '}\n'
        )
        self.assertEqual(len(errors), 1)
        self.assertIn('已到期', errors[0])


if __name__ == '__main__':
    unittest.main()
