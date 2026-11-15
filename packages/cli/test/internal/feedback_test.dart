import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:w_tools_cli/src/feedback/feedback_ledger.dart';
import 'package:w_tools_cli/src/feedback/feedback_path.dart';
import 'package:w_tools_cli/src/feedback/feedback_submit.dart';

Directory _tmp(String prefix) => Directory.systemTemp.createTempSync(prefix);

void main() {
  group('包名校验', () {
    test('合法包名原样返回；空 / null 视为不指定', () {
      expect(validatePackageName('figma'), 'figma');
      expect(validatePackageName('e2e'), 'e2e');
      expect(validatePackageName(null), isNull);
      expect(validatePackageName(''), isNull);
    });

    test('带 .. 或大小写的包名抛 FormatException', () {
      expect(() => validatePackageName('../evil'), throwsFormatException);
      expect(() => validatePackageName('Fig'), throwsFormatException);
      expect(() => validatePackageName('a/b'), throwsFormatException);
    });
  });

  test('CLI-007 反馈包清单包含 app_getx / map_google', () {
    expect(feedbackPackages, contains('app_getx'));
    expect(feedbackPackages, contains('map_google'));
  });

  test('CLI-012 本地查重不把 README / TEMPLATE 当反馈', () {
    final root = _tmp('wt_fb_search_');
    addTearDown(() => root.deleteSync(recursive: true));
    final dir = Directory(p.join(root.path, 'docs', 'feedback'))..createSync(recursive: true);
    File(p.join(dir.path, 'README.md')).writeAsStringSync('| [api](api.md) | 0 | needle |\n');
    File(p.join(dir.path, 'TEMPLATE.md')).writeAsStringSync('# needle 模板\n');
    File(
      p.join(dir.path, 'api.md'),
    ).writeAsStringSync('### [待处理] api: needle 真问题\n- 包/版本：api 1.0.0\n');

    final matches = searchLocal(root, query: 'needle');

    expect(matches.map((m) => p.basename(m.file)), <String>['api.md']);
  });
}
