import pathlib
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from check_test_imports import check_package


class TestImportBoundaryTest(unittest.TestCase):
    def test_public_test_importing_src_is_reported(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            test = root / 'test'
            (test).mkdir()
            (test / 'a_test.dart').write_text(
                "import 'package:w_tools_ui/src/a.dart';\n"
            )
            errors = check_package(root, 'ui')
            self.assertEqual(len(errors), 1)
            self.assertIn('a_test.dart', errors[0])

    def test_integration_test_importing_src_is_reported(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            integration = root / 'integration_test'
            integration.mkdir()
            (integration / 'flow_test.dart').write_text(
                "import 'package:w_tools_ui/src/a.dart';\n"
            )
            errors = check_package(root, 'ui')
            self.assertEqual(len(errors), 1)
            self.assertIn('integration_test', errors[0])

    def test_internal_test_importing_src_is_allowed(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            test = root / 'test' / 'internal'
            test.mkdir(parents=True)
            (test / 'a_test.dart').write_text(
                "import 'package:w_tools_ui/src/a.dart';\n"
            )
            self.assertEqual(check_package(root, 'ui'), [])


if __name__ == '__main__':
    unittest.main()
