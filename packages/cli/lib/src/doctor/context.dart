import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'config.dart';

/// 扫描上下文：项目根、pubspec、待查的 dart 文件。
class ProjectContext {
  ProjectContext({
    required this.root,
    required this.pubspec,
    required this.files,
  });

  final Directory root;

  /// pubspec.yaml 解析后的内容（未解析成功时为空 map）
  final YamlMap pubspec;

  /// 需要扫描的 dart 文件（相对路径）
  final List<String> files;

  String get name => (pubspec['name'] as String?) ?? p.basename(root.path);

  static ProjectContext load(Directory root, DoctorConfig config, {bool includeTests = false}) {
    final pubspecFile = File(p.join(root.path, 'pubspec.yaml'));
    YamlMap pubspec = YamlMap();
    if (pubspecFile.existsSync()) {
      final raw = loadYaml(pubspecFile.readAsStringSync());
      if (raw is YamlMap) pubspec = raw;
    }

    final roots = <String>['lib'];
    if (includeTests) roots.addAll(<String>['test', 'tool']);

    final files = <String>[];
    for (final dir in roots) {
      final d = Directory(p.join(root.path, dir));
      if (!d.existsSync()) continue;
      for (final entity in d.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final rel = p.relative(entity.path, from: root.path).replaceAll('\\', '/');
        if (rel.endsWith('.g.dart') || rel.endsWith('.freezed.dart')) continue;
        if (config.ignore.any((raw) => _matchesIgnore(rel, raw))) continue;
        files.add(rel);
      }
    }
    files.sort();
    return ProjectContext(root: root, pubspec: pubspec, files: files);
  }

  String read(String relPath) => File(p.join(root.path, relPath)).readAsStringSync();

  /// 忽略项按路径前缀匹配：`lib/app/generated` 只命中该目录及其子文件，
  /// 不会误伤 `lib/app/generated2/`。
  static bool _matchesIgnore(String rel, String raw) {
    final prefix = raw.replaceAll('*', '');
    if (rel == prefix) return true;
    final withSlash = prefix.endsWith('/') ? prefix : '$prefix/';
    return rel.startsWith(withSlash);
  }

  /// 只取 `lib/` 或 `test/` 等前缀下的文件。
  Iterable<String> filesUnder(String prefix) =>
      files.where((f) => f == prefix || f.startsWith('$prefix/'));
}
