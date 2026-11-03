// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

/// 在测试中 pump 一个带 WFormScope 的完整 scaffold
///
/// 所有 form Widget 都必须放在 WFormScope 下面才能正常工作
/// （WFormTextFieldCore 通过 context.visitAncestorElements 查找它）
///
/// [formBorderConfig] 未显式传入时，使用一个只提供文案渲染的最小配置
/// （生产代码不再内置默认主题，测试里需要能断言错误/提示文本）。
Future<void> pumpForm(
  WidgetTester tester, {
  required Widget child,
  WFormController? formData,
  WFormBorderConfig? formBorderConfig,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WFormScope(
          formData: formData ?? WFormController(),
          formBorderConfig: formBorderConfig ?? terseBorderConfig(),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
}

/// 测试用最小边框配置：只提供文案渲染能力，不设置任何装饰
WFormBorderConfig terseBorderConfig() {
  Widget buildMessages(List<String>? list) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final message in list ?? const <String>[]) Text(message),
    ],
  );

  return WFormBorderConfig(
    hintBuilder: buildMessages,
    errorBuilder: buildMessages,
  );
}

/// 测试专用：用可变字段拼装不可变 [WFormBorderConfig]。
///
/// 生产 API 的 `WFormBorderConfigBuilder` 已在 4.0 删除；测试保留一个等价 helper，
/// 避免每个用例重复写构造参数。
class TestFormBorderBuilder {
  WFormBorderDecoration? defaultDecoration;
  WFormBorderDecoration? readOnlyDecoration;
  WFormBorderDecoration? errorDecoration;
  WFormBorderDecoration? focusedDecoration;
  TextStyle? hintStyle;
  TextStyle? errorStyle;
  Widget Function(List<String>? list)? hintBuilder;
  Widget Function(List<String>? list)? errorBuilder;
  WFormBorderLayout layout = WFormBorderLayout.column;

  WFormBorderConfig buildConfig() => WFormBorderConfig(
    defaultDecoration: defaultDecoration,
    readOnlyDecoration: readOnlyDecoration,
    errorDecoration: errorDecoration,
    focusedDecoration: focusedDecoration,
    hintStyle: hintStyle,
    errorStyle: errorStyle,
    hintBuilder: hintBuilder,
    errorBuilder: errorBuilder,
    layout: layout,
  );
}

/// 测试专用：4.0 删除的 `Row.withFormBorder` 的等价实现。
///
/// 生产代码直接用 `WFormFieldShell(child: Row(...))`；测试保留糖，避免逐处改。
extension TestRowBorder on Row {
  Widget withFormBorder({
    required String name,
    List<String>? hintTextList,
    bool? isTransparentBackground,
    bool readOnly = false,
    bool enableFocusBorder = true,
    bool useIntrinsicHeight = false,
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
      useIntrinsicHeight: useIntrinsicHeight,
      child: this,
    );
  }
}
