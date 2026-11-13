import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'field_assembly.dart';
import 'field_button.dart';
import 'form_field_style.dart';
import 'fields/checkbox.dart';
import 'fields/date_picker.dart';
import 'fields/dropdown.dart';
import 'fields/multi_dropdown.dart';
import 'fields/radio_group.dart';
import 'fields/text_field.dart';

// 新增直接字段时的约定（FORM-009 收口后）：
// 1. 公共参数与装配走 `_WFormDirectField` 基类：字段只声明自己的参数与 core，
//    不要在字段里另写 assert / bordered 分支 / 只读合并；
// 2. `WForm.fieldStyle` 的 height / containerPadding / textStyle / hintStyle 要接到
//    字段的 core 上（没有对应展示的可以不接，但在字段 doc 里写明）；漏接是静默失效；
// 3. 在 `test/internal/field_style_matrix_test.dart` 补一行矩阵用例，否则漏接没人发现。

/// 直接字段的公共装配骨架（内部基类，不导出）。
///
/// 7 个直接字段共用这些参数与装配步骤（断言 / 只读合并 / 提示文案 / 外框）：
/// 收敛在这里，新增公共参数或调整装配顺序时只改一处。
///
/// 子类只保留自己的参数与 core 构建（`_buildField`）；`bordered` 因默认值不同
/// 仍由各字段声明并覆盖基类 getter。
abstract class _WFormDirectField extends StatelessWidget {
  const _WFormDirectField({
    super.key,
    required this.name,
    this.message,
    this.hintTextList,
    this.isTransparentBackground,
    this.enableFocusBorder = true,
    this.readOnly = false,
    this.enabled,
    this.leading,
    this.actions,
  });

  /// 字段名称
  final String name;

  /// 提示文案；与 [hintTextList] 二选一
  final String? message;

  /// 提示文案列表；与 [message] 二选一
  final List<String>? hintTextList;

  /// 是否透明背景
  final bool? isTransparentBackground;

  /// 是否启用焦点边框
  final bool enableFocusBorder;

  /// 是否只读
  final bool readOnly;

  /// 是否启用（null 视为启用）
  final bool? enabled;

  /// 左侧插槽
  final Widget? leading;

  /// 右侧操作插槽
  final List<Widget>? actions;

  /// 是否带边框（复选 / 单选默认 false，其余 true）
  bool get bordered => true;

  /// 构建字段的 core；公共装配（断言 / 只读 / 提示 / 外框）已由本类完成。
  Widget _buildField(
    BuildContext context,
    WFormFieldStyle? fieldStyle,
    bool effectiveEnabled,
  );

  @override
  Widget build(BuildContext context) {
    final fieldStyle = WFormFieldStyle.of(context);
    final effectiveEnabled = enabled ?? true;
    return assembleFormField(
      name: name,
      bordered: bordered,
      readOnly: readOnly || !effectiveEnabled,
      message: message,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      enableFocusBorder: enableFocusBorder,
      child: _buildField(context, fieldStyle, effectiveEnabled),
    );
  }
}

/// 直接构造的表单字段。
///
/// 这些 Widget 是日常业务入口：常用参数直接传入；页面级样式用
/// `WForm.fieldStyle`，单个字段的特殊样式用 `WFormFieldStyleScope` 包裹。
/// 字段由包内装配层实现（非公开 API），边框 / 校验 / 只读等能力保持不变。
class WFormTextField extends _WFormDirectField {
  const WFormTextField({
    super.key,
    required super.name,
    this.label,
    this.hintText,
    super.message,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.focusNode,
    super.enabled,
    super.readOnly,
    this.bordered = true,
    this.obscureText,
    this.autofocus,
    this.keyboardType,
    this.textInputAction,
    this.maxLines,
    this.maxLength,
    this.textAlign,
    this.inputFormatters,
    super.actions,
    super.leading,
    super.hintTextList,
    super.isTransparentBackground,
    super.enableFocusBorder,
    this.style,
  });

  final String? label;

  /// 占位符；优先于历史参数 [label]。
  final String? hintText;
  final String? initialValue;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String?>? onChanged;
  final void Function(String?)? onSubmitted;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  @override
  final bool bordered;
  final bool? obscureText;
  final bool? autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLines;

  /// 最大字符数（null 表示不限制）
  final int? maxLength;

  /// 文本对齐；默认由平台 / Material 决定
  final TextAlign? textAlign;
  final List<TextInputFormatter>? inputFormatters;

  /// 正文样式（未传时取 `WForm.fieldStyle`）
  final TextStyle? style;

  @override
  Widget _buildField(
    BuildContext context,
    WFormFieldStyle? fieldStyle,
    bool effectiveEnabled,
  ) {
    return WFormTextFieldCore(
      name: name,
      initialValue: initialValue,
      hintText: hintText ?? label,
      validator: validator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      focusNode: focusNode,
      readOnly: readOnly,
      enabled: effectiveEnabled,
      style: style ?? fieldStyle?.textStyle,
      hintStyle: fieldStyle?.hintStyle,
      height: fieldStyle?.height,
      containerPadding: fieldStyle?.containerPadding,
      obscureText: obscureText ?? false,
      autofocus: autofocus,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      maxLength: maxLength,
      textAlign: textAlign,
      inputFormatters: inputFormatters,
      actions: actions,
      leading: leading,
    );
  }
}

/// 下拉选择字段。
///
/// [items] 的 key 是字段值、value 是展示文本，值类型由泛型 [T] 决定；
/// 未选择时的占位文案用 [hintText]（[label] 是历史别名）。
/// 在 `WForm` 子树内使用，边框 / 只读 / 校验由容器统一提供。
class WFormDropdown<T> extends _WFormDirectField {
  const WFormDropdown({
    super.key,
    required super.name,
    required this.items,
    this.label,
    this.hintText,
    super.message,
    this.initialValue,
    this.validator,
    this.onChanged,
    super.enabled,
    super.readOnly,
    this.bordered = true,
    super.hintTextList,
    super.isTransparentBackground,
    super.enableFocusBorder,
    this.icon,
    this.iconSize,
    this.dropdownColor,
    this.contentPadding,
    super.leading,
    super.actions,
    this.focusNode,
    this.style,
  });

  final Map<T, String> items;
  final String? label;

  /// 占位符；优先于历史参数 [label]。
  final String? hintText;
  final T? initialValue;
  final FormFieldValidator<T>? validator;
  final ValueChanged<T?>? onChanged;
  @override
  final bool bordered;
  final Widget? icon;

  /// 右侧图标尺寸；未传时用底层默认 24
  final double? iconSize;
  final Color? dropdownColor;
  final EdgeInsetsGeometry? contentPadding;

  final FocusNode? focusNode;

  /// 选项文字样式（未传时取 `WForm.fieldStyle`）
  final TextStyle? style;

  @override
  Widget _buildField(
    BuildContext context,
    WFormFieldStyle? fieldStyle,
    bool effectiveEnabled,
  ) {
    return WFormDropdownCore<T>(
      name: name,
      items: items,
      initialValue: initialValue,
      validator: validator,
      onChanged: onChanged,
      hintText: hintText ?? label,
      enabled: effectiveEnabled,
      icon: icon,
      iconSize: iconSize,
      style: style ?? fieldStyle?.textStyle,
      hintStyle: fieldStyle?.hintStyle,
      contentPadding: contentPadding,
      focusNode: focusNode,
      dropdownColor: dropdownColor,
      height: fieldStyle?.height,
      containerPadding: fieldStyle?.containerPadding,
      leading: leading,
      actions: actions,
    );
  }
}

/// 多选下拉字段（值为 `Set<T>`）。
///
/// 弹层由 `WFormPopup` 在锚点下方打开；[disabledKeys] 控制不可点击项，
/// [itemStyle] / [itemCheckedStyle] / [itemDisabledStyle] 控制选项文字。
/// 在 `WForm` 子树内使用，边框 / 只读 / 校验由容器统一提供。
class WFormMultiDropdown<T> extends _WFormDirectField {
  const WFormMultiDropdown({
    super.key,
    required super.name,
    required this.items,
    this.label,
    this.hintText,
    super.message,
    this.initialValue,
    this.validator,
    this.onChanged,
    super.enabled,
    super.readOnly,
    this.bordered = true,
    super.hintTextList,
    super.isTransparentBackground,
    super.enableFocusBorder,
    this.icon,
    this.iconSize,
    this.checkboxUnselectedIcon,
    this.checkboxSelectedIcon,
    this.checkboxDisabledIcon,
    this.disabledKeys = const <Never>{},
    this.itemStyle,
    this.itemCheckedStyle,
    this.itemDisabledStyle,
    super.leading,
    super.actions,
    this.focusNode,
  });

  final Map<T, String> items;
  final String? label;

  /// 占位符；优先于历史参数 [label]。
  final String? hintText;
  final Set<T>? initialValue;
  final FormFieldValidator<Set<T>>? validator;
  final ValueChanged<Set<T>>? onChanged;
  @override
  final bool bordered;
  final Widget? icon;
  final double? iconSize;
  final Widget? checkboxUnselectedIcon;
  final Widget? checkboxSelectedIcon;
  final Widget? checkboxDisabledIcon;
  final Set<T> disabledKeys;
  final TextStyle? itemStyle;
  final TextStyle? itemCheckedStyle;
  final TextStyle? itemDisabledStyle;

  final FocusNode? focusNode;

  @override
  Widget _buildField(
    BuildContext context,
    WFormFieldStyle? fieldStyle,
    bool effectiveEnabled,
  ) {
    return WFormMultiDropdownCore<T>(
      name: name,
      items: items,
      initialValue: initialValue,
      validator: validator,
      onChanged: onChanged,
      hintText: hintText ?? label,
      enabled: effectiveEnabled,
      icon: icon,
      iconSize: iconSize,
      style: fieldStyle?.textStyle,
      hintStyle: fieldStyle?.hintStyle,
      height: fieldStyle?.height,
      containerPadding: fieldStyle?.containerPadding,
      disabledKeys: disabledKeys,
      leading: leading,
      actions: actions,
      checkboxUnselectedIcon: checkboxUnselectedIcon,
      checkboxSelectedIcon: checkboxSelectedIcon,
      checkboxDisabledIcon: checkboxDisabledIcon,
      itemStyle: itemStyle,
      itemCheckedStyle: itemCheckedStyle,
      focusNode: focusNode,
      itemDisabledStyle: itemDisabledStyle,
    );
  }
}

/// 日期选择字段。
///
/// 字段值固定存 ISO `yyyy-MM-dd`，显示格式由 [displayFormat] 决定（默认 `yMMMMd`）。
/// 点击后调用系统 `showDatePicker`；`firstDate` / `lastDate` 默认 1900 / 2100。
/// 在 `WForm` 子树内使用，边框 / 只读 / 校验由容器统一提供。
class WFormDatePicker extends _WFormDirectField {
  const WFormDatePicker({
    super.key,
    required super.name,
    this.label,
    this.hintText,
    super.message,
    this.initialValue,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.displayFormat,
    this.icon,
    this.iconSize,
    this.validator,
    this.onChanged,
    super.enabled,
    super.readOnly,
    this.bordered = true,
    super.hintTextList,
    super.isTransparentBackground,
    super.enableFocusBorder,
    super.leading,
    super.actions,
    this.style,
    this.focusNode,
  });

  final String? label;

  /// 占位符；优先于历史参数 [label]。
  final String? hintText;
  final String? initialValue;

  /// 用 `DateTime` 给初值；与 [initialValue] 二选一，同时传时 [initialValue] 优先
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// 日期格式，默认 `yMMMMd`。
  final String? displayFormat;
  final Widget? icon;
  final double? iconSize;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String?>? onChanged;
  @override
  final bool bordered;

  /// 日期文字样式（未传时取 `WForm.fieldStyle`）
  final TextStyle? style;

  final FocusNode? focusNode;

  @override
  Widget _buildField(
    BuildContext context,
    WFormFieldStyle? fieldStyle,
    bool effectiveEnabled,
  ) {
    return WFormDatePickerCore(
      name: name,
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2100),
      initialValue: initialValue ?? initialDate?.toIso8601String().split('T').first,
      validator: validator,
      onChanged: onChanged,
      enabled: effectiveEnabled,
      displayFormat: displayFormat ?? 'yMMMMd',
      icon: icon,
      iconSize: iconSize,
      style: style ?? fieldStyle?.textStyle,
      decoration: hintText == null && label == null
          ? null
          : (const InputDecoration()).copyWith(
              hintText: hintText ?? label,
              hintStyle: fieldStyle?.hintStyle,
            ),
      height: fieldStyle?.height,
      containerPadding: fieldStyle?.containerPadding,
      leading: leading,
      focusNode: focusNode,
      actions: actions,
    );
  }
}

/// 复选框字段（布尔值）。
///
/// [title] 是整行的标题 widget；默认 `bordered: false`，与其余直接字段不同。
/// 选中 / 未选中 / 禁用图标可通过同名参数或 `WFormIcons` 统一配置。
class WFormCheckbox extends _WFormDirectField {
  const WFormCheckbox({
    super.key,
    required super.name,
    required this.title,
    super.message,
    this.initialValue = false,
    this.validator,
    this.onChanged,
    super.enabled,
    super.readOnly,
    this.bordered = false,
    super.hintTextList,
    super.isTransparentBackground,
    super.enableFocusBorder,
    this.unselectedIcon,
    this.selectedIcon,
    this.disabledIcon,
    this.iconSpacing,
    this.iconYOffset,
    super.leading,
    super.actions,
    this.style,
    this.focusNode,
  });

  final Widget title;

  final bool initialValue;
  final FormFieldValidator<bool>? validator;
  final ValueChanged<bool?>? onChanged;
  @override
  final bool bordered;
  final Widget? unselectedIcon;
  final Widget? selectedIcon;
  final Widget? disabledIcon;
  final double? iconSpacing;
  final double? iconYOffset;

  /// 标题文字样式（未传时取 `WForm.fieldStyle`）
  final TextStyle? style;

  final FocusNode? focusNode;

  @override
  Widget _buildField(
    BuildContext context,
    WFormFieldStyle? fieldStyle,
    bool effectiveEnabled,
  ) {
    return WFormCheckboxCore(
      name: name,
      title: title,
      initialValue: initialValue,
      validator: validator,
      onChanged: onChanged,
      enabled: effectiveEnabled,
      unselectedIcon: unselectedIcon,
      selectedIcon: selectedIcon,
      disabledIcon: disabledIcon,
      iconSpacing: iconSpacing,
      iconYOffset: iconYOffset,
      style: style ?? fieldStyle?.textStyle,
      height: fieldStyle?.height,
      containerPadding: fieldStyle?.containerPadding,
      leading: leading,
      focusNode: focusNode,
      actions: actions,
    );
  }
}

/// 单选组字段（单列布局）。
///
/// [items] 的 key 是字段值、value 是展示文本；[titleBuilder] / [itemExtraBuilder]
/// 可定制每个选项；默认 `bordered: false`，与复选保持一致。
class WFormRadioGroup<T> extends _WFormDirectField {
  const WFormRadioGroup({
    super.key,
    required super.name,
    required this.items,
    super.message,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.titleBuilder,
    this.itemExtraBuilder,
    super.enabled,
    super.readOnly,
    this.bordered = false,
    super.hintTextList,
    super.isTransparentBackground,
    super.enableFocusBorder,
    this.unselectedIcon,
    this.selectedIcon,
    this.iconSpacing,
    this.lineSpacing,
    this.iconYOffset,
    this.style,
    super.leading,
    super.actions,
    this.focusNode,
  });

  final Map<T, String> items;
  final T? initialValue;

  final FormFieldValidator<T>? validator;
  final ValueChanged<T?>? onChanged;
  final Widget Function(BuildContext, T, String, bool)? titleBuilder;
  final Widget Function(BuildContext, T, String, bool)? itemExtraBuilder;
  @override
  final bool bordered;
  final Widget? unselectedIcon;
  final Widget? selectedIcon;
  final double? iconSpacing;
  final double? lineSpacing;
  final double? iconYOffset;
  final TextStyle? style;

  final FocusNode? focusNode;

  @override
  Widget _buildField(
    BuildContext context,
    WFormFieldStyle? fieldStyle,
    bool effectiveEnabled,
  ) {
    return WFormRadioGroupCore<T>(
      name: name,
      items: items,
      initialValue: initialValue,
      validator: validator,
      onChanged: onChanged,
      titleBuilder: titleBuilder,
      itemExtraBuilder: itemExtraBuilder,
      enabled: effectiveEnabled,
      unselectedIcon: unselectedIcon,
      selectedIcon: selectedIcon,
      iconSpacing: iconSpacing,
      lineSpacing: lineSpacing,
      iconYOffset: iconYOffset,
      style: style ?? fieldStyle?.textStyle,
      height: fieldStyle?.height,
      containerPadding: fieldStyle?.containerPadding,
      leading: leading,
      focusNode: focusNode,
      actions: actions,
    );
  }
}

/// 字段值选择器（String 专用）。
///
/// 是 [WFormFieldButton]`<String>` 的别名：参数、行为完全一致，
/// `WFormButton(...)` / `const WFormButton(...)` 照旧可用。
/// 需要 enum / int 等非 String 值时直接用 [WFormFieldButton]。
typedef WFormButton = WFormFieldButton<String>;

/// 泛型字段值选择器：enum / int 等非 String 值。
///
/// `WFormButton` 是它的 String 便捷形态（字段值固定 `String`）。
class WFormFieldButton<T> extends _WFormDirectField {
  const WFormFieldButton({
    super.key,
    required super.name,
    required this.onTap,
    this.label,
    this.hintWidget,
    super.message,
    this.selectedWidgetBuilder,
    this.initialValue,
    this.validator,
    this.focusNode,
    super.enabled,
    super.readOnly,
    this.bordered = true,
    super.hintTextList,
    super.isTransparentBackground,
    super.enableFocusBorder,
    super.leading,
    super.actions,
  });

  final void Function(T? value, ValueChanged<T> didChange) onTap;
  final String? label;
  final Widget? hintWidget;

  final Widget Function(T value)? selectedWidgetBuilder;
  final T? initialValue;
  final FormFieldValidator<T>? validator;
  final FocusNode? focusNode;
  @override
  final bool bordered;

  @override
  Widget _buildField(
    BuildContext context,
    WFormFieldStyle? fieldStyle,
    bool effectiveEnabled,
  ) {
    return WFormFieldButtonCore<T>(
      name: name,
      onTap: onTap,
      selectedWidgetBuilder: selectedWidgetBuilder,
      initialValue: initialValue,
      validator: validator,
      focusNode: focusNode,
      enabled: effectiveEnabled,
      hintWidget: hintWidget ?? (label != null ? Text(label!) : null),
      height: fieldStyle?.height,
      containerPadding: fieldStyle?.containerPadding,
      leading: leading,
      actions: actions,
    );
  }
}
