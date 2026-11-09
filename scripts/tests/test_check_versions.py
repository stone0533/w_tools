import pathlib
import sys
import tempfile
import textwrap
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

import check_versions as mod


def _write(path: pathlib.Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(textwrap.dedent(text))


class VersionsTest(unittest.TestCase):
    def _repo(self, temp: str, *, root='^1.0.0', map_constraint='^1.0.0', cli='^1.0.0',
              device='^1.0.0') -> pathlib.Path:
        root_dir = pathlib.Path(temp)
        _write(
            root_dir / 'scripts' / 'packages.manifest',
            '''\
            w_tools_core|packages/core|flutter|root|-
            w_tools_cli|packages/cli|dart|-|-
            w_tools_device|packages/device|dart|-|-
            ''',
        )
        _write(
            root_dir / 'pubspec.yaml',
            f'''\
            name: w_tools
            version: 9.0.0
            dependencies:
              w_tools_core: {root}
            ''',
        )
        _write(root_dir / 'packages' / 'core' / 'pubspec.yaml', 'name: w_tools_core\nversion: 1.0.0\n')
        _write(root_dir / 'packages' / 'cli' / 'pubspec.yaml', 'name: w_tools_cli\nversion: 1.0.0\n')
        _write(root_dir / 'packages' / 'device' / 'pubspec.yaml', 'name: w_tools_device\nversion: 1.0.0\n')
        _write(
            root_dir / 'packages' / 'cli' / 'lib' / 'src' / 'init' / 'versions.dart',
            f'''\
            const subpackageConstraints = <String, String>{{
              'w_tools_core': '{map_constraint}',
            }};

            const cliConstraint = '{cli}';
            const wToolsDeviceConstraint = '{device}';
            ''',
        )
        return root_dir

    def test_valid_repo_passes(self):
        with tempfile.TemporaryDirectory() as temp:
            self.assertEqual(mod.constraint_errors(self._repo(temp)), [])

    def test_root_constraint_must_equal_current_version(self):
        with tempfile.TemporaryDirectory() as temp:
            errors = mod.constraint_errors(self._repo(temp, root='^0.9.0'))
            self.assertEqual(len(errors), 1)
            self.assertIn('根 pubspec.yaml: w_tools_core', errors[0])

    def test_versions_dart_map_must_equal_current_version(self):
        with tempfile.TemporaryDirectory() as temp:
            errors = mod.constraint_errors(self._repo(temp, map_constraint='^0.9.0'))
            self.assertEqual(len(errors), 1)
            self.assertIn('versions.dart: w_tools_core', errors[0])

    def test_cli_self_constraint_is_checked(self):
        # 1.17.0 实际踩过：只有 CLI 自己的约束没有测试读 pubspec。
        with tempfile.TemporaryDirectory() as temp:
            errors = mod.constraint_errors(self._repo(temp, cli='^0.9.0'))
            self.assertEqual(len(errors), 1)
            self.assertIn('cliConstraint', errors[0])

    def test_device_constraint_is_checked(self):
        with tempfile.TemporaryDirectory() as temp:
            errors = mod.constraint_errors(self._repo(temp, device='^0.9.0'))
            self.assertEqual(len(errors), 1)
            self.assertIn('wToolsDeviceConstraint', errors[0])


if __name__ == '__main__':
    unittest.main()
