import '../catalog/catalog_entry.dart';

/// 生成给 AI 的紧凑 prompt；调用方负责提供最终 import 与文档 URL。
String renderExplainPrompt(
  CatalogEntry entry, {
  required String importPath,
  required String docsUrl,
  String? exampleUrl,
  String? packageVersion,
  String? apiDocsUrl,
}) {
  final b = StringBuffer()
    ..writeln('# ${entry.name} (${entry.package})')
    ..writeln(entry.useFor)
    ..writeln()
    ..writeln("import '$importPath';");
  if (packageVersion != null && packageVersion.isNotEmpty) {
    b.writeln('包版本：${entry.package} $packageVersion');
  }
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
  if (exampleUrl != null) {
    b
      ..writeln()
      ..writeln('示例：$exampleUrl');
  }
  b
    ..writeln()
    ..writeln('文档：$docsUrl');
  if (apiDocsUrl != null && apiDocsUrl.isNotEmpty) {
    b.writeln('API 文档：$apiDocsUrl');
  }
  return b.toString().trimRight();
}
