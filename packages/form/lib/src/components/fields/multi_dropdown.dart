import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../border/read_only_scope.dart';
import '../field_frame.dart';
import '../field_base_config.dart';
import '../field_lifecycle.dart';
import '../form_scope.dart';
import '../form_defaults.dart';
import '../form_theme.dart';
import '../popup.dart';

part 'multi_dropdown_field.dart';
part 'multi_dropdown_item.dart';
part 'multi_dropdown_config.dart';

/// 表单多选下拉框组件
///
/// 点击后在锚点下方弹出可多选的选项列表，字段值为 `Set<String>`；
/// 未选择时的占位文本、禁用项、弹层外观与选项样式可通过
/// [WFormMultiDropdownConfig] 配置，只读状态会合并外层 [WFormReadOnlyScope]。
class WFormMultiDropdownCore extends StatelessWidget {
  /// 多选下拉框配置
  final WFormMultiDropdownConfig config;

  /// 字段名称
  final String name;

  /// 选项映射，键为值，值为显示文本
  final Map<String, String> items;

  /// 初始值
  final Set<String>? initialValue;

  /// 值变化回调（空集合表示未选择）
  final ValueChanged<Set<String>>? onChanged;

  /// 校验器
  final FormFieldValidator<Set<String>>? validator;

  /// 未选择时的展示文本（null 时使用 config.hintText，仍未配置则显示 `ALL`）
  final String? hintText;

  /// 宽度（null 时使用 config.width）
  final double? width;

  /// 是否启用（null 时使用 config.enabled）
  final bool? enabled;

  /// 创建多选下拉框组件
  const WFormMultiDropdownCore({
    super.key,
    required this.config,
    required this.name,
    required this.items,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.hintText,
    this.width,
    this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final wFormData = WFormScope.requireOf(context);

    void onChangedHandler(Set<String>? value) {
      final selected = value ?? const <String>{};
      wFormData.handleChange(name, selected);
      onChanged?.call(selected);
    }

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
        child: _WFormMultiDropdown(
          name: name,
          items: items,
          initialValue: initialValue,
          onChanged: onChangedHandler,
          validator: validator,
          enabled: (enabled ?? config.enabled) && !WFormReadOnlyScope.readOnlyOf(context),
          decoration: config.decoration,
          icon: config.icon,
          iconSize: config.iconSize,
          iconDisabledColor: config.iconDisabledColor,
          iconEnabledColor: config.iconEnabledColor,
          checkboxUnselectedIcon: config.checkboxUnselectedIcon,
          checkboxSelectedIcon: config.checkboxSelectedIcon,
          checkboxDisabledIcon: config.checkboxDisabledIcon,
          style: config.style,
          popUpLayerPadding: config.popUpLayerPadding,
          popUpLayerElevation: config.popUpLayerElevation,
          popUpLayerShadowColor: config.popUpLayerShadowColor,
          hintText: hintText ?? config.hintText,
          disabledKeys: config.disabledKeys,
          itemPadding: config.itemPadding,
          itemStyle: config.itemStyle,
          itemCheckedStyle: config.itemCheckedStyle,
          itemDisabledStyle: config.itemDisabledStyle,
          itemTitlePadding: config.itemTitlePadding,
        ),
      ),
    );
  }
}
