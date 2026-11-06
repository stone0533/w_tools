import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from ci_matrix import path_filter_errors


def workflow(filters: str) -> dict:
    return {
        'jobs': {
            'changes': {
                'steps': [
                    {'id': 'checkout', 'uses': 'actions/checkout@v7'},
                    {'id': 'filter', 'with': {'filters': filters}},
                ],
            },
        },
    }


class PathFilterTest(unittest.TestCase):
    def test_positive_only_filters_pass(self):
        self.assertEqual(
            path_filter_errors(
                workflow(
                    'code:\n'
                    "  - 'packages/**/*.dart'\n"
                    "  - 'packages/cli/templates/**'\n"
                    'static:\n'
                    "  - 'scripts/**/*.py'\n"
                )
            ),
            [],
        )

    def test_exclusion_rule_fails(self):
        # some-with-excludes 没有「再包含」：`!**/*.md` 会连 templates/**/*.md 一起挡掉。
        errors = path_filter_errors(
            workflow(
                'code:\n'
                "  - 'packages/**'\n"
                "  - '!packages/**/*.md'\n"
                "  - 'packages/cli/templates/**'\n"
            )
        )
        self.assertEqual(len(errors), 1)
        self.assertIn('code', errors[0])
        self.assertIn('!packages/**/*.md', errors[0])

    def test_missing_filter_fails(self):
        errors = path_filter_errors({'jobs': {'changes': {'steps': []}}})
        self.assertTrue(errors)
        self.assertIn('找不到', errors[0])


if __name__ == '__main__':
    unittest.main()
