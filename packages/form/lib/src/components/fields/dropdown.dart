import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../border/read_only_scope.dart';
import '../field_frame.dart';
import '../form_builder.dart';
import '../form_defaults.dart';

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
    final wFormData = WFormBuilder.requireOf(context);

    void onChangedHandler(T? value) {
      wFormData.onChange(name, value);
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

    // 继承外层只读作用域（WFormBorderWithData.readOnly）
    final effectiveEnabled =
        (enabled ?? config._enabled) && !WFormReadOnlyScope.readOnlyOf(context);

    return WFormFieldFrame(
      height: config._height,
      width: width ?? config._width,
      decoration: config._containerDecoration,
      margin: config._containerMargin,
      padding: config._containerPadding,
      yOffset: config._yOffset,
      leading: config._leading,
      actions: config._actions,
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
        icon: config._icon ?? WFormDefaults.dropdownIcon,
        onChanged: onChangedHandler,
        hint: hintWidget,
        enabled: effectiveEnabled,
        dropdownColor: config._dropdownColor,
      ),
    );
  }
}

/// 下拉选择配置类，定义下拉选择的样式和行为
class WFormDropdownConfig {
  /// 是否启用
  bool _enabled = true;

  /// 高度
  double? _height;

  /// 宽度
  double? _width;

  /// 内容内边距
  EdgeInsetsGeometry? _contentPadding;

  /// Y 轴偏移
  double? _yOffset;

  /// 左侧组件
  Widget? _leading;

  /// 操作按钮列表
  List<Widget>? _actions;

  /// 容器装饰
  Decoration? _containerDecoration;

  /// 容器边距
  EdgeInsetsGeometry? _containerMargin;

  /// 容器内边距
  EdgeInsetsGeometry? _containerPadding;

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

  /// 设置是否启用
  set enabled(bool value) {
    _enabled = value;
  }

  /// 设置高度
  set height(double? value) {
    _height = value;
  }

  /// 设置宽度
  set width(double? value) {
    _width = value;
  }

  /// 设置内容内边距
  set contentPadding(EdgeInsetsGeometry? value) {
    _contentPadding = value;
  }

  /// 设置 Y 轴偏移
  set yOffset(double? value) {
    _yOffset = value;
  }

  /// 设置左侧组件
  set leading(Widget? value) {
    _leading = value;
  }

  /// 设置操作按钮列表
  set actions(List<Widget>? value) {
    _actions = value;
  }

  /// 设置容器装饰
  set containerDecoration(Decoration? value) {
    _containerDecoration = value;
  }

  /// 设置容器边距
  set containerMargin(EdgeInsetsGeometry? value) {
    _containerMargin = value;
  }

  /// 设置容器内边距
  set containerPadding(EdgeInsetsGeometry? value) {
    _containerPadding = value;
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
  /// [bordered] 为 `true` 时返回带 [WFormBorderWithData] / [WFormBorder] 的版本，
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
    final baseEnabled = enabled ?? _enabled;

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
    config._enabled = enabled ?? _enabled;
    config._height = height ?? _height;
    config._width = width ?? _width;
    config._contentPadding = contentPadding ?? _contentPadding;
    config._yOffset = yOffset ?? _yOffset;
    config._leading = leading ?? _leading;
    config._actions = actions ?? _actions;
    config._containerDecoration = containerDecoration ?? _containerDecoration;
    config._containerMargin = containerMargin ?? _containerMargin;
    config._containerPadding = containerPadding ?? _containerPadding;
    config._hint = hint ?? _hint;
    config._icon = icon ?? _icon;
    config._style = style ?? _style;
    config._hintStyle = hintStyle ?? _hintStyle;
    config._dropdownColor = dropdownColor ?? _dropdownColor;
    return config;
  }
}
