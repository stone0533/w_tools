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

/// `hintTextList` 与 `message` 只允许二选一，同时传时直接断言。
void _assertHints(String? message, List<String>? hintTextList) {
  assert(
    message == null || hintTextList == null,
    'message 与 hintTextList 只需传一个（message 是便捷写法，不能与列表同时使用）。',
  );
}

/// 直接构造的表单字段。
///
/// 这些 Widget 是日常业务入口：常用参数直接传入；页面级样式用
/// `WForm.fieldStyle`，单个字段的特殊样式用 `WFormFieldStyleScope` 包裹。
/// 字段由包内装配层实现（非公开 API），边框 / 校验 / 只读等能力保持不变。
class WFormTextField extends StatelessWidget {
  const WFormTextField({
    super.key,
    required this.name,
    this.label,
    this.hintText,
    this.message,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.focusNode,
    this.enabled,
    this.readOnly = false,
    this.bordered = true,
    this.obscureText,
    this.autofocus,
    this.keyboardType,
    this.textInputAction,
    this.maxLines,
    this.inputFormatters,
    this.actions,
    this.leading,
    this.hintTextList,
    this.isTransparentBackground,
    this.enableFocusBorder = true,
    this.style,
  });

  final String name;
  final String? label;

  /// 占位符；优先于历史参数 [label]。
  final String? hintText;
  final String? message;
  final String? initialValue;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String?>? onChanged;
  final void Function(String?)? onSubmitted;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final bool? enabled;
  final bool readOnly;
  final bool bordered;
  final bool? obscureText;
  final bool? autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final List<Widget>? actions;

  /// 文本输入框左侧插槽。
  final Widget? leading;
  final List<String>? hintTextList;
  final bool? isTransparentBackground;
  final bool enableFocusBorder;

  /// 正文样式（未传时取 `WForm.fieldStyle`）
  final TextStyle? style;

  List<String>? get _messages => message != null ? [message!] : null;

  @override
  Widget build(BuildContext context) {
    _assertHints(message, hintTextList);
    final fieldStyle = WFormFieldStyle.of(context);
    final effectiveEnabled = enabled ?? true;
    return assembleFormField(
      name: name,
      bordered: bordered,
      readOnly: readOnly || !effectiveEnabled,
      hintTextList: hintTextList ?? _messages,
      isTransparentBackground: isTransparentBackground,
      enableFocusBorder: enableFocusBorder,
      child: WFormTextFieldCore(
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
        inputFormatters: inputFormatters,
        actions: actions,
        leading: leading,
      ),
    );
  }
}

class WFormDropdown<T> extends StatelessWidget {
  const WFormDropdown({
    super.key,
    required this.name,
    required this.items,
    this.label,
    this.hintText,
    this.message,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.enabled,
    this.readOnly = false,
    this.bordered = true,
    this.hintTextList,
    this.isTransparentBackground,
    this.enableFocusBorder = true,
    this.icon,
    this.dropdownColor,
    this.contentPadding,
    this.leading,
    this.actions,
    this.focusNode,
  });

  final String name;
  final Map<T, String> items;
  final String? label;

  /// 占位符；优先于历史参数 [label]。
  final String? hintText;
  final String? message;
  final T? initialValue;
  final FormFieldValidator<T>? validator;
  final ValueChanged<T?>? onChanged;
  final bool? enabled;
  final bool readOnly;
  final bool bordered;
  final List<String>? hintTextList;
  final bool? isTransparentBackground;
  final bool enableFocusBorder;
  final Widget? icon;
  final Color? dropdownColor;
  final EdgeInsetsGeometry? contentPadding;

  /// 字段左侧插槽。
  final Widget? leading;

  /// 字段右侧操作插槽。
  final List<Widget>? actions;

  List<String>? get _messages => message != null ? [message!] : null;

  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    _assertHints(message, hintTextList);
    final fieldStyle = WFormFieldStyle.of(context);
    final effectiveEnabled = enabled ?? true;
    return assembleFormField(
      name: name,
      bordered: bordered,
      readOnly: readOnly || !effectiveEnabled,
      hintTextList: hintTextList ?? _messages,
      isTransparentBackground: isTransparentBackground,
      enableFocusBorder: enableFocusBorder,
      child: WFormDropdownCore<T>(
        name: name,
        items: items,
        initialValue: initialValue,
        validator: validator,
        onChanged: onChanged,
        hintText: hintText ?? label,
        enabled: effectiveEnabled,
        icon: icon,
        style: fieldStyle?.textStyle,
        hintStyle: fieldStyle?.hintStyle,
        contentPadding: contentPadding,
        focusNode: focusNode,
        dropdownColor: dropdownColor,
        height: fieldStyle?.height,
        leading: leading,
        actions: actions,
      ),
    );
  }
}

class WFormMultiDropdown extends StatelessWidget {
  const WFormMultiDropdown({
    super.key,
    required this.name,
    required this.items,
    this.label,
    this.hintText,
    this.message,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.enabled,
    this.readOnly = false,
    this.bordered = true,
    this.hintTextList,
    this.isTransparentBackground,
    this.enableFocusBorder = true,
    this.icon,
    this.iconSize,
    this.checkboxUnselectedIcon,
    this.checkboxSelectedIcon,
    this.checkboxDisabledIcon,
    this.disabledKeys = const <String>{},
    this.itemStyle,
    this.itemCheckedStyle,
    this.itemDisabledStyle,
    this.leading,
    this.actions,
    this.focusNode,
  });

  final String name;
  final Map<String, String> items;
  final String? label;

  /// 占位符；优先于历史参数 [label]。
  final String? hintText;
  final String? message;
  final Set<String>? initialValue;
  final FormFieldValidator<Set<String>>? validator;
  final ValueChanged<Set<String>>? onChanged;
  final bool? enabled;
  final bool readOnly;
  final bool bordered;
  final List<String>? hintTextList;
  final bool? isTransparentBackground;
  final bool enableFocusBorder;
  final Widget? icon;
  final double? iconSize;
  final Widget? checkboxUnselectedIcon;
  final Widget? checkboxSelectedIcon;
  final Widget? checkboxDisabledIcon;
  final Set<String> disabledKeys;
  final TextStyle? itemStyle;
  final TextStyle? itemCheckedStyle;
  final TextStyle? itemDisabledStyle;

  /// 字段左侧插槽。
  final Widget? leading;

  /// 字段右侧操作插槽。
  final List<Widget>? actions;

  List<String>? get _messages => message != null ? [message!] : null;

  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    _assertHints(message, hintTextList);
    final fieldStyle = WFormFieldStyle.of(context);
    final effectiveEnabled = enabled ?? true;
    return assembleFormField(
      name: name,
      bordered: bordered,
      readOnly: readOnly || !effectiveEnabled,
      hintTextList: hintTextList ?? _messages,
      isTransparentBackground: isTransparentBackground,
      enableFocusBorder: enableFocusBorder,
      child: WFormMultiDropdownCore(
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
      ),
    );
  }
}

class WFormDatePicker extends StatelessWidget {
  const WFormDatePicker({
    super.key,
    required this.name,
    this.label,
    this.hintText,
    this.message,
    this.initialValue,
    this.firstDate,
    this.lastDate,
    this.displayFormat,
    this.icon,
    this.iconSize,
    this.validator,
    this.onChanged,
    this.enabled,
    this.readOnly = false,
    this.bordered = true,
    this.hintTextList,
    this.isTransparentBackground,
    this.enableFocusBorder = true,
    this.leading,
    this.actions,
    this.style,
    this.focusNode,
  });

  final String name;
  final String? label;

  /// 占位符；优先于历史参数 [label]。
  final String? hintText;
  final String? message;
  final String? initialValue;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// 日期格式，默认 `yMMMMd`。
  final String? displayFormat;
  final Widget? icon;
  final double? iconSize;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String?>? onChanged;
  final bool? enabled;
  final bool readOnly;
  final bool bordered;
  final List<String>? hintTextList;
  final bool? isTransparentBackground;
  final bool enableFocusBorder;

  /// 日期文字样式（未传时取 `WForm.fieldStyle`）
  final TextStyle? style;

  /// 字段左侧插槽。
  final Widget? leading;

  /// 字段右侧操作插槽。
  final List<Widget>? actions;

  List<String>? get _messages => message != null ? [message!] : null;

  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    _assertHints(message, hintTextList);
    final fieldStyle = WFormFieldStyle.of(context);
    final effectiveEnabled = enabled ?? true;
    return assembleFormField(
      name: name,
      bordered: bordered,
      readOnly: readOnly || !effectiveEnabled,
      hintTextList: hintTextList ?? _messages,
      isTransparentBackground: isTransparentBackground,
      enableFocusBorder: enableFocusBorder,
      child: WFormDatePickerCore(
        name: name,
        firstDate: firstDate ?? DateTime(1900),
        lastDate: lastDate ?? DateTime(2100),
        initialValue: initialValue,
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
      ),
    );
  }
}

class WFormCheckbox extends StatelessWidget {
  const WFormCheckbox({
    super.key,
    required this.name,
    required this.title,
    this.message,
    this.initialValue = false,
    this.validator,
    this.onChanged,
    this.enabled,
    this.readOnly = false,
    this.bordered = false,
    this.hintTextList,
    this.isTransparentBackground,
    this.enableFocusBorder = true,
    this.unselectedIcon,
    this.selectedIcon,
    this.disabledIcon,
    this.iconSpacing,
    this.iconYOffset,
    this.leading,
    this.actions,
    this.style,
    this.focusNode,
  });

  final String name;
  final Widget title;

  /// 提示文案（有边框时渲染）；与 [hintTextList] 二选一。
  final String? message;
  final bool initialValue;
  final FormFieldValidator<bool>? validator;
  final ValueChanged<bool?>? onChanged;
  final bool? enabled;
  final bool readOnly;
  final bool bordered;
  final List<String>? hintTextList;
  final bool? isTransparentBackground;
  final bool enableFocusBorder;
  final Widget? unselectedIcon;
  final Widget? selectedIcon;
  final Widget? disabledIcon;
  final double? iconSpacing;
  final double? iconYOffset;

  /// 标题文字样式（未传时取 `WForm.fieldStyle`）
  final TextStyle? style;

  /// 字段左侧插槽。
  final Widget? leading;

  /// 字段右侧操作插槽。
  final List<Widget>? actions;

  List<String>? get _messages => message != null ? [message!] : null;

  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    _assertHints(message, hintTextList);
    final fieldStyle = WFormFieldStyle.of(context);
    final effectiveEnabled = enabled ?? true;
    return assembleFormField(
      name: name,
      bordered: bordered,
      readOnly: readOnly || !effectiveEnabled,
      hintTextList: hintTextList ?? _messages,
      isTransparentBackground: isTransparentBackground,
      enableFocusBorder: enableFocusBorder,
      child: WFormCheckboxCore(
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
      ),
    );
  }
}

class WFormRadioGroup<T> extends StatelessWidget {
  const WFormRadioGroup({
    super.key,
    required this.name,
    required this.items,
    this.message,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.titleBuilder,
    this.itemExtraBuilder,
    this.enabled,
    this.readOnly = false,
    this.bordered = false,
    this.hintTextList,
    this.isTransparentBackground,
    this.enableFocusBorder = true,
    this.unselectedIcon,
    this.selectedIcon,
    this.iconSpacing,
    this.lineSpacing,
    this.iconYOffset,
    this.style,
    this.leading,
    this.actions,
    this.focusNode,
  });

  final String name;
  final Map<T, String> items;
  final T? initialValue;

  /// 提示文案（有边框时渲染）；与 [hintTextList] 二选一。
  final String? message;
  final FormFieldValidator<T>? validator;
  final ValueChanged<T?>? onChanged;
  final Widget Function(BuildContext, T, String, bool)? titleBuilder;
  final Widget Function(BuildContext, T, String, bool)? itemExtraBuilder;
  final bool? enabled;
  final bool readOnly;
  final bool bordered;
  final List<String>? hintTextList;
  final bool? isTransparentBackground;
  final bool enableFocusBorder;
  final Widget? unselectedIcon;
  final Widget? selectedIcon;
  final double? iconSpacing;
  final double? lineSpacing;
  final double? iconYOffset;
  final TextStyle? style;

  /// 字段左侧插槽。
  final Widget? leading;

  /// 字段右侧操作插槽。
  final List<Widget>? actions;

  List<String>? get _messages => message != null ? [message!] : null;

  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    _assertHints(message, hintTextList);
    final fieldStyle = WFormFieldStyle.of(context);
    final effectiveEnabled = enabled ?? true;
    return assembleFormField(
      name: name,
      bordered: bordered,
      readOnly: readOnly || !effectiveEnabled,
      hintTextList: hintTextList ?? _messages,
      isTransparentBackground: isTransparentBackground,
      enableFocusBorder: enableFocusBorder,
      child: WFormRadioGroupCore<T>(
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
      ),
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
class WFormFieldButton<T> extends StatelessWidget {
  const WFormFieldButton({
    super.key,
    required this.name,
    required this.onTap,
    this.label,
    this.hintWidget,
    this.message,
    this.selectedWidgetBuilder,
    this.initialValue,
    this.validator,
    this.focusNode,
    this.enabled,
    this.readOnly = false,
    this.bordered = true,
    this.hintTextList,
    this.isTransparentBackground,
    this.enableFocusBorder = true,
    this.leading,
    this.actions,
  });

  final String name;
  final void Function(T? value, ValueChanged<T> didChange) onTap;
  final String? label;
  final Widget? hintWidget;

  /// 提示文案（有边框时渲染）；与 [hintTextList] 二选一。
  final String? message;
  final Widget Function(T value)? selectedWidgetBuilder;
  final T? initialValue;
  final FormFieldValidator<T>? validator;
  final FocusNode? focusNode;
  final bool? enabled;
  final bool readOnly;
  final bool bordered;
  final List<String>? hintTextList;
  final bool? isTransparentBackground;
  final bool enableFocusBorder;
  final Widget? leading;

  /// 字段右侧操作插槽。
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    _assertHints(message, hintTextList);
    final fieldStyle = WFormFieldStyle.of(context);
    final effectiveEnabled = enabled ?? true;
    return assembleFormField(
      name: name,
      bordered: bordered,
      readOnly: readOnly || !effectiveEnabled,
      hintTextList: hintTextList ?? (message != null ? [message!] : null),
      isTransparentBackground: isTransparentBackground,
      enableFocusBorder: enableFocusBorder,
      child: WFormFieldButtonCore<T>(
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
      ),
    );
  }
}
