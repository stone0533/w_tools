import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('.pubignore 只排除根目录的维护者源文件', () {
    final lines = File('.pubignore')
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toList();

    for (final dir in ['catalog', 'templates', 'tool']) {
      expect(lines, contains('/$dir/'), reason: dir);
      expect(lines, isNot(contains('$dir/')), reason: dir);
    }
  });

  test('运行时 catalog 源码存在', () {
    for (final name in [
      'catalog.dart',
      'catalog_entry.dart',
      'catalog.g.dart',
      'list_command.dart',
    ]) {
      expect(
        File('lib/src/catalog/$name').existsSync(),
        isTrue,
        reason: 'lib/src/catalog/$name',
      );
    }
  });
}
