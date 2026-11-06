import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

import yaml

from ci_matrix import (
    path_filter_errors,
    required_filter_errors,
    required_job_errors,
)

ROOT = pathlib.Path(__file__).resolve().parents[2]


def workflow(filters: str) -> dict:
    return {
        'jobs': {
            'changes': {
                'steps': [
                    {'id': 'checkout', 'uses': 'actions/checkout@v7'},
                    {
                        'id': 'filter',
                        'with': {
                            'predicate-quantifier': 'some-with-excludes',
                            'filters': filters,
                        },
                    },
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


def load_ci() -> dict:
    return yaml.safe_load((ROOT / '.github/workflows/ci.yml').read_text())


def filter_step(workflow: dict) -> dict:
    for step in workflow['jobs']['changes']['steps']:
        if step.get('id') == 'filter':
            return step
    raise AssertionError('ci.yml 没有 filter step')


class RequiredWiringTest(unittest.TestCase):
    def test_actual_ci_passes(self):
        workflow = load_ci()
        self.assertEqual(required_filter_errors(workflow), [])
        self.assertEqual(required_job_errors(workflow), [])

    def test_missing_critical_positive_filter_fails(self):
        workflow = load_ci()
        step = filter_step(workflow)
        step['with']['filters'] = step['with']['filters'].replace(
            "- 'packages/**/*.dart'", ''
        )
        errors = required_filter_errors(workflow)
        self.assertTrue(errors)
        self.assertIn('packages/**/*.dart', errors[0])

    def test_wrong_quantifier_fails(self):
        workflow = load_ci()
        filter_step(workflow)['with']['predicate-quantifier'] = 'some'
        errors = required_filter_errors(workflow)
        self.assertTrue(errors)
        self.assertIn('some-with-excludes', errors[0])

    def test_required_needs_missing_docs_fails(self):
        workflow = load_ci()
        needs = workflow['jobs']['required']['needs']
        needs.remove('docs')
        errors = required_job_errors(workflow)
        self.assertTrue(errors)
        self.assertIn('docs', errors[0])

    def test_docs_job_must_keep_meta_checks(self):
        workflow = load_ci()
        workflow['jobs']['docs']['steps'] = [
            step for step in workflow['jobs']['docs']['steps']
            if 'ci_matrix.py --check' not in str(step.get('run') or '')
        ]
        errors = required_job_errors(workflow)
        self.assertTrue(errors)
        self.assertTrue(any('ci_matrix.py --check' in error for error in errors))


if __name__ == '__main__':
    unittest.main()
