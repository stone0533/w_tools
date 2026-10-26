import 'catalog.g.dart';
import 'catalog_entry.dart';

export 'catalog_entry.dart' show CatalogEntry;

/// 组件目录的 schema 版本
int get catalogVersion => catalogSchemaVersion;

/// 全部组件（只读）
List<CatalogEntry> get catalog => catalogEntries;

/// 精确查找（按任一别名，大小写不敏感）
CatalogEntry? findComponent(String name) {
  final q = name.toLowerCase();
  for (final entry in catalogEntries) {
    if (entry.names.any((n) => n.toLowerCase() == q)) return entry;
  }
  return null;
}

/// 关键词搜索：名字、别名、用途、反例、分组任一命中
List<CatalogEntry> searchComponents(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return catalogEntries;
  return catalogEntries.where((entry) {
    if (entry.names.any((n) => n.toLowerCase().contains(q))) return true;
    if (entry.name.toLowerCase().contains(q)) return true;
    if (entry.useFor.toLowerCase().contains(q)) return true;
    if (entry.section.toLowerCase().contains(q)) return true;
    final dont = entry.dontUseFor;
    return dont != null && dont.toLowerCase().contains(q);
  }).toList();
}
