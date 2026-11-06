import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from check_catalog_anchors import slug, validate


class CatalogAnchorTest(unittest.TestCase):
    def test_slug_matches_github_heading_rules(self):
        self.assertEqual(slug('### WNotificationListener'), 'wnotificationlistener')
        self.assertEqual(slug('### WColorExtension（Color 扩展）'), 'wcolorextensioncolor-扩展')

    def test_missing_anchor_is_reported(self):
        anchors = {'ui_module.md': {'wbutton'}, 'form_module.md': {'wform'}}
        entries = [
            {'name': 'WButton', 'package': 'w_tools_ui', 'docsAnchor': 'wbutton'},
            {'name': 'WImage', 'package': 'w_tools_ui', 'docsAnchor': 'wimage'},
        ]
        errors = validate(entries, anchors)
        self.assertEqual(len(errors), 1)
        self.assertIn('WImage', errors[0])

    def test_anchor_in_wrong_module_is_reported(self):
        anchors = {'ui_module.md': {'wbutton'}, 'form_module.md': {'wbutton'}}
        errors = validate(
            [{'name': 'WButton', 'package': 'w_tools_form', 'docsAnchor': 'wbutton'}],
            anchors,
        )
        self.assertEqual(errors, [])

        errors = validate(
            [{'name': 'WButton', 'package': 'w_tools_ui', 'docsAnchor': 'wform'}],
            anchors,
        )
        self.assertEqual(len(errors), 1)
        self.assertIn('ui_module.md', errors[0])

    def test_empty_anchor_is_ignored(self):
        # docsAnchor 可选；UI / form 的完整性由 CLI 测试单独保证。
        errors = validate([{'name': 'WButton', 'docsAnchor': ''}], {'ui_module.md': {'wbutton'}})
        self.assertEqual(errors, [])


if __name__ == '__main__':
    unittest.main()
