import pathlib
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from check_teaching_coverage import check_package


class TeachingCoverageTest(unittest.TestCase):
    def test_missing_template_entry_is_reported(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / 'docs/agents').mkdir(parents=True)
            (root / 'docs/agents/ui.md').write_text('WText\n')
            (root / 'packages/cli/templates/agents/zh').mkdir(parents=True)
            (root / 'packages/cli/templates/agents/en').mkdir(parents=True)
            (root / 'packages/cli/templates/agents/zh/ui.md').write_text('WText\n')
            (root / 'packages/cli/templates/agents/en/ui.md').write_text('WText\n')
            (root / 'packages/ui').mkdir(parents=True)
            (root / 'packages/ui/README.md').write_text('WText\n')
            (root / 'packages/ui/example/lib').mkdir(parents=True)
            (root / 'packages/ui/example/lib/a.dart').write_text('WText\n')
            errors = check_package(root, 'ui', ['WText', 'WImage'])
            self.assertEqual(len(errors), 1)
            self.assertIn('WImage', errors[0])

    def test_all_carriers_present_passes(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            for rel in [
                'docs/agents/ui.md',
                'packages/cli/templates/agents/zh/ui.md',
                'packages/cli/templates/agents/en/ui.md',
                'packages/ui/README.md',
                'packages/ui/example/lib/a.dart',
            ]:
                path = root / rel
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text('WText WImage\n')
            self.assertEqual(check_package(root, 'ui', ['WText', 'WImage']), [])

    def test_missing_example_directory_is_not_required(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            for rel in [
                'docs/agents/app.md',
                'packages/cli/templates/agents/zh/app.md',
                'packages/cli/templates/agents/en/app.md',
                'packages/app/README.md',
            ]:
                path = root / rel
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text('WAppPlugin\n')
            self.assertEqual(check_package(root, 'app', ['WAppPlugin']), [])

    def test_doc_alias_uses_shared_rule_page(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            for rel in [
                'docs/agents/app.md',
                'packages/cli/templates/agents/zh/app.md',
                'packages/cli/templates/agents/en/app.md',
                'packages/app_getx/README.md',
            ]:
                path = root / rel
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text('WApp WAppOptions\n')
            self.assertEqual(
                check_package(root, 'app_getx', ['WApp', 'WAppOptions'], 'app'),
                [],
            )


if __name__ == '__main__':
    unittest.main()
