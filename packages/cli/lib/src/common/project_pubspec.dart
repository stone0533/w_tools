import 'dart:io';

import 'package:yaml/yaml.dart';

/// 读取 pubspec.yaml 的共享视图。
///
/// `init` / `init_options` / `R1` 等只关心“声明了哪些依赖”，不应该各自
/// 再写一份 YAML 解析和错误兜底。这里保持轻量、容错：文件缺失或 YAML 损坏时
/// 返回空视图，由调用方决定是否报错。
class ProjectPubspec {
  const ProjectPubspec._({
    required this.raw,
    required this.dependencies,
    required this.devDependencies,
    this.parseError,
  });

  final YamlMap raw;
  final Map<String, Object?> dependencies;
  final Map<String, Object?> devDependencies;

  /// YAML 语法错误信息；文件缺失或不是 map 时为 null。
  final String? parseError;

  bool get hasDependenciesSection => raw['dependencies'] is YamlMap;

  bool get hasDevDependenciesSection => raw['dev_dependencies'] is YamlMap;

  String? get declaredName {
    final value = raw['name'];
    if (value is! String) return null;
    final name = value.trim();
    return name.isEmpty ? null : name;
  }

  bool get isFlutter => dependencies.containsKey('flutter');

  bool get usesAggregate => hasDependency('w_tools');

  bool hasDependency(String name) =>
      dependencies.containsKey(name) || devDependencies.containsKey(name);

  /// 声明的版本约束；path / git / map 依赖返回 null。
  String? constraint(String name) {
    final value = dependencies[name] ?? devDependencies[name];
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  static ProjectPubspec load(Directory root) {
    final file = File('${root.path}/pubspec.yaml');
    if (!file.existsSync()) return empty;
    try {
      final raw = loadYaml(file.readAsStringSync());
      if (raw is! YamlMap) return empty;
      return ProjectPubspec._(
        raw: raw,
        dependencies: _stringMap(raw['dependencies']),
        devDependencies: _stringMap(raw['dev_dependencies']),
      );
    } on YamlException catch (e) {
      return ProjectPubspec._(
        raw: YamlMap(),
        dependencies: const <String, Object?>{},
        devDependencies: const <String, Object?>{},
        parseError: e.message,
      );
    }
  }

  static final empty = ProjectPubspec._(
    raw: YamlMap(),
    dependencies: const <String, Object?>{},
    devDependencies: const <String, Object?>{},
  );

  static Map<String, Object?> _stringMap(Object? node) {
    if (node is! YamlMap) return const <String, Object?>{};
    return <String, Object?>{for (final entry in node.entries) '${entry.key}': entry.value};
  }
}
