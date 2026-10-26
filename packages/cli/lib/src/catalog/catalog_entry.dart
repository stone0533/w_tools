/// 组件目录中的一条记录。
class CatalogEntry {
  const CatalogEntry({
    required this.name,
    required this.names,
    required this.package,
    required this.section,
    required this.useFor,
    required this.importPath,
    required this.docs,
    this.dontUseFor,
  });

  /// 展示名（可能包含多个组件，如 `WText / WTextConfig`）
  final String name;

  /// 可用于查询的别名（已去除反引号与 `*`）
  final List<String> names;

  final String package;
  final String section;
  final String useFor;
  final String? dontUseFor;
  final String importPath;

  /// 仓库内文档路径（消费方可按需拼接仓库 URL）
  final String docs;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'names': names,
    'package': package,
    'section': section,
    'useFor': useFor,
    if (dontUseFor != null) 'dontUseFor': dontUseFor,
    'import': importPath,
    'docs': docs,
  };
}
