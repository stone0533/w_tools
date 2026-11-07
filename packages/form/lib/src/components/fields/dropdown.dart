import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../border/read_only_scope.dart';
import '../field_frame.dart';
import '../form_scope.dart';
import '../form_icons.dart';
import '../form_theme.dart';

/// 表单下拉选择组件
///
/// 选项由 [items] 提供（键为值、值为展示文本），选中值必须存在于 [items]；
/// 容器、提示、图标与弹层背景色等可通过 `WFormDropdown` 的同名参数 配置，
/// 只读状态会合并外层 [WFormReadOnlyScope]。
/// 框架内部使用：普通业务用直接字段（`WFormTextField` 等），4.0 移出公共面。
@internal
class WFormDropdownCore<T> extends StatelessWidget {
  /// 右侧图标（null 时取 WFormTheme / WFormIcons 默认）
  final Widget? icon;

  /// 选项文字样式
  final TextStyle? style;

  /// hint 文字样式
  final TextStyle? hintStyle;

  /// 输入框内边距
  final EdgeInsetsGeometry? contentPadding;

  /// 弹层背景色
  final Color? dropdownColor;

  /// 外框高度
  final double? height;

  /// 内容 Y 轴偏移
  final double? yOffset;

  /// 左侧插槽
  final Widget? leading;

  /// 右侧操作插槽
  final List<Widget>? actions;

  /// 外框装饰（bordered 时由边框接管）
  final Decoration? containerDecoration;

  /// 外框外边距
  final EdgeInsetsGeometry? containerMargin;

  /// 外框内边距
  final EdgeInsetsGeometry? containerPadding;

  /// 焦点节点
  final FocusNode? focusNode;

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

  /// 是否启用（由字段参数 / 外层只读作用域决定）
  /// 是否启用（只读作用域仍会覆盖）
  final bool enabled;

  /// 宽度
  final double? width;

  /// 创建下拉选择组件
  const WFormDropdownCore({
    super.key,
    required this.name,
    required this.items,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.hint,
    this.hintText,
    this.enabled = true,
    this.width,
    this.icon,
    this.style,
    this.hintStyle,
    this.contentPadding,
    this.dropdownColor,
    this.height,
    this.yOffset,
    this.leading,
    this.actions,
    this.containerDecoration,
    this.containerMargin,
    this.containerPadding,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = WFormThemeData.of(context);
    final wFormData = WFormScope.requireOf(context);

    void onChangedHandler(T? value) {
      wFormData.handleChange(name, value);
      onChanged?.call(value);
    }

    Widget? hintWidget;

    if (hint != null) {
      hintWidget = hint;
    } else if (hintText != null) {
      hintWidget = Center(child: Text(hintText!, style: hintStyle));
    }

    // 继承外层只读作用域（WFormFieldShell.readOnly）
    final effectiveEnabled = enabled && !WFormReadOnlyScope.readOnlyOf(context);

    return WFormFieldFrame(
      height: height,
      width: width,
      decoration: containerDecoration,
      margin: containerMargin,
      padding: containerPadding,
      yOffset: yOffset,
      leading: leading,
      actions: actions,
      child: FormBuilderDropdown<T>(
        name: name,
        items: items.entries
            .map(
              (e) => DropdownMenuItem<T>(
                value: e.key,
                child: Text(
                  e.value,
                  style: style,
                  strutStyle: StrutStyle(
                    fontFamily: style?.fontFamily,
                    fontSize: style?.fontSize,
                    fontWeight: style?.fontWeight,
                    height: style?.height,
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
          contentPadding: contentPadding,
        ),
        initialValue: initialValue,
        validator: validator,
        icon: icon ?? theme?.effectiveDropdownIcon ?? WFormIcons.defaults.dropdown,
        onChanged: onChangedHandler,
        hint: hintWidget,
        enabled: effectiveEnabled,
        dropdownColor: dropdownColor,
        focusNode: focusNode,
      ),
    );
  }
}
