import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:w_tools_cli/src/doctor/config.dart';
import 'package:w_tools_cli/src/doctor/context.dart';
import 'package:w_tools_cli/src/doctor/rules/r3_hardcoded_colors.dart';
import 'package:w_tools_cli/src/doctor/rules/r6_banned_units.dart';
import 'package:w_tools_cli/src/doctor/text_scan.dart';

Directory _project(Map<String, String> files) {
  final root = Directory.systemTemp.createTempSync('wt_scan_');
  files.forEach((rel, content) {
    final file = File(p.join(root.path, rel));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  });
  return root;
}

void main() {
  test('CLI-014 同一个 ProjectContext 内 SourceFile 复用', () {
    final root = _project({
      'pubspec.yaml': 'name: demo\n',
      'lib/a.dart': 'void main() {}\n',
    });
    addTearDown(() => root.deleteSync(recursive: true));
    final ctx = ProjectContext.load(root, DoctorConfig());

    expect(identical(TextScan.files(ctx).first, TextScan.files(ctx).first), isTrue);
  });

  test('CLI-015 字符串里的颜色 / 单位不算，fromHex 仍要命中', () {
    final root = _project({
      'pubspec.yaml': 'name: demo\n',
      'lib/a.dart':
          "const s = 'Color(0xFF3F3F3F) 1.5.r';\n"
          'final c = Color(0xFF3F3F3F);\n'
          "final d = WColors.fromHex('#3F3F3F');\n",
    });
    addTearDown(() => root.deleteSync(recursive: true));

    final colorConfig = DoctorConfig(palette: <String>['#3F3F3F'], colorMinCount: 1);
    final r3 = R3HardcodedColors.check(
      ProjectContext.load(root, colorConfig, includeTests: true),
      colorConfig,
    );
    expect(r3.issues.single.message, contains('2 处'));

    final unitsConfig = DoctorConfig(enabledRules: <String>{'R6'});
    final r6 = R6BannedUnits.check(
      ProjectContext.load(root, unitsConfig, includeTests: true),
      unitsConfig,
    );
    expect(r6.issues, isEmpty);
  });
}
