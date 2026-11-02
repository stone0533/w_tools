import 'dart:io';

import 'package:yaml/yaml.dart' show YamlException;

import '../doctor/config.dart';

/// 项目级配置读取错误；命令层统一转成可读提示。
class ProjectLoadException implements Exception {
  const ProjectLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 命令层共用的项目加载入口。
class ProjectFiles {
  static DoctorConfig loadConfig(Directory root) {
    try {
      return DoctorConfig.load(root);
    } on YamlException catch (e) {
      throw ProjectLoadException('${DoctorConfig.fileName} 解析失败：${e.message}');
    }
  }
}
