import 'package:flutter/material.dart';

import 'border/border.dart';
import 'form_icons.dart';

/// 表单主题的**数据**部分：图标集合 + 边框样式。
///
/// 不可变、可比较；由 [WFormTheme] 放进子树，用 [of] 读取。
/// 字段只依赖本类，不依赖 [WFormTheme] 这个 widget。
class WFormThemeData {
  const WFormThemeData({this.icons, this.borderStyle});

  /// 图标集合；未配置项回退 [WFormIcons.defaults]
  final WFormIcons? icons;

  /// 表单边框样式；由 `WForm` / `WFormTheme` 统一写入
  final WFormBorderStyle? borderStyle;

  /// 读取最近的表单主题数据（无祖先时返回 null）
  static WFormThemeData? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_WFormThemeInherited>()?.data;

  Widget get effectiveDropdownIcon => icons?.dropdown ?? WFormIcons.defaults.dropdown;

  Widget get effectiveRadioUnselectedIcon =>
      icons?.radioUnselected ?? WFormIcons.defaults.radioUnselected;

  Widget get effectiveRadioSelectedIcon =>
      icons?.radioSelected ?? WFormIcons.defaults.radioSelected;

  Widget get effectiveCheckboxUnselectedIcon =>
      icons?.checkboxUnselected ?? WFormIcons.defaults.checkboxUnselected;

  Widget get effectiveCheckboxSelectedIcon =>
      icons?.checkboxSelected ?? WFormIcons.defaults.checkboxSelected;

  Widget get effectiveObscureTextIcon => icons?.obscureText ?? WFormIcons.defaults.obscureText;

  Widget get effectiveObscureTextVisibleIcon =>
      icons?.obscureTextVisible ?? WFormIcons.defaults.obscureTextVisible;

  Widget get effectiveClearButtonIcon => icons?.clear ?? WFormIcons.defaults.clear;

  @override
  bool operator ==(Object other) =>
      other is WFormThemeData && other.icons == icons && other.borderStyle == borderStyle;

  @override
  int get hashCode => Object.hash(icons, borderStyle);
}

/// 表单主题的作用域容器：把 [WFormThemeData] 放进子树。
///
/// 优先使用本主题中的图标；对应项为 null 时回退到 [WFormIcons.defaults]。
/// 可以按页面 / 品牌隔离，不会造成全局状态串扰。
class WFormTheme extends StatelessWidget {
  const WFormTheme({
    super.key,
    this.borderStyle,
    this.icons,
    required this.child,
  });

  final Widget child;

  /// 表单边框样式；未传时继承外层 `WFormThemeData.borderStyle`
  final WFormBorderStyle? borderStyle;

  /// 图标集合；未配置项回退 [WFormIcons.defaults]
  final WFormIcons? icons;

  @override
  Widget build(BuildContext context) {
    final inherited = WFormThemeData.of(context);
    final data = WFormThemeData(
      icons: icons ?? inherited?.icons,
      borderStyle: borderStyle ?? inherited?.borderStyle,
    );
    // 显式参数优先于祖先主题（嵌套 WForm / WFormTheme 时，里层的配置说了算）。
    return _WFormThemeInherited(data: data, child: child);
  }
}

/// WFormTheme 的 InheritedWidget 载体。
class _WFormThemeInherited extends InheritedWidget {
  const _WFormThemeInherited({
    required this.data,
    required super.child,
  });

  final WFormThemeData data;

  @override
  bool updateShouldNotify(_WFormThemeInherited oldWidget) => data != oldWidget.data;
}
