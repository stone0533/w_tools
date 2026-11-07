import contextlib
import io
import pathlib
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

ROOT = pathlib.Path(__file__).resolve().parents[2]

from check_public_api_diff import (
    _current_version_text,
    api_surface,
    check_notes,
    diff_api,
    latest_snapshot,
    latest_snapshot_version,
)


class PublicApiDiffTest(unittest.TestCase):
    def test_nullable_change_is_detected(self):
        changes = diff_api(
            {'WButton.color': 'Color'},
            {'WButton.color': 'Color?'},
        )
        self.assertEqual(changes, [('WButton.color', 'Color', 'Color?')])

    def test_removed_symbol_is_detected(self):
        changes = diff_api({'WButton.color': 'Color'}, {})
        self.assertEqual(changes, [('WButton.color', 'Color', None)])

    def test_changelog_breaking_is_required(self):
        changes = [('WStepStyle.completedColor', 'Color', 'Color?')]
        errors = check_notes(
            changes,
            changelog='## 7.0.0\n\n### Added\n- WStepStyle.resolve\n',
            migration='',
        )
        self.assertEqual(len(errors), 1)
        self.assertIn('WStepStyle', errors[0])

        errors = check_notes(
            changes,
            changelog='## 7.0.0\n\n### Breaking\n- WStepStyle.completedColor 改为可空\n',
            migration='',
        )
        self.assertEqual(errors, [])

    def test_migration_can_satisfy_instead_of_changelog(self):
        changes = [('WStepStyle.completedColor', 'Color', 'Color?')]
        errors = check_notes(
            changes,
            changelog='## 7.0.0\n\n### Added\n- WStepStyle.resolve\n',
            migration='WStepStyle.completedColor 改为可空\n',
        )
        self.assertEqual(errors, [])

    def test_method_signature_is_captured(self):
        with tempfile.TemporaryDirectory() as temp:
            package = pathlib.Path(temp)
            (package / 'lib' / 'src').mkdir(parents=True)
            (package / 'lib' / 'w_tools_demo.dart').write_text(
                "export 'src/a.dart';\n"
            )
            (package / 'lib' / 'src' / 'a.dart').write_text(
                'class WThing {\n'
                '  void run(int value) {}\n'
                '  String get name => "x";\n'
                '}\n'
            )
            surface = api_surface(package)
            self.assertEqual(surface.get('WThing.run'), 'void (int value)')
            self.assertEqual(surface.get('WThing.name'), 'String')

    def test_function_typed_field_is_field_not_method(self):
        with tempfile.TemporaryDirectory() as temp:
            package = pathlib.Path(temp)
            (package / 'lib' / 'src').mkdir(parents=True)
            (package / 'lib' / 'w_tools_demo.dart').write_text(
                "export 'src/a.dart';\n"
            )
            (package / 'lib' / 'src' / 'a.dart').write_text(
                'class WThing {\n'
                '  final Widget? Function(BuildContext, String)? builder;\n'
                '  bool operator ==(Object other) => true;\n'
                '}\n'
            )
            surface = api_surface(package)
            self.assertEqual(
                surface.get('WThing.builder'),
                'Widget? Function(BuildContext, String)?',
            )
            self.assertNotIn('WThing.Function', surface)
            self.assertNotIn('WThing.operator', surface)

    def test_public_constructors_are_captured(self):
        with tempfile.TemporaryDirectory() as temp:
            package = pathlib.Path(temp)
            (package / 'lib' / 'src').mkdir(parents=True)
            (package / 'lib' / 'w_tools_demo.dart').write_text(
                "export 'src/a.dart';\n"
            )
            (package / 'lib' / 'src' / 'a.dart').write_text(
                'class WThing {\n'
                '  WThing({required int x});\n'
                '  factory WThing.named(String y) => WThing(x: 0);\n'
                '}\n'
            )
            surface = api_surface(package)
            self.assertEqual(surface.get('WThing.new'), '({required int x})')
            self.assertEqual(surface.get('WThing.named'), '(String y)')

    def test_method_after_multiline_body_is_captured(self):
        with tempfile.TemporaryDirectory() as temp:
            package = pathlib.Path(temp)
            (package / 'lib' / 'src').mkdir(parents=True)
            (package / 'lib' / 'w_tools_demo.dart').write_text(
                "export 'src/a.dart';\n"
            )
            (package / 'lib' / 'src' / 'a.dart').write_text(
                'class WThing {\n'
                '  void run(\n'
                '    int value,\n'
                '  ) {\n'
                '    final local = 1;\n'
                '  }\n'
                '  void after() {}\n'
                '}\n'
            )
            surface = api_surface(package)
            self.assertIn('WThing.after', surface)

    def test_method_signature_change_is_detected(self):
        changes = diff_api(
            {'WThing.run': 'void (int value)'},
            {'WThing.run': 'void (String value)'},
        )
        self.assertEqual(
            changes,
            [('WThing.run', 'void (int value)', 'void (String value)')],
        )

    def test_version_section_is_selected_by_pubspec_version(self):
        changelog = (
            '## 7.1.0\n\n### Breaking\n- WThing.future\n\n'
            '## 7.0.0\n\n### Breaking\n- WThing.current\n'
        )
        text = _current_version_text(changelog, '7.0.0')
        self.assertIn('WThing.current', text)
        self.assertNotIn('WThing.future', text)

    def test_unreleased_section_is_used_when_version_is_missing(self):
        changelog = (
            '## Unreleased\n\n### Breaking\n- WThing.upcoming\n\n'
            '## 7.0.0\n\n### Breaking\n- WThing.released\n'
        )
        text = _current_version_text(changelog, '7.1.0')
        self.assertIn('WThing.upcoming', text)
        self.assertNotIn('WThing.released', text)

    def test_bare_member_name_no_longer_satisfies_breaking_notes(self):
        changes = [('WButton.text', 'String', 'String?')]
        errors = check_notes(
            changes,
            changelog='## 7.0.0\n\n### Breaking\n- 调整了 text 的默认值\n',
            migration='the text field layout changed',
        )
        self.assertEqual(len(errors), 1)

    def test_full_member_name_satisfies_breaking_notes(self):
        changes = [('WButton.text', 'String', 'String?')]
        errors = check_notes(
            changes,
            changelog='## 7.0.0\n\n### Breaking\n- `WButton.text` 改为可空\n',
            migration='',
        )
        self.assertEqual(errors, [])

    def test_missing_snapshot_is_an_error(self):
        import check_public_api_diff as mod

        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            package = root / 'packages' / 'demo'
            (package / 'lib' / 'src').mkdir(parents=True)
            (package / 'lib' / 'w_tools_demo.dart').write_text("export 'src/a.dart';\n")
            (package / 'lib' / 'src' / 'a.dart').write_text('class WDemo {}\n')
            (package / 'pubspec.yaml').write_text(
                'name: w_tools_demo\nversion: 1.0.0\n'
            )
            old_root, old_snapshots = mod.ROOT, mod.SNAPSHOTS
            old_argv = sys.argv
            mod.ROOT = root
            mod.SNAPSHOTS = root / 'snapshots'
            mod.SNAPSHOTS.mkdir()
            try:
                sys.argv = ['check_public_api_diff.py', '--package', 'demo']
                with contextlib.redirect_stderr(io.StringIO()):
                    self.assertEqual(mod.main(), 1)
            finally:
                mod.ROOT, mod.SNAPSHOTS = old_root, old_snapshots
                sys.argv = old_argv


    def test_empty_surface_fails_unless_declared(self):
        """空 surface 不能当成「一致」：cli 显式登记后跳过，其它包必须失败。"""
        import check_public_api_diff as mod

        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / 'snapshots').mkdir()
            (root / 'snapshots' / 'w_tools_demo-1.0.0.txt').write_text('# w_tools_demo 1.0.0\n')
            (root / 'snapshots' / 'w_tools_cli-1.0.0.txt').write_text('# w_tools_cli 1.0.0\n')
            old_root, old_snapshots = mod.ROOT, mod.SNAPSHOTS
            old_argv = sys.argv
            mod.ROOT = root
            mod.SNAPSHOTS = root / 'snapshots'
            try:
                sys.argv = ['check_public_api_diff.py', '--package', 'demo']
                with contextlib.redirect_stdout(io.StringIO()):
                    with contextlib.redirect_stderr(io.StringIO()):
                        self.assertEqual(mod.main(), 1)

                sys.argv = ['check_public_api_diff.py', '--package', 'cli']
                with contextlib.redirect_stdout(io.StringIO()):
                    self.assertEqual(mod.main(), 0)
            finally:
                mod.ROOT, mod.SNAPSHOTS = old_root, old_snapshots
                sys.argv = old_argv

    def test_output_dir_writes_snapshot_to_pending_dir(self):
        """发布脚本把快照写到 .w_tools/release-snapshots，不直接写 scripts/api_snapshots。"""
        import check_public_api_diff as mod

        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            package = root / 'packages' / 'demo'
            (package / 'lib' / 'src').mkdir(parents=True)
            (package / 'lib' / 'w_tools_demo.dart').write_text("export 'src/a.dart';\n")
            (package / 'lib' / 'src' / 'a.dart').write_text('class WDemo {}\n')
            (package / 'pubspec.yaml').write_text('name: w_tools_demo\nversion: 1.0.0\n')
            pending = root / 'pending'
            old_root, old_snapshots = mod.ROOT, mod.SNAPSHOTS
            old_argv = sys.argv
            mod.ROOT = root
            mod.SNAPSHOTS = root / 'snapshots'
            try:
                sys.argv = [
                    'check_public_api_diff.py',
                    '--snapshot-from', str(package),
                    '--package', 'demo',
                    '--version', '1.0.0',
                    '--output-dir', str(pending),
                ]
                with contextlib.redirect_stdout(io.StringIO()):
                    self.assertEqual(mod.main(), 0)
                self.assertTrue((pending / 'w_tools_demo-1.0.0.txt').exists())
                self.assertFalse((mod.SNAPSHOTS / 'w_tools_demo-1.0.0.txt').exists())
            finally:
                mod.ROOT, mod.SNAPSHOTS = old_root, old_snapshots
                sys.argv = old_argv


class SnapshotIntegrityTest(unittest.TestCase):
    """空基线 = 门禁永久空转；--snapshot-from 必须拒绝写空 / 写错版本。"""

    def _run(self, mod, root, argv):
        old_root, old_snapshots = mod.ROOT, mod.SNAPSHOTS
        old_argv = sys.argv
        mod.ROOT = root
        mod.SNAPSHOTS = root / 'snapshots'
        sys.argv = ['check_public_api_diff.py', *argv]
        try:
            with contextlib.redirect_stdout(io.StringIO()):
                with contextlib.redirect_stderr(io.StringIO()):
                    return mod.main()
        finally:
            mod.ROOT, mod.SNAPSHOTS = old_root, old_snapshots
            sys.argv = old_argv

    def _package(self, root):
        package = root / 'packages' / 'demo'
        (package / 'lib' / 'src').mkdir(parents=True)
        (package / 'lib' / 'w_tools_demo.dart').write_text("export 'src/a.dart';\n")
        (package / 'lib' / 'src' / 'a.dart').write_text('class WDemo {}\n')
        (package / 'pubspec.yaml').write_text('name: w_tools_demo\nversion: 2.0.0\n')
        (package / 'CHANGELOG.md').write_text('## 2.0.0\n')
        return package

    def test_empty_baseline_is_an_error(self):
        import check_public_api_diff as mod

        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            self._package(root)
            (root / 'snapshots').mkdir()
            (root / 'snapshots' / 'w_tools_demo-2.0.0.txt').write_text(
                '# w_tools_demo 2.0.0\n'
            )
            self.assertEqual(self._run(mod, root, ['--package', 'demo']), 1)

    def test_snapshot_from_rejects_empty_source(self):
        import check_public_api_diff as mod

        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / 'snapshots').mkdir()
            empty = root / 'empty-src'
            empty.mkdir()
            (empty / 'pubspec.yaml').write_text('name: w_tools_demo\nversion: 3.0.0\n')
            status = self._run(
                mod, root,
                ['--snapshot-from', str(empty), '--package', 'demo', '--version', '3.0.0'],
            )
            self.assertEqual(status, 1)
            self.assertFalse((root / 'snapshots' / 'w_tools_demo-3.0.0.txt').exists())

    def test_snapshot_from_rejects_version_mismatch(self):
        import check_public_api_diff as mod

        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / 'snapshots').mkdir()
            source = root / 'src'
            (source / 'lib').mkdir(parents=True)
            (source / 'lib' / 'w_tools_demo.dart').write_text('class WDemo {}\n')
            (source / 'pubspec.yaml').write_text('name: w_tools_demo\nversion: 2.0.0\n')
            status = self._run(
                mod, root,
                ['--snapshot-from', str(source), '--package', 'demo', '--version', '1.0.0'],
            )
            self.assertEqual(status, 2)

    def test_constructor_deletion_needs_its_own_note(self):
        errors = check_notes(
            [('WButton.new', '({int x})', None)],
            changelog='## 7.1.0\n\n### Breaking\n- WButton.text 改为可空\n',
            migration='',
            current={'WButton': 'class'},
            version='7.1.0',
        )
        self.assertEqual(len(errors), 1)

    def test_old_major_migration_only_counts_on_major_bump(self):
        changes = [('WColorExtension.fromHex', 'String (int)', 'String (String)')]
        migration = 'WColorExtension.fromHex 参数改为 String\n'
        same_major = check_notes(
            changes, '', migration,
            current={'WColorExtension': 'extension'}, version='7.1.0',
            allow_migration=False,
        )
        self.assertEqual(len(same_major), 1)
        major_bump = check_notes(
            changes, '', migration,
            current={'WColorExtension': 'extension'}, version='8.0.0',
            allow_migration=True,
        )
        self.assertEqual(major_bump, [])

    def test_prerelease_snapshot_is_the_latest(self):
        from check_public_api_diff import latest_snapshot, snapshot_version_of

        with tempfile.TemporaryDirectory() as temp:
            directory = pathlib.Path(temp)
            stable = directory / 'w_tools_demo-7.0.0.txt'
            dev = directory / 'w_tools_demo-8.0.0-dev.1.txt'
            stable.write_text('# 7.0.0\n')
            dev.write_text('# 8.0.0-dev.1\n')
            self.assertEqual(snapshot_version_of(dev), '8.0.0-dev.1')
            self.assertEqual(latest_snapshot([stable, dev]), dev)

    def test_latest_snapshot_flag_prints_version(self):
        result = subprocess.run(
            [
                sys.executable,
                'scripts/check_public_api_diff.py',
                '--package', 'ui',
                '--latest-snapshot',
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), latest_snapshot_version('ui'))


if __name__ == '__main__':
    unittest.main()
