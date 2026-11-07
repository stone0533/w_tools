import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_cli/src/feedback/feedback_ledger.dart';

import '../../bin/explain.dart' show exampleUrl;

void main() {
  test('CLI-011 manifest 的每个包在 feedback / example 清单里都有落点', () {
    final manifest = File('../../scripts/packages.manifest');
    if (!manifest.existsSync()) return;

    for (final line in manifest.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final cells = trimmed.split('|');
      final name = cells[0].trim();
      final path = cells[1].trim();
      final short = name.startsWith('w_tools_') ? name.substring('w_tools_'.length) : name;

      expect(feedbackPackages, contains(short), reason: '$name 缺少 feedback 包名');

      if (Directory('../../$path/example').existsSync()) {
        expect(exampleUrl(name), isNotNull, reason: '$name 有 example 但 exampleUrl 没登记');
      }
    }
  });
}
