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
    this.aliases = const <String>[],
    this.usage,
    this.pitfalls = const <String>[],
    this.related = const <String>[],
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

  /// 方法名 / 旧名等补充别名；不参与展示名。
  final List<String> aliases;

  /// 最短用法，给 explain / AI 查询使用。
  final String? usage;

  /// 常见坑，explain --format=prompt 使用。
  final List<String> pitfalls;

  /// 相关组件名。
  final List<String> related;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'names': names,
    'package': package,
    'section': section,
    'useFor': useFor,
    if (dontUseFor != null) 'dontUseFor': dontUseFor,
    'import': importPath,
    'docs': docs,
    'aliases': aliases,
    if (usage != null) 'usage': usage,
    'pitfalls': pitfalls,
    'related': related,
  };
}
