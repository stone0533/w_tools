import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'field_base_config.dart';
import 'field_button.dart';
import 'form_field_style.dart';
import 'fields/checkbox.dart';
import 'fields/date_picker.dart';
import 'fields/dropdown.dart';
import 'fields/multi_dropdown.dart';
import 'fields/radio_group.dart';
import 'fields/text_field.dart';

void _applyBaseStyle(
  WFormFieldBaseConfig config,
  WFormFieldStyle? style,
) {
  if (style == null) return;
  if (style.height != null) config.height = style.height;
  if (style.containerPadding != null) {
    config.containerPadding = style.containerPadding;
  }
}

/// 直接构造的表单字段。
///
/// 这些 Widget 是日常业务入口：常用参数直接传入，样式通过可选 config 覆盖。
/// 字段仍由既有 Config.build 实现，边框 / 校验 / 只读等能力保持不变。
class WFormTextField extends StatelessWidget {
  const WFormTextField({
    super.key,
    required this.name,
    this.label,
    this.message,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.focusNode,
    this.enabled = true,
    this.readOnly = false,
    this.bordered = true,
    this.obscureText = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines,
    this.inputFormatters,
    this.actions,
    this.config,
    this.hintTextList,
    this.isTransparentBackground,
    this.borderKey,
    this.enableFocusBorder = true,
  });

  final String name;
  final String? label;
  final String? message;
  final String? initialValue;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String?>? onChanged;
  final void Function(String?)? onSubmitted;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final bool enabled;
  final bool readOnly;
  final bool bordered;
  final bool obscureText;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final List<Widget>? actions;
  final WFormTextFieldConfig? config;
  final List<String>? hintTextList;
  final bool? isTransparentBackground;
  final Key? borderKey;
  final bool enableFocusBorder;

  @override
  Widget build(BuildContext context) {
    final fieldStyle = WFormFieldStyle.of(context);
    final c = config?.copy() ?? WFormTextFieldConfig();
    if (config == null) {
      _applyBaseStyle(c, fieldStyle);
      if (fieldStyle?.textStyle != null) c.style = fieldStyle!.textStyle;
      if (fieldStyle?.hintStyle != null) c.hintStyle = fieldStyle!.hintStyle;
    }
    c
      ..enabled = enabled
      ..obscureText = obscureText
      ..autofocus = autofocus;
    if (keyboardType != null) c.keyboardType = keyboardType;
    if (textInputAction != null) c.textInputAction = textInputAction;
    if (maxLines != null) c.maxLines = maxLines;
    if (inputFormatters != null) c.inputFormatters = inputFormatters;
    if (actions != null) c.actions = actions;

    return c.build(
      name: name,
      initialValue: initialValue,
      hintText: label,
      validator: validator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      focusNode: focusNode,
      readOnly: readOnly,
      bordered: bordered,
      hintTextList: hintTextList ?? _messages,
      isTransparentBackground: isTransparentBackground,
      borderKey: borderKey,
      enableFocusBorder: enableFocusBorder,
    );
  }

  List<String>? get _messages {
    if (message != null) return [message!];
    if (label != null) return [label!];
    return null;
  }
}

class WFormDropdown<T> extends StatelessWidget {
  const WFormDropdown({
    super.key,
    required this.name,
    required this.items,
    this.label,
    this.message,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.bordered = true,
    this.hintTextList,
    this.isTransparentBackground,
    this.borderKey,
    this.enableFocusBorder = true,
    this.config,
  });

  final String name;
  final Map<T, String> items;
  final String? label;
  final String? message;
  final T? initialValue;
  final FormFieldValidator<T>? validator;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final bool readOnly;
  final bool bordered;
  final List<String>? hintTextList;
  final bool? isTransparentBackground;
  final Key? borderKey;
  final bool enableFocusBorder;
  final WFormDropdownConfig? config;

  @override
  Widget build(BuildContext context) {
    final fieldStyle = WFormFieldStyle.of(context);
    final c = config?.copy() ?? WFormDropdownConfig();
    if (config == null) {
      _applyBaseStyle(c, fieldStyle);
      if (fieldStyle?.textStyle != null) c.style = fieldStyle!.textStyle;
      if (fieldStyle?.hintStyle != null) c.hintStyle = fieldStyle!.hintStyle;
    }
    c.enabled = enabled;
    return c.build<T>(
      name: name,
      items: items,
      initialValue: initialValue,
      validator: validator,
      onChanged: onChanged,
      hintText: label,
      bordered: bordered,
      hintTextList: hintTextList ?? _messages,
      isTransparentBackground: isTransparentBackground,
      borderKey: borderKey,
      enableFocusBorder: enableFocusBorder,
      readOnly: readOnly,
    );
  }

  List<String>? get _messages => message != null ? [message!] : null;
}

class WFormMultiDropdown extends StatelessWidget {
  const WFormMultiDropdown({
    super.key,
    required this.name,
    required this.items,
    this.label,
    this.message,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.bordered = true,
    this.hintTextList,
    this.isTransparentBackground,
    this.borderKey,
    this.enableFocusBorder = true,
    this.config,
  });

  final String name;
  final Map<String, String> items;
  final String? label;
  final String? message;
  final Set<String>? initialValue;
  final FormFieldValidator<Set<String>>? validator;
  final ValueChanged<Set<String>>? onChanged;
  final bool enabled;
  final bool readOnly;
  final bool bordered;
  final List<String>? hintTextList;
  final bool? isTransparentBackground;
  final Key? borderKey;
  final bool enableFocusBorder;
  final WFormMultiDropdownConfig? config;

  @override
  Widget build(BuildContext context) {
    final fieldStyle = WFormFieldStyle.of(context);
    final c = config?.copy() ?? WFormMultiDropdownConfig();
    if (config == null) {
      _applyBaseStyle(c, fieldStyle);
      if (fieldStyle?.textStyle != null) c.style = fieldStyle!.textStyle;
      c.hintText = label ?? c.hintText;
    }
    c.enabled = enabled;
    return c.build(
      name: name,
      items: items,
      initialValue: initialValue,
      validator: validator,
      onChanged: onChanged,
      hintText: label,
      bordered: bordered,
      hintTextList: hintTextList ?? _messages,
      isTransparentBackground: isTransparentBackground,
      borderKey: borderKey,
      enableFocusBorder: enableFocusBorder,
      readOnly: readOnly,
    );
  }

  List<String>? get _messages => message != null ? [message!] : null;
}

class WFormDatePicker extends StatelessWidget {
  const WFormDatePicker({
    super.key,
    required this.name,
    this.label,
    this.message,
    this.initialValue,
    this.firstDate,
    this.lastDate,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.bordered = true,
    this.hintTextList,
    this.isTransparentBackground,
    this.borderKey,
    this.enableFocusBorder = true,
    this.config,
  });

  final String name;
  final String? label;
  final String? message;
  final String? initialValue;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String?>? onChanged;
  final bool enabled;
  final bool readOnly;
  final bool bordered;
  final List<String>? hintTextList;
  final bool? isTransparentBackground;
  final Key? borderKey;
  final bool enableFocusBorder;
  final WFormDatePickerConfig? config;

  @override
  Widget build(BuildContext context) {
    final fieldStyle = WFormFieldStyle.of(context);
    final c = config?.copy() ?? WFormDatePickerConfig();
    if (config == null) {
      _applyBaseStyle(c, fieldStyle);
      if (fieldStyle?.textStyle != null) c.style = fieldStyle!.textStyle;
      if (label != null) c.decoration = InputDecoration(hintText: label);
    }
    c.enabled = enabled;
    return c.build(
      name: name,
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime.now(),
      initialValue: initialValue,
      validator: validator,
      onChanged: onChanged,
      bordered: bordered,
      hintTextList: hintTextList ?? _messages,
      isTransparentBackground: isTransparentBackground,
      borderKey: borderKey,
      enableFocusBorder: enableFocusBorder,
      readOnly: readOnly,
    );
  }

  List<String>? get _messages => message != null ? [message!] : null;
}

class WFormCheckbox extends StatelessWidget {
  const WFormCheckbox({
    super.key,
    required this.name,
    required this.title,
    this.initialValue = false,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.bordered = false,
    this.hintTextList,
    this.isTransparentBackground,
    this.borderKey,
    this.enableFocusBorder = true,
    this.config,
  });

  final String name;
  final Widget title;
  final bool initialValue;
  final FormFieldValidator<bool>? validator;
  final ValueChanged<bool?>? onChanged;
  final bool enabled;
  final bool readOnly;
  final bool bordered;
  final List<String>? hintTextList;
  final bool? isTransparentBackground;
  final Key? borderKey;
  final bool enableFocusBorder;
  final WFormCheckboxConfig? config;

  @override
  Widget build(BuildContext context) {
    final fieldStyle = WFormFieldStyle.of(context);
    final c = config?.copy() ?? WFormCheckboxConfig();
    if (config == null) _applyBaseStyle(c, fieldStyle);
    c.enabled = enabled;
    return c.build(
      name: name,
      title: title,
      initialValue: initialValue,
      validator: validator,
      onChanged: onChanged,
      readOnly: readOnly,
      bordered: bordered,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      borderKey: borderKey,
      enableFocusBorder: enableFocusBorder,
    );
  }
}

class WFormRadioGroup<T> extends StatelessWidget {
  const WFormRadioGroup({
    super.key,
    required this.name,
    required this.items,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.titleBuilder,
    this.itemExtraBuilder,
    this.enabled = true,
    this.readOnly = false,
    this.bordered = false,
    this.hintTextList,
    this.isTransparentBackground,
    this.borderKey,
    this.enableFocusBorder = true,
    this.config,
  });

  final String name;
  final Map<T, String> items;
  final T? initialValue;
  final FormFieldValidator<T>? validator;
  final ValueChanged<T?>? onChanged;
  final Widget Function(BuildContext, T, String, bool)? titleBuilder;
  final Widget Function(BuildContext, T, String, bool)? itemExtraBuilder;
  final bool enabled;
  final bool readOnly;
  final bool bordered;
  final List<String>? hintTextList;
  final bool? isTransparentBackground;
  final Key? borderKey;
  final bool enableFocusBorder;
  final WFormRadioGroupConfig? config;

  @override
  Widget build(BuildContext context) {
    final fieldStyle = WFormFieldStyle.of(context);
    final c = config?.copy() ?? WFormRadioGroupConfig();
    if (config == null) {
      _applyBaseStyle(c, fieldStyle);
      if (fieldStyle?.textStyle != null) c.style = fieldStyle!.textStyle;
    }
    c.enabled = enabled;
    return c.build<T>(
      name: name,
      items: items,
      initialValue: initialValue,
      validator: validator,
      onChanged: onChanged,
      titleBuilder: titleBuilder,
      itemExtraBuilder: itemExtraBuilder,
      readOnly: readOnly,
      bordered: bordered,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      borderKey: borderKey,
      enableFocusBorder: enableFocusBorder,
    );
  }
}

class WFormButton extends StatelessWidget {
  const WFormButton({
    super.key,
    required this.name,
    required this.onTap,
    this.label,
    this.hintWidget,
    this.selectedWidgetBuilder,
    this.initialValue,
    this.validator,
    this.focusNode,
    this.enabled = true,
    this.readOnly = false,
    this.bordered = true,
    this.hintTextList,
    this.isTransparentBackground,
    this.borderKey,
    this.enableFocusBorder = true,
    this.config,
  });

  final String name;
  final void Function(String? value, ValueChanged<String> didChange) onTap;
  final String? label;
  final Widget? hintWidget;
  final Widget Function(String value)? selectedWidgetBuilder;
  final String? initialValue;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;
  final bool enabled;
  final bool readOnly;
  final bool bordered;
  final List<String>? hintTextList;
  final bool? isTransparentBackground;
  final Key? borderKey;
  final bool enableFocusBorder;
  final WFormFieldButtonConfig? config;

  @override
  Widget build(BuildContext context) {
    final fieldStyle = WFormFieldStyle.of(context);
    final c = config?.copy() ?? WFormFieldButtonConfig();
    if (config == null) _applyBaseStyle(c, fieldStyle);
    c
      ..enabled = enabled
      ..hintWidget = hintWidget ?? (label == null ? null : Text(label!));
    return c.build(
      name: name,
      onTap: onTap,
      selectedWidgetBuilder: selectedWidgetBuilder,
      initialValue: initialValue,
      validator: validator,
      focusNode: focusNode,
      readOnly: readOnly,
      bordered: bordered,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      borderKey: borderKey,
      enableFocusBorder: enableFocusBorder,
    );
  }
}
