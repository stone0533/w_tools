import 'package:flutter/material.dart';

import 'border/border.dart';
import 'border/read_only_scope.dart';
import 'form_scope.dart';
import 'form_field_style.dart';
import 'form_theme.dart';
import 'validation/validator.dart';
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
class WForm extends StatefulWidget {
  const WForm({
    super.key,
    required this.controller,
    required this.child,
    this.borderConfig,
    this.fieldStyle,
    this.validatorSettings,
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
  final WFormFieldStyle? fieldStyle;
  final WFormValidatorSettings? validatorSettings;
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
  State<WForm> createState() => _WFormState();
}

class _WFormState extends State<WForm> {
  @override
  void initState() {
    super.initState();
    widget.controller.validatorSettings = widget.validatorSettings;
  }

  @override
  void didUpdateWidget(covariant WForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.validatorSettings != widget.validatorSettings) {
      widget.controller.validatorSettings = widget.validatorSettings;
    }
  }

  @override
  void dispose() {
    if (widget.controller.validatorSettings == widget.validatorSettings) {
      widget.controller.validatorSettings = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WFormTheme(
      borderConfig: widget.borderConfig,
      dropdownIcon: widget.dropdownIcon,
      radioUnselectedIcon: widget.radioUnselectedIcon,
      radioSelectedIcon: widget.radioSelectedIcon,
      checkboxUnselectedIcon: widget.checkboxUnselectedIcon,
      checkboxSelectedIcon: widget.checkboxSelectedIcon,
      obscureTextIcon: widget.obscureTextIcon,
      obscureTextVisibleIcon: widget.obscureTextVisibleIcon,
      clearButtonIcon: widget.clearButtonIcon,
      child: WFormFieldStyleScope(
        style: widget.fieldStyle,
        child: WFormScope(
          formData: widget.controller,
          autovalidateMode: widget.autovalidateMode,
          child: WFormReadOnlyScope(
            readOnly: widget.readOnly,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
