import 'package:flutter/material.dart';

import 'border/border.dart';
import 'form_defaults.dart';

/// 表单图标默认值的作用域版本。
///
/// 优先使用本主题中的图标；对应项为 null 时回退到 [WFormDefaults]。
/// 相比直接修改 [WFormDefaults] 静态变量，WFormTheme 可以按页面 / 品牌隔离，
/// 不会造成全局状态串扰。
class WFormTheme extends InheritedWidget {
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
    required super.child,
  });

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
    return context.dependOnInheritedWidgetOfExactType<WFormTheme>();
  }

  @override
  bool updateShouldNotify(WFormTheme oldWidget) {
    return borderConfig != oldWidget.borderConfig ||
        dropdownIcon != oldWidget.dropdownIcon ||
        radioUnselectedIcon != oldWidget.radioUnselectedIcon ||
        radioSelectedIcon != oldWidget.radioSelectedIcon ||
        checkboxUnselectedIcon != oldWidget.checkboxUnselectedIcon ||
        checkboxSelectedIcon != oldWidget.checkboxSelectedIcon ||
        obscureTextIcon != oldWidget.obscureTextIcon ||
        obscureTextVisibleIcon != oldWidget.obscureTextVisibleIcon ||
        clearButtonIcon != oldWidget.clearButtonIcon;
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
