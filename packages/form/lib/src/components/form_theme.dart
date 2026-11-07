import 'package:flutter/material.dart';

import 'border/border.dart';
import 'form_icons.dart';

/// 表单图标默认值的作用域版本。
///
/// 优先使用本主题中的图标；对应项为 null 时回退到 [WFormIcons.defaults]。
/// WFormTheme 可以按页面 / 品牌隔离，
/// 不会造成全局状态串扰。
class WFormTheme extends StatelessWidget {
  const WFormTheme({
    super.key,
    this.borderConfig,
    this.icons,
    required this.child,
  });

  final Widget child;

  /// 表单边框配置；WFormScope 未显式传 formBorderConfig 时继承本项
  final WFormBorderConfig? borderConfig;

  /// 图标集合；未配置项回退 [WFormIcons.defaults]
  final WFormIcons? icons;

  static WFormTheme? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_WFormThemeInherited>()?.theme;
  }

  @override
  Widget build(BuildContext context) {
    final inherited = WFormBorderConfigScope.maybeOf(context);
    // 显式参数优先于祖先作用域（嵌套 WForm / WFormTheme 时，里层的配置说了算）
    return _WFormThemeInherited(
      theme: this,
      child: WFormBorderConfigScope(
        config: borderConfig ?? inherited,
        child: child,
      ),
    );
  }

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
}

/// WFormTheme 的 InheritedWidget 载体。
class _WFormThemeInherited extends InheritedWidget {
  const _WFormThemeInherited({
    required this.theme,
    required super.child,
  });

  final WFormTheme theme;

  @override
  bool updateShouldNotify(_WFormThemeInherited oldWidget) {
    return theme.borderConfig != oldWidget.theme.borderConfig ||
        theme.icons != oldWidget.theme.icons;
  }
}
