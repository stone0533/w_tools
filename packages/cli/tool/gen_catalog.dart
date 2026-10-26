// 把 catalog/components.yaml 生成成 Dart 常量（lib/src/catalog/catalog.g.dart）。
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
  'w_tools_ui': 'docs/modules/ui_module.md',
  'w_tools_form': 'docs/modules/form_module.md',
  'w_tools_api': 'docs/modules/api_module.md',
  'w_tools_toast': 'docs/modules/toast_module.md',
  'w_tools_qr': 'docs/modules/qr_module.md',
  'w_tools_map': 'docs/modules/map_module.md',
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

void main(List<String> argv) {
  final packageRoot = Directory.current.path;
  final target = File(p.join(packageRoot, 'lib', 'src', 'catalog', 'catalog.g.dart'));
  final generated = generate(packageRoot);
  if (argv.contains('--check')) {
    final current = target.existsSync() ? target.readAsStringSync() : '';
    if (current != generated) {
      stderr.writeln(
        'catalog.g.dart 已过期：改了 catalog/components.yaml 之后要跑 '
        '`dart run tool/gen_catalog.dart`',
      );
      exit(1);
    }
    print('catalog.g.dart 与 catalog/components.yaml 一致 ✓');
    return;
  }
  target.writeAsStringSync(generated);
  print('已生成 ${p.relative(target.path, from: packageRoot)}');
}
