import '../common/project_pubspec.dart';

/// 生成物里给消费方的 `w_tools_figma` 安装命令。
///
/// `init` 与 `doctor` 必须用同一份计算，否则一边写带版本号的命令、另一边
/// 回放不带版本号的默认命令，会把正常项目误判成生成物漂移（R8）。
/// 没有约束时返回 null，由模板兜底成不带版本号的命令。
String? figmaInstallLine(ProjectPubspec pubspec) {
  if (!pubspec.hasDependency('w_tools_figma')) return null;
  final constraint = pubspec.constraint('w_tools_figma');
  if (constraint == null) return '# w_tools_figma 已通过 path/git 安装';
  return 'dart pub add dev:w_tools_figma:$constraint';
}
