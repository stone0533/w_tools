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
///
/// 校验设置：显式传 [validatorSettings] 时完全以它为准；只传 [borderConfig]
/// 时默认 `showBorderError = true` —— 否则 `validate()` 失败时界面没有任何反馈。
/// 两者都不传时不注入默认值（保持"没有边框就没有错误展示"的历史语义）。
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
  /// 实际生效的校验设置：显式传入优先；只传了 borderConfig 时默认显示边框错误，
  /// 否则 `validate()` 失败不会有任何可见反馈（默认 WFormValidatorSettings 是关的）。
  WFormValidatorSettings? _settings;

  @override
  void initState() {
    super.initState();
    _syncSettings();
  }

  void _syncSettings() {
    _settings =
        widget.validatorSettings ??
        (widget.borderConfig == null
            ? null
            : (WFormValidatorSettings()..showBorderError = true));
    widget.controller.validatorSettings = _settings;
  }

  @override
  void didUpdateWidget(covariant WForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.validatorSettings != widget.validatorSettings ||
        oldWidget.borderConfig != widget.borderConfig) {
      _syncSettings();
    }
  }

  @override
  void dispose() {
    if (widget.controller.validatorSettings == _settings) {
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
