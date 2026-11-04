// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../border/read_only_scope.dart';
import '../field_frame.dart';
import '../field_base_config.dart';
import '../field_lifecycle.dart';
import '../form_scope.dart';
import '../form_icons.dart';
import '../form_theme.dart';

/// 表单下拉选择组件
///
/// 选项由 [items] 提供（键为值、值为展示文本），选中值必须存在于 [items]；
/// 容器、提示、图标与弹层背景色等可通过 [WFormDropdownConfig] 配置，
/// 只读状态会合并外层 [WFormReadOnlyScope]。
/// 框架内部使用：普通业务用直接字段（`WFormTextField` 等），4.0 移出公共面。
@internal
class WFormDropdownCore<T> extends StatelessWidget {
  /// 下拉选择配置
  final WFormDropdownConfig config;

  /// 字段名称
  final String name;

  /// 选项映射，键为值，值为显示文本
  ///
  /// 初始值 / 字段值必须存在于 [items] 中，否则底层 `FormBuilderDropdown` 会断言失败。
  final Map<T, String> items;

  /// 初始值
  final T? initialValue;

  /// 值变化回调
  final ValueChanged<T?>? onChanged;

  /// 校验器
  final FormFieldValidator<T>? validator;

  /// 提示 widget（优先于 [hintText]）
  final Widget? hint;

  /// 提示文本
  final String? hintText;

  /// 是否启用（null 时使用 [WFormDropdownConfig.enabled]）
  final bool? enabled;

  /// 宽度
  final double? width;

  /// 创建下拉选择组件
  const WFormDropdownCore({
    super.key,
    required this.config,
    required this.name,
    required this.items,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.hint,
    this.hintText,
    this.enabled,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = WFormTheme.maybeOf(context);
    final wFormData = WFormScope.requireOf(context);

    void onChangedHandler(T? value) {
      wFormData.handleChange(name, value);
      onChanged?.call(value);
    }

    Widget? hintWidget;

    if (hint != null) {
      hintWidget = hint;
    } else if (hintText != null) {
      hintWidget = Center(child: Text(hintText!, style: config.hintStyle));
    } else if (config.hint != null) {
      hintWidget = config.hint;
    }

    // 继承外层只读作用域（WFormFieldShell.readOnly）
    final effectiveEnabled = (enabled ?? config.enabled) && !WFormReadOnlyScope.readOnlyOf(context);

    return WFormFieldCleanup(
      name: name,
      child: WFormFieldFrame(
        height: config.height,
        width: width ?? config.width,
        decoration: config.containerDecoration,
        margin: config.containerMargin,
        padding: config.containerPadding,
        yOffset: config.yOffset,
        leading: config.leading,
        actions: config.actions,
        child: FormBuilderDropdown<T>(
          name: name,
          items: items.entries
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e.key,
                  child: Text(
                    e.value,
                    style: config.style,
                    strutStyle: StrutStyle(
                      fontFamily: config.style?.fontFamily,
                      fontSize: config.style?.fontSize,
                      fontWeight: config.style?.fontWeight,
                      height: config.style?.height,
                      forceStrutHeight: true,
                    ),
                  ),
                ),
              )
              .toList(),
          decoration: InputDecoration(
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            contentPadding: config.contentPadding,
          ),
          initialValue: initialValue,
          validator: validator,
          icon: config.icon ?? theme?.effectiveDropdownIcon ?? WFormIcons.defaults.dropdown,
          onChanged: onChangedHandler,
          hint: hintWidget,
          enabled: effectiveEnabled,
          dropdownColor: config.dropdownColor,
        ),
      ),
    );
  }
}

/// 下拉选择配置类，定义下拉选择的样式和行为。
///
/// 可变的字段配置；用命名构造 / copyWith。
/// remove-in: 5.0.0
@Deprecated('Use direct field parameters / WFormFieldStyle; removed in form 5.0')
class WFormDropdownConfig extends WFormFieldBaseConfig {
  EdgeInsetsGeometry? contentPadding;
  Widget? hint;
  Widget? icon;
  TextStyle? style;
  TextStyle? hintStyle;
  Color? dropdownColor;

  WFormDropdownConfig({
    bool enabled = true,
    double? height,
    double? width,
    this.contentPadding,
    double? yOffset,
    Widget? leading,
    List<Widget>? actions,
    Decoration? containerDecoration,
    EdgeInsetsGeometry? containerMargin,
    EdgeInsetsGeometry? containerPadding,
    this.hint,
    this.icon,
    this.style,
    this.hintStyle,
    this.dropdownColor,
  }) {
    this.enabled = enabled;
    this.height = height;
    this.width = width;
    this.yOffset = yOffset;
    this.leading = leading;
    this.actions = actions;
    this.containerDecoration = containerDecoration;
    this.containerMargin = containerMargin;
    this.containerPadding = containerPadding;
  }

  Widget build<T>({
    required String name,
    required Map<T, String> items,
    T? initialValue,
    ValueChanged<T?>? onChanged,
    FormFieldValidator<T>? validator,
    Widget? hint,
    String? hintText,
    bool? enabled,
    double? width,
    bool readOnly = false,
    bool bordered = false,
    List<String>? hintTextList,
    bool? isTransparentBackground,
    bool enableFocusBorder = true,
  }) {
    final baseEnabled = enabled ?? this.enabled;
    final config = bordered ? (copy()..containerDecoration = null) : this;
    final dropdown = WFormDropdownCore<T>(
      config: config,
      name: name,
      items: items,
      initialValue: initialValue,
      onChanged: onChanged,
      validator: validator,
      hint: hint,
      hintText: hintText,
      enabled: bordered ? baseEnabled && !readOnly : enabled,
      width: width,
    );
    if (!bordered) {
      return readOnly ? WFormReadOnlyScope(readOnly: true, child: dropdown) : dropdown;
    }
    return WFormFieldFrame.border(
      name: name,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      enableFocusBorder: enableFocusBorder,
      readOnly: readOnly || !baseEnabled,
      child: dropdown,
    );
  }

  WFormDropdownConfig copy() => copyWith();

  WFormDropdownConfig copyWith({
    bool? enabled,
    double? height,
    double? width,
    EdgeInsetsGeometry? contentPadding,
    double? yOffset,
    Widget? leading,
    List<Widget>? actions,
    Decoration? containerDecoration,
    EdgeInsetsGeometry? containerMargin,
    EdgeInsetsGeometry? containerPadding,
    Widget? hint,
    Widget? icon,
    TextStyle? style,
    TextStyle? hintStyle,
    Color? dropdownColor,
  }) {
    return WFormDropdownConfig(
      enabled: enabled ?? this.enabled,
      height: height ?? this.height,
      width: width ?? this.width,
      contentPadding: contentPadding ?? this.contentPadding,
      yOffset: yOffset ?? this.yOffset,
      leading: leading ?? this.leading,
      actions: actions ?? this.actions,
      containerDecoration: containerDecoration ?? this.containerDecoration,
      containerMargin: containerMargin ?? this.containerMargin,
      containerPadding: containerPadding ?? this.containerPadding,
      hint: hint ?? this.hint,
      icon: icon ?? this.icon,
      style: style ?? this.style,
      hintStyle: hintStyle ?? this.hintStyle,
      dropdownColor: dropdownColor ?? this.dropdownColor,
    );
  }
}
