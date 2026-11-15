import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 应用外观配置：亮/暗主题、主题模式与系统 UI 样式。
///
/// 这是应用级的外观值对象，不属于组件 `Options`；`WAppOptions.theme` 使用它。
@immutable
class WAppTheme {
  const WAppTheme({
    this.light,
    this.dark,
    this.mode = ThemeMode.system,
    this.systemUiOverlayStyle,
  });

  /// 亮色主题；为 null 时不覆盖应用壳的默认主题。
  final ThemeData? light;

  /// 暗色主题；为 null 时不覆盖应用壳的默认主题。
  final ThemeData? dark;

  /// 主题模式，默认跟随系统。
  final ThemeMode mode;

  /// 系统 UI 样式；默认 null，不主动设置系统栏。
  ///
  /// 需要固定状态栏 / 导航栏样式时显式传入，例如
  /// `SystemUiOverlayStyle(statusBarColor: Colors.transparent)`。
  final SystemUiOverlayStyle? systemUiOverlayStyle;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WAppTheme &&
        other.light == light &&
        other.dark == dark &&
        other.mode == mode &&
        other.systemUiOverlayStyle == systemUiOverlayStyle;
  }

  @override
  int get hashCode => Object.hash(light, dark, mode, systemUiOverlayStyle);
}
