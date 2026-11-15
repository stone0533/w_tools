import contextlib
import io
import pathlib
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from check_public_api_diff import api_surface
import check_api_budget as budget


class BudgetUnitTest(unittest.TestCase):
    def test_release_kind(self):
        self.assertEqual(budget.release_kind('1.0.1', '1.0.0'), 'patch')
        self.assertEqual(budget.release_kind('1.1.0', '1.0.0'), 'minor')
        self.assertEqual(budget.release_kind('2.0.0', '1.9.0'), 'major')
        self.assertEqual(budget.release_kind('1.0.0', '1.0.0'), 'same')
        self.assertEqual(budget.release_kind('0.9.0', '1.0.0'), 'behind')

    def test_allowed_growth_uses_ratio_and_clamp(self):
        defaults = {'growth_ratio': 0.03, 'min_growth': 3, 'max_growth': 12}
        self.assertEqual(budget.allowed_growth({}, defaults, 10), 3)    # floor
        self.assertEqual(budget.allowed_growth({}, defaults, 100), 3)   # 3
        self.assertEqual(budget.allowed_growth({}, defaults, 500), 12)  # cap
        self.assertEqual(budget.allowed_growth({'growth': 5}, defaults, 500), 5)


class BudgetCheckTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self.temp.name)
        (self.root / 'snapshots').mkdir()
        (self.root / 'docs' / 'adr').mkdir(parents=True)
        (self.root / 'docs' / 'adr' / '0001-demo.md').write_text('# demo\n')
        self._old_root, self._old_snapshots = budget.ROOT, budget.SNAPSHOTS
        budget.ROOT, budget.SNAPSHOTS = self.root, self.root / 'snapshots'
        self.defaults = {'mode': 'library', 'growth_ratio': 0.03, 'min_growth': 3, 'max_growth': 12}

    def tearDown(self):
        budget.ROOT, budget.SNAPSHOTS = self._old_root, self._old_snapshots
        self.temp.cleanup()

    def _package(self, version, body):
        package = self.root / 'packages' / 'demo'
        (package / 'lib' / 'src').mkdir(parents=True, exist_ok=True)
        (package / 'lib' / 'w_tools_demo.dart').write_text("export 'src/a.dart';\n")
        (package / 'lib' / 'src' / 'a.dart').write_text(body)
        (package / 'pubspec.yaml').write_text(f'name: w_tools_demo\nversion: {version}\n')
        return package

    def _snapshot(self, body, version='1.0.0'):
        source = self.root / 'baseline'
        (source / 'lib' / 'src').mkdir(parents=True, exist_ok=True)
        (source / 'lib' / 'w_tools_demo.dart').write_text("export 'src/a.dart';\n")
        (source / 'lib' / 'src' / 'a.dart').write_text(body)
        surface = api_surface(source)
        lines = [f'# w_tools_demo {version}'] + [
            f'{key}\t{value}' for key, value in sorted(surface.items())
        ]
        (self.root / 'snapshots' / f'w_tools_demo-{version}.txt').write_text(
            '\n'.join(lines) + '\n'
        )

    def _check(self, entry=None, exceptions=None):
        return budget.check_package(
            'demo',
            entry or {},
            self.defaults,
            exceptions or [],
        )

    def test_patch_addition_fails(self):
        self._snapshot('class WDemo {\n  void a() {}\n}\n')
        self._package('1.0.1', 'class WDemo {\n  void a() {}\n  void b() {}\n}\n')
        errors, _, _ = self._check()
        self.assertTrue(any('新增' in error or '净增' in error for error in errors))

    def test_same_version_addition_fails(self):
        self._snapshot('class WDemo {\n  void a() {}\n}\n')
        self._package('1.0.0', 'class WDemo {\n  void a() {}\n  void b() {}\n}\n')
        errors, _, _ = self._check({'growth': 5})
        self.assertTrue(any('版本没抬' in error for error in errors))

    def test_minor_removal_fails(self):
        self._snapshot('class WDemo {\n  void a() {}\n  void b() {}\n}\n')
        self._package('1.1.0', 'class WDemo {\n  void a() {}\n}\n')
        errors, _, _ = self._check({'growth': 5})
        self.assertTrue(any('minor 不允许删除' in error for error in errors))

    def test_same_version_signature_change_fails(self):
        self._snapshot('class WDemo {\n  void a() {}\n}\n')
        self._package('1.0.0', 'class WDemo {\n  void a(int x) {}\n}\n')
        errors, _, _ = self._check({'growth': 5})
        self.assertTrue(any('签名 / 默认值变化' in error for error in errors))

    def test_patch_signature_change_fails(self):
        self._snapshot('class WDemo {\n  void a() {}\n}\n')
        self._package('1.0.1', 'class WDemo {\n  void a(int x) {}\n}\n')
        errors, _, _ = self._check({'growth': 5})
        self.assertTrue(any('patch 版本不允许' in error for error in errors))

    def test_minor_optional_param_added_is_additive(self):
        self._snapshot('class WDemo {\n  void a() {}\n}\n')
        self._package('1.1.0', 'class WDemo {\n  void a({int? x}) {}\n}\n')
        errors, notes, _ = self._check({'growth': 5})
        self.assertEqual(errors, [])
        self.assertTrue(any('additive' in note for note in notes))

    def test_minor_required_param_added_fails(self):
        self._snapshot('class WDemo {\n  void a() {}\n}\n')
        self._package('1.1.0', 'class WDemo {\n  void a(int x) {}\n}\n')
        errors, _, _ = self._check({'growth': 5})
        self.assertTrue(any('required 参数' in error for error in errors))

    def test_minor_param_removed_fails(self):
        self._snapshot('class WDemo {\n  void a(int x) {}\n}\n')
        self._package('1.1.0', 'class WDemo {\n  void a() {}\n}\n')
        errors, _, _ = self._check({'growth': 5})
        self.assertTrue(any('删除参数' in error for error in errors))

    def test_minor_param_type_change_fails(self):
        self._snapshot('class WDemo {\n  void a(int x) {}\n}\n')
        self._package('1.1.0', 'class WDemo {\n  void a(String x) {}\n}\n')
        errors, _, _ = self._check({'growth': 5})
        self.assertTrue(any('类型' in error for error in errors))

    def test_minor_default_value_change_is_additive(self):
        self._snapshot('class WDemo {\n  void a([int x = 1]) {}\n}\n')
        self._package('1.1.0', 'class WDemo {\n  void a([int x = 2]) {}\n}\n')
        errors, notes, _ = self._check({'growth': 5})
        self.assertEqual(errors, [])
        self.assertTrue(any('additive' in note for note in notes))

    def test_new_enum_value_fails_on_minor(self):
        self._snapshot('enum WStatus {\n  a,\n}\n')
        self._package('1.1.0', 'enum WStatus {\n  a,\n  b,\n}\n')
        errors, _, _ = self._check({'growth': 5})
        self.assertTrue(any('breaking addition' in error for error in errors))

    def test_new_enum_value_passes_on_major(self):
        self._snapshot('enum WStatus {\n  a,\n}\n')
        self._package('2.0.0', 'enum WStatus {\n  a,\n  b,\n}\n')
        errors, _, _ = self._check({'growth': 5})
        self.assertEqual(errors, [])

    def test_new_sealed_subtype_fails_on_minor(self):
        self._snapshot('sealed class WBase {}\n')
        self._package(
            '1.1.0',
            'sealed class WBase {}\nclass WChild extends WBase {}\n',
        )
        errors, _, _ = self._check(
            {'growth': 5},
            [{
                'package': 'demo',
                'type': 'WChild',
                'adr': 'docs/adr/0001-demo.md',
                'until': '1.1.0',
            }],
        )
        self.assertTrue(any('sealed 子类型' in error for error in errors))

    def test_new_enum_type_in_minor_is_not_breaking(self):
        self._snapshot('class WDemo {}\n')
        self._package('1.1.0', 'class WDemo {}\nenum WNew {\n  a,\n}\n')
        errors, _, _ = self._check(
            {'growth': 5},
            [{
                'package': 'demo',
                'type': 'WNew',
                'adr': 'docs/adr/0001-demo.md',
                'until': '1.1.0',
            }],
        )
        self.assertEqual(errors, [])

    def test_new_sealed_hierarchy_in_minor_is_not_breaking(self):
        self._snapshot('class WDemo {}\n')
        self._package(
            '1.1.0',
            'class WDemo {}\nsealed class WBase {}\nclass WChild extends WBase {}\n',
        )
        errors, _, _ = self._check(
            {'growth': 5},
            [
                {'package': 'demo', 'type': 'WBase', 'adr': 'docs/adr/0001-demo.md', 'until': '1.1.0'},
                {'package': 'demo', 'type': 'WChild', 'adr': 'docs/adr/0001-demo.md', 'until': '1.1.0'},
            ],
        )
        self.assertEqual(errors, [])

    def test_indirect_sealed_subtype_fails_on_minor(self):
        self._snapshot('sealed class WBase {}\n')
        self._package(
            '1.1.0',
            'sealed class WBase {}\n'
            'class _Mid extends WBase {}\n'
            'class WChild extends _Mid {}\n',
        )
        errors, _, _ = self._check(
            {'growth': 5},
            [{
                'package': 'demo',
                'type': 'WChild',
                'adr': 'docs/adr/0001-demo.md',
                'until': '1.1.0',
            }],
        )
        self.assertTrue(any('sealed 子类型' in error for error in errors))

    def test_new_sealed_subtype_passes_on_major(self):
        self._snapshot('sealed class WBase {}\n')
        self._package(
            '2.0.0',
            'sealed class WBase {}\nclass WChild extends WBase {}\n',
        )
        errors, _, _ = self._check(
            {'growth': 5},
            [{
                'package': 'demo',
                'type': 'WChild',
                'adr': 'docs/adr/0001-demo.md',
                'until': '2.0.0',
            }],
        )
        self.assertEqual(errors, [])

    def test_aggregate_mode_is_not_supported(self):
        self.assertNotIn('aggregate', budget.VALID_MODES)

    def test_minor_growth_within_budget(self):
        self._snapshot('class WDemo {\n  void a() {}\n}\n')
        self._package('1.1.0', 'class WDemo {\n  void a() {}\n  void b() {}\n}\n')
        errors, notes, _ = self._check({'growth': 5})
        self.assertEqual(errors, [])
        self.assertTrue(any('净增' in note for note in notes))

    def test_minor_growth_over_budget(self):
        self._snapshot('class WDemo {\n  void a() {}\n}\n')
        self._package(
            '1.1.0',
            'class WDemo {\n  void a() {}\n  void b() {}\n  void c() {}\n}\n',
        )
        errors, _, _ = self._check({'growth': 1})
        self.assertTrue(any('> 预算' in error for error in errors))

    def test_new_type_requires_exception(self):
        self._snapshot('class WDemo {\n  void a() {}\n}\n')
        self._package(
            '1.1.0',
            'class WDemo {\n  void a() {}\n}\nclass WNew {}\n',
        )
        errors, _, _ = self._check({'growth': 5})
        self.assertTrue(any('WNew' in error and 'ADR' in error for error in errors))

    def test_new_type_with_adr_exception_passes(self):
        self._snapshot('class WDemo {\n  void a() {}\n}\n')
        self._package(
            '1.1.0',
            'class WDemo {\n  void a() {}\n}\nclass WNew {}\n',
        )
        errors, _, _ = self._check(
            {'growth': 5},
            [{
                'package': 'demo',
                'type': 'WNew',
                'adr': 'docs/adr/0001-demo.md',
                'until': '1.1.0',
            }],
        )
        self.assertEqual(errors, [])

    def test_new_type_exception_expires(self):
        self._snapshot('class WDemo {\n  void a() {}\n}\n')
        self._package(
            '1.2.0',
            'class WDemo {\n  void a() {}\n}\nclass WNew {}\n',
        )
        errors, _, _ = self._check(
            {'growth': 5},
            [{
                'package': 'demo',
                'type': 'WNew',
                'adr': 'docs/adr/0001-demo.md',
                'until': '1.1.0',
            }],
        )
        self.assertTrue(any('到期' in error for error in errors))

    def test_exception_without_until_fails(self):
        problem = budget._validate_exception(
            {
                'package': 'demo',
                'type': 'WNew',
                'adr': 'docs/adr/0001-demo.md',
            },
            'demo',
            'WNew',
            '1.1.0',
        )
        self.assertIsNotNone(problem)
        self.assertIn('until', problem)

    def test_tool_mode_skips(self):
        errors, _, summary = self._check({'mode': 'tool'})
        self.assertEqual(errors, [])
        self.assertIn('tool', summary)

    def test_tool_mode_rejects_barrel(self):
        self._package('1.0.0', 'class WDemo {}\n')
        errors, _, _ = self._check({'mode': 'tool'})
        self.assertTrue(any('mode=tool' in error for error in errors))


class BudgetMainTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self.temp.name)
        (self.root / 'scripts').mkdir()
        (self.root / 'snapshots').mkdir()
        self._old = (budget.ROOT, budget.SNAPSHOTS, budget.CONFIG, budget.MANIFEST, sys.argv)
        budget.ROOT = self.root
        budget.SNAPSHOTS = self.root / 'snapshots'
        budget.CONFIG = self.root / 'scripts' / 'api_budget.yaml'
        budget.MANIFEST = self.root / 'scripts' / 'packages.manifest'
        sys.argv = ['check_api_budget.py']

    def tearDown(self):
        budget.ROOT, budget.SNAPSHOTS, budget.CONFIG, budget.MANIFEST, sys.argv = self._old
        self.temp.cleanup()

    def _run(self):
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            return budget.main()

    def test_missing_config_fails(self):
        budget.MANIFEST.write_text('w_tools_demo|packages/demo|dart|-|-\n')
        self.assertEqual(self._run(), 2)

    def test_manifest_package_without_entry_fails(self):
        budget.MANIFEST.write_text('w_tools_demo|packages/demo|dart|-|-\n')
        budget.CONFIG.write_text('defaults:\n  mode: library\npackages: {}\n')
        self.assertEqual(self._run(), 2)


if __name__ == '__main__':
    unittest.main()
