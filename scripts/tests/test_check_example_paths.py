import pathlib
import sys
import tempfile
import textwrap
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

import check_example_paths as mod


class ExamplePathsTest(unittest.TestCase):
    def test_path_inside_package_is_allowed(self):
        with tempfile.TemporaryDirectory() as temp:
            package = pathlib.Path(temp) / 'packages' / 'demo'
            example = package / 'example'
            example.mkdir(parents=True)
            (example / 'pubspec.yaml').write_text(
                textwrap.dedent(
                    '''\
                    name: demo_example
                    publish_to: none
                    dependencies:
                      w_tools_demo:
                        path: ../
                    ''',
                ),
            )
            self.assertEqual(mod.example_errors(example, package), [])

    def test_path_outside_package_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            package = pathlib.Path(temp) / 'packages' / 'demo'
            example = package / 'example'
            example.mkdir(parents=True)
            (example / 'pubspec.yaml').write_text(
                textwrap.dedent(
                    '''\
                    name: demo_example
                    publish_to: none
                    dependencies:
                      sibling:
                        path: ../../sibling
                    ''',
                ),
            )
            errors = mod.example_errors(example, package)
            self.assertEqual(len(errors), 1)
            self.assertIn('包外路径', errors[0])

    def test_dependency_overrides_are_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            package = pathlib.Path(temp) / 'packages' / 'demo'
            example = package / 'example'
            example.mkdir(parents=True)
            (example / 'pubspec.yaml').write_text(
                textwrap.dedent(
                    '''\
                    name: demo_example
                    publish_to: none
                    dependency_overrides:
                      sibling:
                        path: ../../sibling
                    ''',
                ),
            )
            errors = mod.example_errors(example, package)
            self.assertEqual(len(errors), 1)
            self.assertIn('dependency_overrides', errors[0])

    def test_root_example_parent_path_is_allowed(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            example = root / 'example'
            example.mkdir(parents=True)
            (example / 'pubspec.yaml').write_text(
                textwrap.dedent(
                    '''\
                    name: root_example
                    publish_to: none
                    dependencies:
                      w_tools:
                        path: ../
                    ''',
                ),
            )
            self.assertEqual(mod.example_errors(example, root), [])

    def test_pubspec_overrides_is_not_checked(self):
        # 本地专用文件不随包发布，不参与检查。
        with tempfile.TemporaryDirectory() as temp:
            package = pathlib.Path(temp) / 'packages' / 'demo'
            example = package / 'example'
            example.mkdir(parents=True)
            (example / 'pubspec.yaml').write_text('name: demo_example\n')
            (example / 'pubspec_overrides.yaml').write_text(
                'dependency_overrides:\n  sibling:\n    path: ../../sibling\n',
            )
            self.assertEqual(mod.example_errors(example, package), [])


if __name__ == '__main__':
    unittest.main()
