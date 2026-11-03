import 'package:flutter/material.dart';

import 'border/border.dart';
import 'form_defaults.dart';

/// 表单图标默认值的作用域版本。
///
/// 优先使用本主题中的图标；对应项为 null 时回退到 [WFormDefaults]。
/// 相比直接修改 [WFormDefaults] 静态变量，WFormTheme 可以按页面 / 品牌隔离，
/// 不会造成全局状态串扰。
class WFormTheme extends StatelessWidget {
  const WFormTheme({
    super.key,
    this.borderConfig,
    this.dropdownIcon,
    this.radioUnselectedIcon,
    this.radioSelectedIcon,
    this.checkboxUnselectedIcon,
    this.checkboxSelectedIcon,
    this.obscureTextIcon,
    this.obscureTextVisibleIcon,
    this.clearButtonIcon,
    required this.child,
  });

  final Widget child;

  /// 表单边框配置；WFormScope 未显式传 formBorderConfig 时继承本项
  final WFormBorderConfig? borderConfig;

  final Widget? dropdownIcon;
  final Widget? radioUnselectedIcon;
  final Widget? radioSelectedIcon;
  final Widget? checkboxUnselectedIcon;
  final Widget? checkboxSelectedIcon;
  final Widget? obscureTextIcon;
  final Widget? obscureTextVisibleIcon;
  final Widget? clearButtonIcon;

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

  Widget get effectiveDropdownIcon => dropdownIcon ?? WFormDefaults.dropdownIcon;
  Widget get effectiveRadioUnselectedIcon =>
      radioUnselectedIcon ?? WFormDefaults.radioUnselectedIcon;
  Widget get effectiveRadioSelectedIcon => radioSelectedIcon ?? WFormDefaults.radioSelectedIcon;
  Widget get effectiveCheckboxUnselectedIcon =>
      checkboxUnselectedIcon ?? WFormDefaults.checkboxUnselectedIcon;
  Widget get effectiveCheckboxSelectedIcon =>
      checkboxSelectedIcon ?? WFormDefaults.checkboxSelectedIcon;
  Widget get effectiveObscureTextIcon => obscureTextIcon ?? WFormDefaults.obscureTextIcon;
  Widget get effectiveObscureTextVisibleIcon =>
      obscureTextVisibleIcon ?? WFormDefaults.obscureTextVisibleIcon;
  Widget get effectiveClearButtonIcon => clearButtonIcon ?? WFormDefaults.clearButtonIcon;
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
        theme.dropdownIcon != oldWidget.theme.dropdownIcon ||
        theme.radioUnselectedIcon != oldWidget.theme.radioUnselectedIcon ||
        theme.radioSelectedIcon != oldWidget.theme.radioSelectedIcon ||
        theme.checkboxUnselectedIcon != oldWidget.theme.checkboxUnselectedIcon ||
        theme.checkboxSelectedIcon != oldWidget.theme.checkboxSelectedIcon ||
        theme.obscureTextIcon != oldWidget.theme.obscureTextIcon ||
        theme.obscureTextVisibleIcon != oldWidget.theme.obscureTextVisibleIcon ||
        theme.clearButtonIcon != oldWidget.theme.clearButtonIcon;
  }
}
