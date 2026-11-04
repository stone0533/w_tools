import '../catalog/catalog_entry.dart';

/// 生成给 AI 的紧凑 prompt；调用方负责提供最终 import 与文档 URL。
String renderExplainPrompt(
  CatalogEntry entry, {
  required String importPath,
  required String docsUrl,
}) {
  final b = StringBuffer()
    ..writeln('# ${entry.name} (${entry.package})')
    ..writeln(entry.useFor)
    ..writeln()
    ..writeln("import '$importPath';");
  if (entry.usage != null) {
    b
      ..writeln()
      ..writeln('用法：')
      ..writeln(entry.usage);
  }
  if (entry.pitfalls.isNotEmpty) {
    b
      ..writeln()
      ..writeln('注意：');
    for (final pitfall in entry.pitfalls) {
      b.writeln('- $pitfall');
    }
  }
  if (entry.related.isNotEmpty) {
    b
      ..writeln()
      ..writeln('相关：${entry.related.join(' / ')}');
  }
  b
    ..writeln()
    ..writeln('文档：$docsUrl');
  return b.toString().trimRight();
}
