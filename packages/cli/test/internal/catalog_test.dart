import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_cli/src/catalog/catalog.dart';

import '../../tool/gen_catalog.dart' as gen;

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

  test('components.md 的 §1~§9 表格由 YAML 生成（不能手改）', () {
    final docs = File('../../docs/modules/components.md');
    if (!docs.existsSync()) return;
    expect(
      docs.readAsStringSync(),
      gen.generateDocs(Directory.current.path),
      reason: '改了 catalog/components.yaml 之后要跑 `dart run tool/gen_catalog.dart`',
    );
  });

  test('components.md 里出现的每个名字都能被 explain 找到', () {
    final docs = File('../../docs/modules/components.md');
    if (!docs.existsSync()) return;
    final names = <String>{};
    for (final line in docs.readAsLinesSync()) {
      if (!line.startsWith('|')) continue;
      final cells = line.split('|');
      if (cells.length < 3) continue;
      final first = cells[1].trim();
      if (!first.startsWith('`')) continue;
      for (final m in RegExp(r'`([^`]+)`').allMatches(first)) {
        names.add(m.group(1)!.replaceAll('*', '').trim());
      }
    }
    expect(names, isNotEmpty);
    for (final name in names) {
      expect(
        findComponent(name),
        isNotNull,
        reason: 'components.md 推荐了 $name，但 catalog / explain 找不到它',
      );
    }
  });

  test('catalog 组件名都能在对应子包的公开声明中找到', () {
    final packagesRoot = Directory('../../packages');
    if (!packagesRoot.existsSync()) return;

    for (final entry in catalog) {
      final packageName = entry.package.replaceFirst('w_tools_', '');
      final packageDir = Directory('${packagesRoot.path}/$packageName/lib');
      if (!packageDir.existsSync()) {
        fail('catalog 指向不存在的子包：${entry.package}');
      }

      final source = packageDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .map((file) => file.readAsStringSync())
          .join('\n');

      for (final alias in entry.names) {
        final name = alias.replaceAll('*', '').trim();
        if (name.isEmpty) continue;
        final declaration = RegExp(
          r'\b(?:class|enum|mixin|typedef|extension)\s+' + RegExp.escape(name) + r'\b',
        );
        expect(
          declaration.hasMatch(source),
          isTrue,
          reason: 'catalog 引用了不存在的组件：$name（${entry.package}）',
        );
      }
    }
  });

  test('ASYNC-001：sliver*Builder 的示例返回非滚动 Widget', () {
    final entry = findComponent('WAsyncTheme');
    expect(entry, isNotNull);
    expect(entry!.usage, isNotNull);
    expect(entry.usage, contains('sliverLoadingBuilder'));
    expect(
      entry.usage,
      isNot(contains('SliverFillRemaining')),
      reason: 'sliver*Builder 由 WAsyncStateSliver 包 SliverFillRemaining，示例不能返回 sliver',
    );
  });

  test('ASYNC-002：WAsyncOptions / WAsyncActivity / WCancelToken 各自可 explain', () {
    for (final name in <String>['WAsyncOptions', 'WAsyncActivity', 'WCancelToken']) {
      final entry = findComponent(name);
      expect(entry, isNotNull, reason: '$name 没有独立条目');
      expect(entry!.name, name, reason: '$name 仍被合并到 ${entry.name}');
      expect(entry.usage, isNotNull, reason: '$name 没有 usage');
      expect(entry.teach, isTrue, reason: '$name 是入口类型，应 teach');
    }
  });
}
