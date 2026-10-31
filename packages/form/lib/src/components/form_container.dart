import 'package:flutter/material.dart';

import 'border/border.dart';
import 'border/read_only_scope.dart';
import 'form_scope.dart';
import 'form_theme.dart';
import 'form_controller.dart';

/// 表单页面容器。
///
/// 一次性组合 [WFormTheme]、[WFormScope] 与 [WFormReadOnlyScope]，
/// 业务页面不再需要重复写三层嵌套。
///
/// ```dart
/// WForm(
///   controller: form,
///   borderConfig: WFormBorderConfig.standard(),
///   child: ListView(...),
/// )
/// ```
class WForm extends StatelessWidget {
  const WForm({
    super.key,
    required this.controller,
    required this.child,
    this.borderConfig,
    this.readOnly = false,
    this.autovalidateMode,
    this.dropdownIcon,
    this.radioUnselectedIcon,
    this.radioSelectedIcon,
    this.checkboxUnselectedIcon,
    this.checkboxSelectedIcon,
    this.obscureTextIcon,
    this.obscureTextVisibleIcon,
    this.clearButtonIcon,
  });

  final WFormController controller;
  final Widget child;
  final WFormBorderConfig? borderConfig;
  final bool readOnly;
  final AutovalidateMode? autovalidateMode;

  final Widget? dropdownIcon;
  final Widget? radioUnselectedIcon;
  final Widget? radioSelectedIcon;
  final Widget? checkboxUnselectedIcon;
  final Widget? checkboxSelectedIcon;
  final Widget? obscureTextIcon;
  final Widget? obscureTextVisibleIcon;
  final Widget? clearButtonIcon;

  @override
  Widget build(BuildContext context) {
    return WFormTheme(
      borderConfig: borderConfig,
      dropdownIcon: dropdownIcon,
      radioUnselectedIcon: radioUnselectedIcon,
      radioSelectedIcon: radioSelectedIcon,
      checkboxUnselectedIcon: checkboxUnselectedIcon,
      checkboxSelectedIcon: checkboxSelectedIcon,
      obscureTextIcon: obscureTextIcon,
      obscureTextVisibleIcon: obscureTextVisibleIcon,
      clearButtonIcon: clearButtonIcon,
      child: WFormScope(
        formData: controller,
        autovalidateMode: autovalidateMode,
        child: WFormReadOnlyScope(
          readOnly: readOnly,
          child: child,
        ),
      ),
    );
  }
}
