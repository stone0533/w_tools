import contextlib
import io
import pathlib
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from check_public_api_diff import (
    _current_version_text,
    api_surface,
    check_notes,
    diff_api,
    latest_snapshot,
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


if __name__ == '__main__':
    unittest.main()
