import 'package:flutter/material.dart';

import 'border/border.dart';
import 'form_icons.dart';
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
/// 校验设置：显式传 [validatorSettings] 时完全以它为准；未传时注入
/// `WFormValidatorSettings()..showBorderError = true`，保证 `validate()` 失败时
/// 至少有边框错误可看。没有边框样式（例如显式 `const WFormBorderConfig()`）时
/// 不会渲染文案，效果等同“没有错误展示”。
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
    this.icons,
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

  /// 图标集合（单个 `xxxIcon` 参数优先）
  final WFormIcons? icons;

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
  WFormValidatorSettings? _settings;

  /// 主题派生的默认边框配置（按 ThemeData 实例缓存，避免每帧重建）
  WFormBorderConfig? _defaultBorderConfig;
  ThemeData? _defaultBorderTheme;

  @override
  void initState() {
    super.initState();
    _syncSettings();
  }

  void _syncSettings() {
    // 现在默认边框一定存在（显式 / 祖先主题 / fromTheme），
    // 未显式配置校验设置时默认把错误显示在边框上。
    _settings = widget.validatorSettings ?? (WFormValidatorSettings()..showBorderError = true);
    widget.controller.validatorSettings = _settings;
  }

  /// 边框配置解析：显式参数 > 祖先 [WFormBorderConfigScope] > 主题派生默认值。
  WFormBorderConfig? _resolveBorderConfig(BuildContext context) {
    final explicit = widget.borderConfig;
    if (explicit != null) return explicit;

    final inherited = WFormBorderConfigScope.maybeOf(context);
    if (inherited != null) return inherited;

    final theme = Theme.of(context);
    if (!identical(_defaultBorderTheme, theme) || _defaultBorderConfig == null) {
      _defaultBorderTheme = theme;
      _defaultBorderConfig = WFormBorderConfig.fromTheme(theme);
    }
    return _defaultBorderConfig;
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
      icons: widget.icons,
      borderConfig: _resolveBorderConfig(context),
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
