// 把 catalog/components.yaml 生成两份产物：
//   - lib/src/catalog/catalog.g.dart（CLI 的 list / explain 数据）
//   - docs/modules/components.md 的 §1~§9 表格（人和 AI 的入口）
//
// 用法：
//   dart run tool/gen_catalog.dart          # 重新生成
//   dart run tool/gen_catalog.dart --check  # 只校验是否过期（CI 用）
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

const _docsByPackage = <String, String>{
  'w_tools_core': 'docs/modules/core_module.md',
  'w_tools_app': 'docs/modules/app_module.md',
  'w_tools_app_getx': 'docs/modules/app_module.md',
  'w_tools_ui': 'docs/modules/ui_module.md',
  'w_tools_form': 'docs/modules/form_module.md',
  'w_tools_api': 'docs/modules/api_module.md',
  'w_tools_toast': 'docs/modules/toast_module.md',
  'w_tools_qr': 'docs/modules/qr_module.md',
  'w_tools_map': 'docs/modules/map_module.md',
  'w_tools_map_google': 'docs/modules/map_module.md',
  'w_tools_async': 'docs/modules/async_module.md',
};

String generate(String packageRoot) {
  final raw = loadYaml(File(p.join(packageRoot, 'catalog', 'components.yaml')).readAsStringSync());
  final version = (raw as YamlMap)['version'] as int;
  final components = (raw['components'] as YamlList).cast<YamlMap>();

  final buf = StringBuffer()
    ..writeln('// 由 tool/gen_catalog.dart 生成，不要手改。')
    ..writeln('// 来源：catalog/components.yaml（唯一来源）。')
    ..writeln('//')
    ..writeln('// dart format off')
    ..writeln("import 'catalog_entry.dart';")
    ..writeln()
    ..writeln('const int catalogSchemaVersion = $version;')
    ..writeln()
    ..writeln('const List<CatalogEntry> catalogEntries = <CatalogEntry>[');

  for (final c in components) {
    final rawName = c['name'] as String;
    final package = c['package'] as String;
    final names = rawName
        .split('/')
        .map((e) => e.replaceAll('`', '').replaceAll('*', '').trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final name = rawName.replaceAll('`', '');
    final docs = _docsByPackage[package];
    if (docs == null) {
      throw StateError('catalog/components.yaml: 未知 package $package');
    }
    final dont = c['dontUseFor'] as String?;
    buf
      ..writeln('  CatalogEntry(')
      ..writeln('    name: ${jsonEncode(name)},')
      ..writeln('    names: <String>[${names.map(jsonEncode).join(', ')}],')
      ..writeln('    package: ${jsonEncode(package)},')
      ..writeln('    section: ${jsonEncode(c['section'] as String)},')
      ..writeln('    useFor: ${jsonEncode(c['useFor'] as String)},')
      ..writeln('    dontUseFor: ${dont == null ? 'null' : jsonEncode(dont)},')
      ..writeln('    importPath: ${jsonEncode('package:$package/$package.dart')},')
      ..writeln('    docs: ${jsonEncode(docs)},')
      ..writeln('  ),');
  }
  buf
    ..writeln('];')
    ..writeln();
  return buf.toString();
}

/// 文档表格的列名：§8 是「能力」，其余是「组件」。
const _sectionHeader = <String, List<String>>{
  '8': <String>['能力', '子包', '说明', '**不要用在哪**'],
};

const _defaultHeader = <String>['组件', '子包', '用来做什么', '**不要用在哪**'];

/// 生成 §1~§9 的表格文本（不含标题）。
String buildTable(String section, List<YamlMap> components) {
  final header = _sectionHeader[section] ?? _defaultHeader;
  final buf = StringBuffer()
    ..writeln('| ${header.join(' | ')} |')
    ..writeln('| --- | --- | --- | --- |');
  for (final c in components) {
    final name = c['name'] as String;
    final pkg = (c['package'] as String).replaceFirst('w_tools_', '');
    final useFor = (c['useFor'] as String).replaceAll('|', r'\|');
    final dont = ((c['dontUseFor'] as String?) ?? '—').replaceAll('|', r'\|');
    buf.writeln('| $name | $pkg | $useFor | $dont |');
  }
  return buf.toString().trimRight();
}

/// 用 YAML 重写 components.md 的受管表格（marker 之间），返回新的文档内容。
///
/// 手写内容只保留在 marker 之外（如「待补」「版本」两节和表格后的说明）。
String generateDocs(String packageRoot) {
  final raw = loadYaml(File(p.join(packageRoot, 'catalog', 'components.yaml')).readAsStringSync());
  final components = (raw['components'] as YamlList).cast<YamlMap>();
  final docsPath = p.join(packageRoot, '..', '..', 'docs', 'modules', 'components.md');
  var text = File(docsPath).readAsStringSync();

  for (final section in const <String>['1', '2', '3', '4', '5', '6', '7', '8', '9']) {
    final rows = components
        .where((c) => (c['section'] as String).startsWith('$section. '))
        .toList();
    final table = buildTable(section, rows);
    final startMarker = '<!-- catalog:$section:start -->';
    final endMarker = '<!-- catalog:$section:end -->';
    final start = text.indexOf(startMarker);
    final end = text.indexOf(endMarker);
    if (start < 0 || end < 0 || end < start) {
      throw StateError('docs/modules/components.md 缺少 $startMarker / $endMarker');
    }
    text = text.replaceRange(start + startMarker.length, end, '\n$table\n');
  }
  return text;
}

void main(List<String> argv) {
  final packageRoot = Directory.current.path;
  final target = File(p.join(packageRoot, 'lib', 'src', 'catalog', 'catalog.g.dart'));
  final docsPath = p.join(packageRoot, '..', '..', 'docs', 'modules', 'components.md');
  final generated = generate(packageRoot);
  final generatedDocs = generateDocs(packageRoot);

  if (argv.contains('--check')) {
    var stale = false;
    final current = target.existsSync() ? target.readAsStringSync() : '';
    if (current != generated) {
      stderr.writeln(
        'catalog.g.dart 已过期：改了 catalog/components.yaml 之后要跑 '
        '`dart run tool/gen_catalog.dart`',
      );
      stale = true;
    }
    final currentDocs = File(docsPath).readAsStringSync();
    if (currentDocs != generatedDocs) {
      stderr.writeln('docs/modules/components.md 的组件表已过期：跑 `dart run tool/gen_catalog.dart`');
      stale = true;
    }
    if (stale) exit(1);
    print('catalog.g.dart / components.md 与 catalog/components.yaml 一致 ✓');
    return;
  }

  target.writeAsStringSync(generated);
  File(docsPath).writeAsStringSync(generatedDocs);
  print('已生成 ${p.relative(target.path, from: packageRoot)}');
  print('已生成 $docsPath');
}
