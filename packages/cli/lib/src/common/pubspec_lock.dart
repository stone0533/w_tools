import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// 读取 `pubspec.lock` 里已解析的包版本。
Map<String, String> readLockedVersions(Directory root) {
  final file = File(p.join(root.path, 'pubspec.lock'));
  if (!file.existsSync()) return const <String, String>{};
  final raw = loadYaml(file.readAsStringSync());
  if (raw is! YamlMap) return const <String, String>{};
  final packages = raw['packages'];
  if (packages is! YamlMap) return const <String, String>{};
  final out = <String, String>{};
  packages.forEach((key, value) {
    if (value is YamlMap && value['version'] is String) {
      out['$key'] = value['version'] as String;
    }
  });
  return out;
}
