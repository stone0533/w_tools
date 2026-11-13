import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../border/read_only_scope.dart';
import '../field_frame.dart';
import '../form_scope.dart';
import '../form_icons.dart';
import '../form_theme.dart';
import '../popup.dart';

part 'multi_dropdown_field.dart';
part 'multi_dropdown_item.dart';

/// 表单多选下拉框组件
///
/// 点击后在锚点下方弹出可多选的选项列表，字段值为 `Set<T>`（`T` 由 items 推断）；
/// 未选择时的占位文本、禁用项、弹层外观与选项样式可通过
/// 直接参数配置，只读状态会合并外层 [WFormReadOnlyScope]。
/// 框架内部使用：普通业务用直接字段（`WFormTextField` 等），4.0 移出公共面。
@internal
class WFormMultiDropdownCore<T> extends StatelessWidget {
  /// 输入装饰
  final InputDecoration? decoration;

  /// 右侧图标
  final Widget? icon;

  /// 图标大小
  final double? iconSize;

  /// 图标禁用色
  final Color? iconDisabledColor;

  /// 图标启用色
  final Color? iconEnabledColor;

  /// 未选中复选框图标
  final Widget? checkboxUnselectedIcon;

  /// 选中复选框图标
  final Widget? checkboxSelectedIcon;

  /// 禁用复选框图标
  final Widget? checkboxDisabledIcon;

  /// 文本样式
  final TextStyle? style;

  /// hint 文本样式
  final TextStyle? hintStyle;

  /// 弹层内边距
  final EdgeInsets? popUpLayerPadding;

  /// 弹层阴影高度
  final double? popUpLayerElevation;

  /// 弹层阴影颜色
  final Color? popUpLayerShadowColor;

  /// 禁用键
  final Set<T> disabledKeys;

  /// 选项内边距
  final EdgeInsetsGeometry? itemPadding;

  /// 选项文字样式
  final TextStyle? itemStyle;

  /// 选项选中文字样式
  final TextStyle? itemCheckedStyle;

  /// 选项禁用文字样式
  final TextStyle? itemDisabledStyle;

  /// 选项标题内边距
  final EdgeInsets? itemTitlePadding;

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
  final Map<T, String> items;

  /// 初始值
  final Set<T>? initialValue;

  /// 值变化回调（空集合表示未选择）
  final ValueChanged<Set<T>>? onChanged;

  /// 校验器
  final FormFieldValidator<Set<T>>? validator;

  /// 未选择时的展示文本（null 时使用 hintText；仍未配置则不显示占位）
  final String? hintText;

  /// 宽度（null 时使用 width）
  final double? width;

  /// 是否启用（null 时使用 enabled）
  /// 是否启用（只读作用域仍会覆盖）
  final bool enabled;

  /// 创建多选下拉框组件
  const WFormMultiDropdownCore({
    super.key,
    required this.name,
    required this.items,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.hintText,
    this.width,
    this.enabled = true,
    this.decoration,
    this.icon,
    this.iconSize = 24,
    this.iconDisabledColor,
    this.iconEnabledColor,
    this.checkboxUnselectedIcon,
    this.checkboxSelectedIcon,
    this.checkboxDisabledIcon,
    this.style,
    this.hintStyle,
    this.popUpLayerPadding,
    this.popUpLayerElevation,
    this.popUpLayerShadowColor,
    this.disabledKeys = const <Never>{},
    this.itemPadding,
    this.itemStyle,
    this.itemCheckedStyle,
    this.itemDisabledStyle,
    this.itemTitlePadding,
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
    final wFormData = WFormScope.requireOf(context);

    void onChangedHandler(Set<T>? value) {
      final selected = value ?? const <Never>{};
      wFormData.clearError(name);
      onChanged?.call(selected);
    }

    return WFormFieldFrame(
      height: height,
      width: width,
      decoration: containerDecoration,
      margin: containerMargin,
      padding: containerPadding,
      yOffset: yOffset,
      leading: leading,
      actions: actions,
      child: _WFormMultiDropdown<T>(
        name: name,
        items: items,
        initialValue: initialValue,
        onChanged: onChangedHandler,
        validator: validator,
        enabled: enabled && !WFormReadOnlyScope.readOnlyOf(context),
        decoration: decoration,
        icon: icon,
        iconSize: iconSize,
        iconDisabledColor: iconDisabledColor,
        iconEnabledColor: iconEnabledColor,
        checkboxUnselectedIcon: checkboxUnselectedIcon,
        checkboxSelectedIcon: checkboxSelectedIcon,
        checkboxDisabledIcon: checkboxDisabledIcon,
        style: style,
        hintStyle: hintStyle,
        popUpLayerPadding: popUpLayerPadding,
        popUpLayerElevation: popUpLayerElevation,
        popUpLayerShadowColor: popUpLayerShadowColor,
        hintText: hintText,
        disabledKeys: disabledKeys,
        itemPadding: itemPadding,
        itemStyle: itemStyle,
        itemCheckedStyle: itemCheckedStyle,
        itemDisabledStyle: itemDisabledStyle,
        itemTitlePadding: itemTitlePadding,
        focusNode: focusNode,
      ),
    );
  }
}
