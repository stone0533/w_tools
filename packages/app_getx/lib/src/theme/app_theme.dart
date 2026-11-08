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

  /// 亮色主题；为 null 时使用 `GetMaterialApp` 默认值。
  final ThemeData? light;

  /// 暗色主题；为 null 时使用 `GetMaterialApp` 默认值。
  final ThemeData? dark;

  /// 主题模式，默认跟随系统。
  final ThemeMode mode;

  /// 系统 UI 样式；为 null 时不主动干预。
  final SystemUiOverlayStyle? systemUiOverlayStyle;

  static const Object _unset = Object();

  WAppTheme copyWith({
    Object? light = _unset,
    Object? dark = _unset,
    ThemeMode? mode,
    Object? systemUiOverlayStyle = _unset,
  }) {
    return WAppTheme(
      light: identical(light, _unset) ? this.light : light as ThemeData?,
      dark: identical(dark, _unset) ? this.dark : dark as ThemeData?,
      mode: mode ?? this.mode,
      systemUiOverlayStyle: identical(systemUiOverlayStyle, _unset)
          ? this.systemUiOverlayStyle
          : systemUiOverlayStyle as SystemUiOverlayStyle?,
    );
  }

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
