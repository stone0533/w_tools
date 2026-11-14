import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/src/components/border/border_access.dart' as access;
import 'package:w_tools_form/src/components/border/border_registry.dart';
import 'package:w_tools_form/src/components/field_assembly.dart';
import 'package:w_tools_form/src/components/fields/checkbox.dart';
import 'package:w_tools_form/src/components/field_button.dart';
import 'package:w_tools_form/src/components/fields/text_field.dart';
import 'package:w_tools_form/src/components/fields/radio_group.dart';
import 'package:w_tools_form/w_tools_form.dart';
import 'package:w_tools_form/src/components/form_scope.dart';

/// 测试专用：读取 controller 的边框错误通道。
///
/// 生产 API 不再暴露 `WFormController.borders`；这个 helper 只给测试用。
WFormBorderRegistry formBordersOf(WFormController form) => access.bordersOf(form);

/// 在测试中 pump 一个带 WFormScope 的完整 scaffold
///
/// 所有 form Widget 都必须放在 WFormScope 下面才能正常工作
/// （核心组件通过 WFormScope 的 InheritedWidget 查找 controller）。
///
/// [formBorderStyle] 未显式传入时，使用一个只提供文案渲染的最小配置
/// （生产代码不再内置默认主题，测试里需要能断言错误/提示文本）。
Future<void> pumpForm(
  WidgetTester tester, {
  required Widget child,
  WFormController? formData,
  WFormBorderStyle? formBorderStyle,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WFormTheme(
          borderStyle: formBorderStyle ?? terseBorderStyle(),
          child: WFormScope(
            formData: formData ?? WFormController(),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// 测试专用：`WFormScope` + 外层 `WFormTheme(borderStyle:)`。
///
/// 7.0 起 `WFormScope` 不再接受 `formBorderStyle`；测试要配边框就包这一层。
Widget themedScope({
  required WFormController formData,
  required Widget child,
  WFormBorderStyle? formBorderStyle,
  AutovalidateMode? autovalidateMode,
  ValueChanged<Map<String, dynamic>>? onChanged,
}) {
  return WFormTheme(
    borderStyle: formBorderStyle,
    child: WFormScope(
      formData: formData,
      autovalidateMode: autovalidateMode,
      onChanged: onChanged,
      child: child,
    ),
  );
}

/// 测试用最小边框配置：只提供文案渲染能力，不设置任何装饰
WFormBorderStyle terseBorderStyle() {
  Widget buildMessages(List<String>? list) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final message in list ?? const <String>[]) Text(message),
    ],
  );

  return WFormBorderStyle(
    hintBuilder: buildMessages,
    errorBuilder: buildMessages,
  );
}

/// 测试专用：用可变字段拼装不可变 [WFormBorderStyle]。
///
/// 生产 API 的 `WFormBorderStyleBuilder` 已在 4.0 删除；测试保留一个等价 helper，
/// 避免每个用例重复写构造参数。
class TestFormBorderBuilder {
  BoxDecoration? defaultDecoration;
  BoxDecoration? readOnlyDecoration;
  BoxDecoration? errorDecoration;
  BoxDecoration? focusedDecoration;
  TextStyle? helperStyle;
  TextStyle? errorStyle;
  Widget Function(List<String>? list)? hintBuilder;
  Widget Function(List<String>? list)? errorBuilder;

  WFormBorderStyle buildStyle() => WFormBorderStyle(
    defaultDecoration: defaultDecoration,
    readOnlyDecoration: readOnlyDecoration,
    errorDecoration: errorDecoration,
    focusedDecoration: focusedDecoration,
    helperStyle: helperStyle,
    errorStyle: errorStyle,
    hintBuilder: hintBuilder,
    errorBuilder: errorBuilder,
  );
}

/// 测试专用：`Row.withFormBorder` 在 4.0 已删除，这里只作为
/// `WFormFieldShell(child: Row(...))` 的装配糖，测的是公开的 `WFormFieldShell`
/// 与只读作用域，不代表已删除的扩展仍然存在。
extension TestRowBorder on Row {
  Widget withFormBorder({
    required String name,
    List<String>? hintTextList,
    bool? isTransparentBackground,
    bool readOnly = false,
    bool enableFocusBorder = true,
    Key? key,
  }) {
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', '字段名称不能为空');
    }
    return WFormFieldShell(
      key: key,
      name: name,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      readOnly: readOnly,
      enableFocusBorder: enableFocusBorder,
      child: this,
    );
  }
}

/// 测试用：无边框的单选字段（等价于直接字段的非 bordered 路径）。
Widget radioCore<T>({
  required String name,
  required Map<T, String> items,
  T? initialValue,
  ValueChanged<T?>? onChanged,
  FormFieldValidator<T>? validator,
  bool enabled = true,
  bool readOnly = false,
  bool bordered = false,
}) {
  return assembleFormField(
    name: name,
    bordered: bordered,
    readOnly: readOnly || !enabled,
    rendersInlineError: false,
    child: WFormRadioGroupCore<T>(
      name: name,
      items: items,
      initialValue: initialValue,
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
    ),
  );
}

/// 测试用：无边框的复选字段（等价于直接字段的非 bordered 路径）。
Widget checkboxCore({
  required String name,
  required Widget title,
  bool initialValue = false,
  ValueChanged<bool?>? onChanged,
  FormFieldValidator<bool>? validator,
  bool enabled = true,
  bool readOnly = false,
  bool bordered = false,
  Widget? unselectedIcon,
  Widget? selectedIcon,
  Widget? disabledIcon,
  double? iconSpacing,
  double? iconYOffset,
  TextStyle? style,
}) {
  return assembleFormField(
    name: name,
    bordered: bordered,
    readOnly: readOnly || !enabled,
    rendersInlineError: false,
    child: WFormCheckboxCore(
      name: name,
      title: title,
      initialValue: initialValue,
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
      unselectedIcon: unselectedIcon,
      selectedIcon: selectedIcon,
      disabledIcon: disabledIcon,
      iconSpacing: iconSpacing,
      iconYOffset: iconYOffset,
      style: style,
    ),
  );
}

/// 测试用：字段按钮（等价于直接字段的非 bordered 路径）。
Widget buttonCore({
  required String name,
  required void Function(String? value, ValueChanged<String> didChange) onTap,
  Widget Function(String value)? selectedWidgetBuilder,
  String? initialValue,
  bool? enabled,
  FormFieldValidator<String>? validator,
  FocusNode? focusNode,
  bool readOnly = false,
  bool bordered = false,
  List<String>? hintTextList,
  Widget? hintWidget,
  double? height,
  double? width,
  double? yOffset,
  Widget? leading,
  List<Widget>? actions,
  Decoration? containerDecoration,
  EdgeInsetsGeometry? containerMargin,
  EdgeInsetsGeometry? containerPadding,
}) {
  final effectiveEnabled = enabled ?? true;
  return assembleFormField(
    name: name,
    bordered: bordered,
    readOnly: readOnly || !effectiveEnabled,
    rendersInlineError: false,
    hintTextList: hintTextList,
    child: WFormFieldButtonCore<String>(
      name: name,
      onTap: onTap,
      selectedWidgetBuilder: selectedWidgetBuilder,
      initialValue: initialValue,
      enabled: effectiveEnabled,
      validator: validator,
      focusNode: focusNode,
      hintWidget: hintWidget,
      height: height,
      width: width,
      yOffset: yOffset,
      leading: leading,
      actions: actions,
      containerDecoration: containerDecoration,
      containerMargin: containerMargin,
      containerPadding: containerPadding,
    ),
  );
}

/// 测试用：文本字段（等价于直接字段的装配路径，bordered 可选）。
Widget textCore({
  required String name,
  String? initialValue,
  String? hintText,
  FormFieldValidator<String>? validator,
  ValueChanged<String?>? onChanged,
  void Function(String?)? onSubmitted,
  VoidCallback? onEditingComplete,
  FocusNode? focusNode,
  bool readOnly = false,
  bool bordered = false,
  List<String>? hintTextList,
  bool? isTransparentBackground,
  bool enableFocusBorder = true,
  bool enabled = true,
  bool obscureText = false,
  InputDecoration? decoration,
  TextStyle? style,
  TextStyle? hintStyle,
  TextStyle? readOnlyStyle,
  EdgeInsetsGeometry? contentPadding,
  Widget? prefix,
  Widget? prefixIcon,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  TextAlign? textAlign,
  bool? autofocus,
  int? maxLines,
  TextInputAction? textInputAction,
  double? height,
  double? width,
  double? yOffset,
  Widget? leading,
  List<Widget>? actions,
  Decoration? containerDecoration,
  EdgeInsetsGeometry? containerMargin,
  EdgeInsetsGeometry? containerPadding,
}) {
  return assembleFormField(
    name: name,
    bordered: bordered,
    readOnly: readOnly || !enabled,
    hintTextList: hintTextList,
    isTransparentBackground: isTransparentBackground,
    enableFocusBorder: enableFocusBorder,
    child: WFormTextFieldCore(
      name: name,
      initialValue: initialValue,
      hintText: hintText,
      validator: validator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      focusNode: focusNode,
      readOnly: readOnly,
      enabled: enabled,
      decoration: decoration,
      style: style,
      hintStyle: hintStyle,
      readOnlyStyle: readOnlyStyle,
      contentPadding: contentPadding,
      prefix: prefix,
      prefixIcon: prefixIcon,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      autofocus: autofocus,
      maxLines: maxLines,
      textInputAction: textInputAction,
      height: height,
      width: width,
      yOffset: yOffset,
      leading: leading,
      actions: actions,
      containerDecoration: containerDecoration,
      containerMargin: containerMargin,
      containerPadding: containerPadding,
    ),
  );
}
