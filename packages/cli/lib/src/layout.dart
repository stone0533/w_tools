/// init 生成物与 doctor 检查共用的**唯一**路径来源。
///
/// 这些目录是约定的一部分（见 `docs/conventions.md` §7），不允许项目自定义：
/// 一旦 init 写 A、doctor 查 B，就会出现「刚 init 完 doctor 说没初始化」。
/// 需要覆盖的只有聚合入口文件名，通过 `.w_tools_doctor.yaml` 的 `toolkit_entry`，
/// 且 init 与 doctor 都要读同一份配置。
class ProjectLayout {
  const ProjectLayout._();

  /// 项目永久 UI 规范层
  static const projectUiDir = 'lib/app/ui';

  /// 暂存层（待上移进 w_tools 的组件）
  static const designSystemDir = 'lib/app/design_system';

  /// 聚合入口（唯一允许直接 import/export 子包的文件）
  static const toolkitEntry = 'lib/app/w/toolkit.dart';
}
