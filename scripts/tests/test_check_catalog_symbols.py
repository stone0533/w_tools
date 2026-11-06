import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from check_catalog_symbols import extract_symbols, validate


class CatalogSymbolsTest(unittest.TestCase):
    def test_extracts_type_and_member(self):
        self.assertEqual(
            extract_symbols('WImage.source(...) + `WButtonStyle.filled`'),
            {'WImage.source', 'WButtonStyle.filled'},
        )

    def test_missing_type_is_reported(self):
        errors = validate(
            [{'name': 'WImage', 'package': 'w_tools_ui', 'usage': 'WMissing()'}],
            {'WImage': 'class WImage {}'},
        )
        self.assertEqual(len(errors), 1)
        self.assertIn('WMissing', errors[0])

    def test_missing_member_is_reported(self):
        errors = validate(
            [{'name': 'WImage', 'package': 'w_tools_ui', 'usage': 'WImage.config(...)'}],
            {'WImage': 'class WImage { void source() {} }'},
        )
        self.assertEqual(len(errors), 1)
        self.assertIn('WImage.config', errors[0])


if __name__ == '__main__':
    unittest.main()
