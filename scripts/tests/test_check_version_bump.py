import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from check_version_bump import _parse_version, diff_surfaces


class VersionBumpTest(unittest.TestCase):
    def test_added_symbol_is_a_change(self):
        changes = diff_surfaces({'WThing': 'class'}, {'WThing': 'class', 'WNew': 'class'})
        self.assertIn('WNew', changes)

    def test_removed_symbol_is_a_change(self):
        changes = diff_surfaces({'WThing': 'class'}, {})
        self.assertIn('WThing', changes)

    def test_signature_change_is_a_change(self):
        changes = diff_surfaces(
            {'WThing.run': 'void (int value)'},
            {'WThing.run': 'void (String value)'},
        )
        self.assertIn('WThing.run', changes)

    def test_identical_surfaces_have_no_changes(self):
        surface = {'WThing': 'class', 'WThing.run': 'void (int value)'}
        self.assertEqual(diff_surfaces(surface, dict(surface)), {})

    def test_parse_version(self):
        self.assertEqual(_parse_version('name: w_tools_ui\nversion: 7.0.0\n'), '7.0.0')
        self.assertIsNone(_parse_version('name: w_tools_ui\n'))


if __name__ == '__main__':
    unittest.main()
