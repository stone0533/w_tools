import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

/// 在测试中 pump 一个带 WFormBuilder 的完整 scaffold
///
/// 所有 form Widget 都必须放在 WFormBuilder 下面才能正常工作
/// （WFormTextField 通过 context.visitAncestorElements 查找它）
///
/// [formBorderConfig] 未显式传入时，使用一个只提供文案渲染的最小配置
/// （生产代码不再内置默认主题，测试里需要能断言错误/提示文本）。
Future<void> pumpForm(
  WidgetTester tester, {
  required Widget child,
  WFormData? formData,
  WFormBorderConfig? formBorderConfig,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WFormBuilder(
          formData: formData ?? WFormData(),
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

  return WFormBorderConfig()
    ..hintBuilder = buildMessages
    ..errorBuilder = buildMessages;
}
