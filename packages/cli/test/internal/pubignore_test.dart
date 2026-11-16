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

  test('发布 manifest 覆盖运行时 catalog 源码', () {
    final manifest = File('tool/publish_manifest.txt').readAsLinesSync();
    for (final name in [
      'lib/src/catalog/catalog.dart',
      'lib/src/catalog/catalog_entry.dart',
      'lib/src/catalog/catalog.g.dart',
      'lib/src/catalog/list_command.dart',
    ]) {
      expect(manifest, contains(name), reason: name);
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
