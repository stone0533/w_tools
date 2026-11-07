import pathlib
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

import yaml

from ci_matrix import (
    gate_step_errors,
    matrix_emit_errors,
    package_step_errors,
    path_filter_errors,
    pr_template_errors,
    release_status_workflow_errors,
    required_filter_errors,
    required_job_errors,
    wiring_errors,
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


class SemanticWiringTest(unittest.TestCase):
    """meta 门禁要能发现「文本还在、执行语义被改掉」的接线回归。"""

    def test_actual_ci_passes(self):
        workflow = load_ci()
        self.assertEqual(wiring_errors(workflow), [])
        self.assertEqual(gate_step_errors(workflow), [])
        self.assertEqual(package_step_errors(workflow), [])
        self.assertEqual(matrix_emit_errors(workflow), [])
        self.assertEqual(pr_template_errors(), [])
        self.assertEqual(release_status_workflow_errors(), [])

    def test_changes_outputs_cannot_be_forced_false(self):
        workflow = load_ci()
        workflow['jobs']['changes']['outputs']['code'] = 'false'
        errors = wiring_errors(workflow)
        self.assertTrue(errors)
        self.assertIn('changes.outputs.code', errors[0])

    def test_gated_if_cannot_be_silenced(self):
        workflow = load_ci()
        workflow['jobs']['umbrella']['if'] = (
            "needs.changes.outputs.code == 'true' || needs.changes.outputs.static == 'true'"
            ' && false'
        )
        errors = wiring_errors(workflow)
        self.assertTrue(any('umbrella.if' in error for error in errors))

    def test_api_bump_if_cannot_be_silenced(self):
        workflow = load_ci()
        workflow['jobs']['api-bump']['if'] = False
        errors = wiring_errors(workflow)
        self.assertTrue(any('api-bump.if' in error for error in errors))

    def test_required_step_cannot_be_gutted(self):
        workflow = load_ci()
        workflow['jobs']['required']['steps'] = [
            {'name': 'noop', 'run': 'echo ok; exit 0'}
        ]
        errors = wiring_errors(workflow)
        self.assertTrue(any('needs.packages.result' in error for error in errors))

    def test_required_if_must_be_always(self):
        workflow = load_ci()
        workflow['jobs']['required']['if'] = False
        errors = wiring_errors(workflow)
        self.assertTrue(any('required.if' in error for error in errors))

    def test_required_step_cannot_be_disabled(self):
        workflow = load_ci()
        workflow['jobs']['required']['steps'][0]['if'] = False
        errors = gate_step_errors(workflow)
        self.assertTrue(any('required' in error and 'if' in error for error in errors))

    def test_required_step_cannot_ignore_failure(self):
        workflow = load_ci()
        workflow['jobs']['required']['steps'][0]['continue-on-error'] = True
        errors = gate_step_errors(workflow)
        self.assertTrue(
            any('required' in error and 'continue-on-error' in error for error in errors)
        )

    def test_min_sdk_gate_step_cannot_be_disabled(self):
        workflow = load_ci()
        for step in workflow['jobs']['min_sdk']['steps']:
            if 'flutter analyze' in str(step.get('run') or ''):
                step['if'] = False
        errors = gate_step_errors(workflow)
        self.assertTrue(any('min_sdk' in error for error in errors))

    def test_packages_dry_run_cannot_be_disabled(self):
        workflow = load_ci()
        for step in workflow['jobs']['packages']['steps']:
            if 'publish_package.sh' in str(step.get('run') or ''):
                step['if'] = False
        errors = gate_step_errors(workflow)
        self.assertTrue(any('packages' in error for error in errors))

    def test_umbrella_test_cannot_be_disabled(self):
        workflow = load_ci()
        for step in workflow['jobs']['umbrella']['steps']:
            if str(step.get('run') or '').strip() == 'flutter test':
                step['if'] = False
        errors = gate_step_errors(workflow)
        self.assertTrue(any('umbrella' in error for error in errors))

    def test_package_test_step_cannot_be_disabled(self):
        workflow = load_ci()
        for step in workflow['jobs']['packages']['steps']:
            if step.get('name') == 'Test (Flutter package)':
                step['if'] = False
        errors = package_step_errors(workflow)
        self.assertTrue(any('Test (Flutter package)' in error for error in errors))

    def test_package_step_if_cannot_be_altered(self):
        workflow = load_ci()
        for step in workflow['jobs']['packages']['steps']:
            if step.get('name') == 'Test (pure Dart package)':
                step['if'] = "matrix.kind == 'dart' && false"
        errors = package_step_errors(workflow)
        self.assertTrue(any('Test (pure Dart package)' in error for error in errors))

    def test_package_step_cannot_ignore_failure(self):
        workflow = load_ci()
        for step in workflow['jobs']['packages']['steps']:
            if step.get('name') == 'Test (Flutter package)':
                step['continue-on-error'] = True
        errors = package_step_errors(workflow)
        self.assertTrue(any('continue-on-error' in error for error in errors))

    def test_gate_step_cannot_be_disabled(self):
        workflow = load_ci()
        for step in workflow['jobs']['umbrella']['steps']:
            if 'scripts/preflight.sh' in str(step.get('run') or ''):
                step['if'] = False
        errors = gate_step_errors(workflow)
        self.assertTrue(errors)
        self.assertIn('if', errors[0])

    def test_gate_step_cannot_ignore_failure(self):
        workflow = load_ci()
        for step in workflow['jobs']['api-bump']['steps']:
            if 'check_version_bump.py' in str(step.get('run') or ''):
                step['continue-on-error'] = True
        errors = gate_step_errors(workflow)
        self.assertTrue(any('continue-on-error' in error for error in errors))

    def test_matrix_emit_cannot_be_replaced(self):
        workflow = load_ci()
        for step in workflow['jobs']['matrix']['steps']:
            if step.get('id') == 'emit':
                step['run'] = 'echo \'include=[]\' >> "$GITHUB_OUTPUT"'
        errors = matrix_emit_errors(workflow)
        self.assertTrue(errors)
        self.assertTrue(any('ci_matrix.py --github-output' in error for error in errors))

    def test_pr_template_marker_is_required(self):
        with tempfile.TemporaryDirectory() as temp:
            path = pathlib.Path(temp) / 'PULL_REQUEST_TEMPLATE.md'
            path.write_text('- [ ] 内部重构\n')
            errors = pr_template_errors(path)
            self.assertTrue(errors)
            self.assertTrue(any('## 改动类型' in error for error in errors))

    def test_release_status_workflow_is_required(self):
        with tempfile.TemporaryDirectory() as temp:
            path = pathlib.Path(temp) / 'release-status.yml'
            path.write_text('name: x\njobs:\n  a:\n    steps:\n      - run: echo hi\n')
            errors = release_status_workflow_errors(path)
            self.assertTrue(errors)
            self.assertIn('release_status.py --online --check', errors[0])

    def _release_errors(self, mutate) -> list[str]:
        data = yaml.safe_load(
            (ROOT / '.github/workflows/release-status.yml').read_text()
        )
        mutate(data)
        with tempfile.TemporaryDirectory() as temp:
            path = pathlib.Path(temp) / 'release-status.yml'
            path.write_text(yaml.safe_dump(data, sort_keys=False))
            return release_status_workflow_errors(path)

    def test_release_status_schedule_cannot_be_removed(self):
        errors = self._release_errors(lambda w: w[True].pop('schedule'))
        self.assertTrue(any('on.schedule' in error for error in errors))

    def test_release_status_cron_cannot_be_changed(self):
        errors = self._release_errors(
            lambda w: w[True]['schedule'][0].update({'cron': '0 2 * * 1'})
        )
        self.assertTrue(any("0 1 * * 1" in error for error in errors))

    def test_release_status_job_cannot_be_disabled(self):
        errors = self._release_errors(lambda w: w['jobs']['status'].update({'if': False}))
        self.assertTrue(any('status job' in error and 'if' in error for error in errors))

    def test_release_status_step_cannot_be_disabled(self):
        def mutate(w):
            for step in w['jobs']['status']['steps']:
                if 'release_status.py --online --check' in str(step.get('run') or ''):
                    step['if'] = False

        errors = self._release_errors(mutate)
        self.assertTrue(any('周检步骤' in error and 'if' in error for error in errors))

    def test_release_status_step_cannot_ignore_failure(self):
        def mutate(w):
            for step in w['jobs']['status']['steps']:
                if 'release_status.py --online --check' in str(step.get('run') or ''):
                    step['continue-on-error'] = True

        errors = self._release_errors(mutate)
        self.assertTrue(any('continue-on-error' in error for error in errors))


if __name__ == '__main__':
    unittest.main()
