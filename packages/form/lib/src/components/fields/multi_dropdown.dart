import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../border/read_only_scope.dart';
import '../field_frame.dart';
import '../field_lifecycle.dart';
import '../field_chrome.dart';
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
class WFormMultiDropdown extends StatelessWidget {
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
  const WFormMultiDropdown({
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
          decoration: config._decoration,
          icon: config._icon,
          iconSize: config._iconSize,
          iconDisabledColor: config._iconDisabledColor,
          iconEnabledColor: config._iconEnabledColor,
          checkboxUnselectedIcon: config._checkboxUnselectedIcon,
          checkboxSelectedIcon: config._checkboxSelectedIcon,
          checkboxDisabledIcon: config._checkboxDisabledIcon,
          style: config._style,
          popUpLayerPadding: config._popUpLayerPadding,
          popUpLayerElevation: config._popUpLayerElevation,
          popUpLayerShadowColor: config._popUpLayerShadowColor,
          hintText: hintText ?? config._hintText,
          disabledKeys: config._disabledKeys,
          itemPadding: config._itemPadding,
          itemStyle: config._itemStyle,
          itemCheckedStyle: config._itemCheckedStyle,
          itemDisabledStyle: config._itemDisabledStyle,
          itemTitlePadding: config._itemTitlePadding,
        ),
      ),
    );
  }
}
