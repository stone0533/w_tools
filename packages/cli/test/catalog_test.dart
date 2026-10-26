import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_cli/src/catalog/catalog.dart';

import '../tool/gen_catalog.dart' as gen;

void main() {
  test('catalog.g.dart 与 catalog/components.yaml 一致', () {
    final committed = File('lib/src/catalog/catalog.g.dart').readAsStringSync();
    expect(
      committed,
      gen.generate(Directory.current.path),
      reason: '改了 catalog/components.yaml 之后要跑 `dart run tool/gen_catalog.dart`',
    );
  });

  test('别名唯一，能按名字精确查找', () {
    final seen = <String>{};
    for (final entry in catalog) {
      for (final name in entry.names) {
        expect(seen.add(name.toLowerCase()), isTrue, reason: '重复别名：$name');
      }
    }
    expect(catalog.length, greaterThan(20));
    expect(findComponent('WImage'), isNotNull);
    expect(findComponent('wimage'), isNotNull);
  });

  test('toJson 带齐 AI 需要的字段', () {
    final json = catalog.first.toJson();
    expect(json['name'], isNotEmpty);
    expect(json['names'], isA<List<Object?>>());
    expect(json['package'], startsWith('w_tools_'));
    expect(json['useFor'], isNotEmpty);
    expect(json['import'], startsWith('package:'));
    expect(json['docs'], contains('docs/modules/'));
  });

  test('按用途/反例关键词能搜到', () {
    final dialog = searchComponents('下拉');
    expect(dialog.map((e) => e.names.first), contains('WFormDropdown'));
    final image = searchComponents('Image.network');
    expect(image.map((e) => e.names.first), contains('WImage'));
  });

  test('components.md 里的组件都进了 catalog', () {
    final docs = File('../../docs/modules/components.md');
    if (!docs.existsSync()) return;
    final aliases = <String>{for (final e in catalog) ...e.names};
    final names = <String>{};
    for (final line in docs.readAsLinesSync()) {
      if (!line.startsWith('|')) continue;
      final cells = line.split('|');
      if (cells.length < 3) continue;
      final first = cells[1].trim();
      if (!first.startsWith('`')) continue;
      final match = RegExp(r'`([^`]+)`').firstMatch(first);
      if (match == null) continue;
      var name = match.group(1)!.split('/').first.trim().replaceAll('*', '');
      if (name.isNotEmpty) names.add(name);
    }
    for (final name in names) {
      expect(aliases, contains(name), reason: 'components.md 的 $name 不在 catalog');
    }
  });

  test('目录里的组件仍出现在 components.md', () {
    final docs = File('../../docs/modules/components.md');
    if (!docs.existsSync()) return;
    final text = docs.readAsStringSync();
    for (final entry in catalog) {
      expect(text, contains(entry.names.first), reason: 'components.md 缺 ${entry.name}');
    }
  });
}
