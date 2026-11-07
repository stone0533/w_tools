import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

import check_prompt_docs as mod


class ScenarioTest(unittest.TestCase):
    def test_n_scenario_is_accepted(self):
        text = '## 1. 场景选择\n\nA / N / N-1\n\n## A. a\n\n## N. n\n\n### N-1. n1\n'
        self.assertEqual(mod.scenario_errors(text, 'x'), [])

    def test_unknown_scenario_is_reported(self):
        text = '## 1. 场景选择\n\nX\n\n## A. a\n'
        errors = mod.scenario_errors(text, 'x')
        self.assertTrue(errors)
        self.assertIn('X', errors[0])

    def test_missing_selection_section(self):
        self.assertTrue(mod.scenario_errors('## A. a\n', 'x'))


class CliFlagTest(unittest.TestCase):
    def test_valid_list_flags(self):
        text = 'dart run w_tools_cli:w_tools list --package=ui --format=prompt\n'
        self.assertEqual(mod.cli_flag_errors(text, 'x'), [])

    def test_unknown_flag_is_reported(self):
        text = 'dart run w_tools_cli:w_tools list --nope\n'
        errors = mod.cli_flag_errors(text, 'x')
        self.assertEqual(len(errors), 1)
        self.assertIn('--nope', errors[0])

    def test_init_feature_flags_are_known(self):
        text = 'dart run w_tools_cli:w_tools init --no-async --map --force\n'
        self.assertEqual(mod.cli_flag_errors(text, 'x'), [])

    def test_unknown_subcommand_is_skipped(self):
        self.assertEqual(mod.cli_flag_errors('w_tools_cli:w_tools unknown --x\n', 'x'), [])


class PlaceholderTest(unittest.TestCase):
    def test_runner_and_pkg_are_allowed(self):
        text = '| `<pkg>` | 包目录名 | `form` |\n\n<runner> test / packages/<pkg>\n'
        self.assertEqual(mod.placeholder_errors(text, 'x'), [])

    def test_undefined_placeholder_is_reported(self):
        text = '| `<pkg>` | 包目录名 | `form` |\n\n<foo>\n'
        errors = mod.placeholder_errors(text, 'x')
        self.assertTrue(any('<foo>' in error for error in errors))


class CwdTest(unittest.TestCase):
    def test_generator_requires_packages_cli(self):
        text = '```\ndart run tool/gen_catalog.dart\n```\n'
        self.assertTrue(mod.cwd_errors(text, 'x'))

    def test_generator_after_cd_is_ok(self):
        text = '```\ncd packages/cli\ndart run tool/gen_catalog.dart\n```\n'
        self.assertEqual(mod.cwd_errors(text, 'x'), [])


if __name__ == '__main__':
    unittest.main()
