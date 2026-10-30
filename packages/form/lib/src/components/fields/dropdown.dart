import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../border/read_only_scope.dart';
import '../field_frame.dart';
import '../field_chrome.dart';
import '../form_scope.dart';
import '../form_defaults.dart';
import '../form_theme.dart';

/// 表单下拉选择组件
///
/// 选项由 [items] 提供（键为值、值为展示文本），选中值必须存在于 [items]；
/// 容器、提示、图标与弹层背景色等可通过 [WFormDropdownConfig] 配置，
/// 只读状态会合并外层 [WFormReadOnlyScope]。
class WFormDropdown<T> extends StatelessWidget {
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
  const WFormDropdown({
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
      hintWidget = Center(child: Text(hintText!, style: config._hintStyle));
    } else if (config._hint != null) {
      hintWidget = config._hint;
    }

    // 继承外层只读作用域（WFormFieldShell.readOnly）
    final effectiveEnabled = (enabled ?? config.enabled) && !WFormReadOnlyScope.readOnlyOf(context);

    return WFormFieldFrame(
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
                  style: config._style,
                  strutStyle: StrutStyle(
                    fontFamily: config._style?.fontFamily,
                    fontSize: config._style?.fontSize,
                    fontWeight: config._style?.fontWeight,
                    height: config._style?.height,
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
          contentPadding: config._contentPadding,
        ),
        initialValue: initialValue,
        validator: validator,
        icon: config._icon ?? theme?.effectiveDropdownIcon ?? WFormDefaults.dropdownIcon,
        onChanged: onChangedHandler,
        hint: hintWidget,
        enabled: effectiveEnabled,
        dropdownColor: config._dropdownColor,
      ),
    );
  }
}

/// 下拉选择配置类，定义下拉选择的样式和行为
class WFormDropdownConfig extends WFormFieldChrome {
  /// 内容内边距
  EdgeInsetsGeometry? _contentPadding;

  /// 提示 widget
  Widget? _hint;

  /// 图标
  Widget? _icon;

  /// 标签样式
  TextStyle? _style;

  /// 提示文本样式
  TextStyle? _hintStyle;

  /// 下拉弹出层背景色
  Color? _dropdownColor;

  /// 设置内容内边距
  set contentPadding(EdgeInsetsGeometry? value) {
    _contentPadding = value;
  }

  /// 设置提示 widget
  set hint(Widget? value) {
    _hint = value;
  }

  /// 设置图标
  set icon(Widget? value) {
    _icon = value;
  }

  /// 设置标签样式
  set style(TextStyle? value) {
    _style = value;
  }

  /// 设置提示文本样式
  set hintStyle(TextStyle? value) {
    _hintStyle = value;
  }

  /// 设置下拉弹出层背景色
  set dropdownColor(Color? value) {
    _dropdownColor = value;
  }

  /// 构建 [WFormDropdown] 组件
  ///
  /// [bordered] 为 `true` 时返回带 [WFormFieldShell] / [WFormBorder] 的版本，
  /// 内层 `containerDecoration` 会被清空，边框交由外层绘制；否则返回裸字段。
  ///
  /// [readOnly] 为 true 时内层控件不可交互、外层使用只读装饰；
  /// [enabled] 为 false（且配置未启用）时外层同样按只读展示。
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
    Key? borderKey,
    bool enableFocusBorder = true,
  }) {
    final baseEnabled = enabled ?? this.enabled;

    // 清空内层容器装饰（在副本上操作，避免污染原配置的后续 build()），边框交由外层 WFormBorder 绘制
    final config = bordered ? (copy()..containerDecoration = null) : this;

    final dropdown = WFormDropdown<T>(
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
      return dropdown;
    }

    return WFormFieldFrame.border(
      name: name,
      borderKey: borderKey,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      enableFocusBorder: enableFocusBorder,
      readOnly: readOnly || !baseEnabled,
      child: dropdown,
    );
  }

  /// 创建当前配置的副本
  WFormDropdownConfig copy() {
    return copyWith();
  }

  /// 创建当前配置的副本，并可以选择性地更新某些属性
  ///
  /// 参数为 null 表示沿用原值。
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
    final config = WFormDropdownConfig();
    config.enabled = enabled ?? this.enabled;
    config.height = height ?? this.height;
    config.width = width ?? this.width;
    config._contentPadding = contentPadding ?? _contentPadding;
    config.yOffset = yOffset ?? this.yOffset;
    config.leading = leading ?? this.leading;
    config.actions = actions ?? this.actions;
    config.containerDecoration = containerDecoration ?? this.containerDecoration;
    config.containerMargin = containerMargin ?? this.containerMargin;
    config.containerPadding = containerPadding ?? this.containerPadding;
    config._hint = hint ?? _hint;
    config._icon = icon ?? _icon;
    config._style = style ?? _style;
    config._hintStyle = hintStyle ?? _hintStyle;
    config._dropdownColor = dropdownColor ?? _dropdownColor;
    return config;
  }
}
