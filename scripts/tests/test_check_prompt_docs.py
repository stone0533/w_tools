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
        text = '## 1. 场景选择\n\nA / X\n\n## A. a\n'
        errors = mod.scenario_errors(text, 'x')
        self.assertTrue(errors)
        self.assertTrue(any('X' in error for error in errors))

    def test_missing_selection_section(self):
        self.assertTrue(mod.scenario_errors('## A. a\n', 'x'))

    def test_duplicate_scenario_heading_is_reported(self):
        text = '## 1. 场景选择\n\nA\n\n## A. one\n\n## A. two\n'
        errors = mod.scenario_errors(text, 'x')
        self.assertTrue(any('重复标题' in error for error in errors))

    def test_orphan_scenario_heading_is_reported(self):
        text = '## 1. 场景选择\n\nA\n\n## A. one\n\n## O. orphan\n'
        errors = mod.scenario_errors(text, 'x')
        self.assertTrue(any('O' in error and '没有列出' in error for error in errors))


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

    def test_unknown_subcommand_is_reported(self):
        errors = mod.cli_flag_errors('w_tools_cli:w_tools unknown --x\n', 'x')
        self.assertTrue(errors)
        self.assertIn('未知的 w_tools 子命令', errors[0])

    def test_bare_w_tools_is_not_a_subcommand(self):
        # `w_tools_cli:w_tools`（后面没有子命令）不能被回退匹配成子命令 `w`。
        self.assertEqual(mod.cli_flag_errors('dart run w_tools_cli:w_tools\n', 'x'), [])

    def test_flags_on_continuation_line_are_checked(self):
        text = (
            'dart run w_tools_cli:w_tools feedback submit \\\n'
            '  --package=ui --nope\n'
        )
        errors = mod.cli_flag_errors(text, 'x')
        self.assertTrue(errors)
        self.assertIn('--nope', errors[0])


class PathTest(unittest.TestCase):
    def test_existing_docs_path_passes(self):
        self.assertEqual(mod.path_exists_errors('先读 docs/agents/form.md\n', 'x'), [])

    def test_missing_docs_path_is_reported(self):
        errors = mod.path_exists_errors('先读 docs/agents/not-a-real-file.md\n', 'x')
        self.assertTrue(errors)
        self.assertIn('docs/agents/not-a-real-file.md', errors[0])

    def test_template_paths_are_ignored(self):
        self.assertEqual(
            mod.path_exists_errors('docs/agents/<pkg>.md / docs/modules/<pkg>_module.md\n', 'x'),
            [],
        )


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


class DartFileTest(unittest.TestCase):
    def test_existing_generator_and_test_pass(self):
        text = (
            'cd packages/cli\n'
            'dart run tool/gen_catalog.dart\n'
            'dart test test/internal/ai_contract_test.dart\n'
        )
        self.assertEqual(mod.dart_file_errors(text, 'x'), [])

    def test_missing_generator_is_reported(self):
        errors = mod.dart_file_errors('dart run tool/nope.dart\n', 'x')
        self.assertTrue(errors)
        self.assertIn('packages/cli/tool/nope.dart', errors[0])

    def test_missing_test_file_is_reported(self):
        errors = mod.dart_file_errors('dart test test/nope_test.dart\n', 'x')
        self.assertTrue(errors)
        self.assertIn('packages/cli/test/nope_test.dart', errors[0])


class ScenarioHeadingTest(unittest.TestCase):
    def test_plain_capitalised_heading_is_not_a_scenario(self):
        # `## A filled-in example` 这类普通标题不能被当成场景 A。
        text = '## 1. 场景选择\n\nA\n\n## A. a\n\n## A filled-in example\n'
        self.assertEqual(mod.scenario_errors(text, 'x'), [])

    def test_english_selection_heading_is_accepted(self):
        text = (
            '## 1. Scenario selection\n\nA-1 -> A-2\n\n'
            '## A. a\n\n### A-1. a1\n\n### A-2. a2\n'
        )
        self.assertEqual(mod.scenario_errors(text, 'x'), [])

    def test_sub_scenario_must_have_heading(self):
        text = '## 1. 场景选择\n\nA-1 / A-2\n\n## A. a\n\n### A-1. a1\n'
        errors = mod.scenario_errors(text, 'x')
        self.assertTrue(any('A-2' in error for error in errors))


class ConsumerTemplateTest(unittest.TestCase):
    """`init` 生成的消费方提示词模板必须和本手册一样过严格检查。"""

    def test_templates_are_registered(self):
        names = [path.name for path in mod.consumer_prompt_docs()]
        self.assertIn('consumer-prompts.md', names)
        self.assertIn('consumer-prompts.en.md', names)

    def test_consumer_templates_pass_strict_checks(self):
        for path in mod.consumer_prompt_docs():
            self.assertEqual(mod.strict_errors(path), [], msg=str(path))

    def test_placeholder_with_space_escapes_validation(self):
        # 带空格的占位符不会被 placeholder_errors 匹配，所以模板里一律不许写空格。
        text = '| `<a>` | x |\n\n<接口 / 登录流程>\n'
        self.assertEqual(mod.placeholder_errors(text, 'x'), [])

    def test_undefined_placeholder_in_template_is_reported(self):
        text = '| `<pkg>` | 包目录名 | `form` |\n\n任务：实现 <页面>。\n'
        errors = mod.placeholder_errors(text, 'x')
        self.assertTrue(any('<页面>' in error for error in errors))


if __name__ == '__main__':
    unittest.main()
