import 'dart:io';

import 'package:yaml/yaml.dart' show YamlException;

import '../doctor/config.dart';
import 'project_pubspec.dart';

/// 项目级配置读取错误；命令层统一转成可读提示。
class ProjectLoadException implements Exception {
  const ProjectLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 项目事实：package name + 聚合入口。
class ProjectInfo {
  const ProjectInfo({required this.name, required this.toolkitEntry});

  final String name;

  /// 仓库内路径，如 lib/app/w/toolkit.dart
  final String toolkitEntry;

  /// 消费方可直接 import 的聚合入口；入口文件不存在时为 null
  String? get packageImport {
    final path = toolkitEntry.replaceFirst(RegExp(r'^lib/'), '');
    return path == toolkitEntry ? null : 'package:$name/$path';
  }
}

/// 命令层共用的项目加载入口。
class ProjectFiles {
  static DoctorConfig loadConfig(Directory root) {
    try {
      return DoctorConfig.load(root);
    } on YamlException catch (e) {
      throw ProjectLoadException('${DoctorConfig.fileName} 解析失败：${e.message}');
    } on DoctorConfigException catch (e) {
      throw ProjectLoadException('${DoctorConfig.fileName} 配置错误：${e.message}');
    }
  }

  /// 读取 pubspec name 与配置中的 toolkit 入口；缺失/非法 pubspec 时抛
  /// [ProjectLoadException]，而不是让 yaml 类型错误冒成 TypeError。
  static ProjectInfo loadProject(Directory root) {
    final file = File('${root.path}/pubspec.yaml');
    if (!file.existsSync()) {
      throw ProjectLoadException('找不到 pubspec.yaml：${root.path}（用 --root=<dir> 指定项目根）');
    }
    final pubspec = ProjectPubspec.load(root);
    if (pubspec.parseError != null) {
      throw ProjectLoadException('pubspec.yaml 解析失败：${pubspec.parseError}');
    }
    final name = pubspec.declaredName;
    if (name == null) {
      throw const ProjectLoadException('pubspec.yaml 缺少合法的 name');
    }
    final config = loadConfig(root);
    return ProjectInfo(name: name, toolkitEntry: config.toolkitEntry);
  }
}
