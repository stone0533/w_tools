import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  testWidgets('改 borderStyle 不会重置 WForm 注入的 validatorSettings', (tester) async {
    final form = WFormController();
    const manual = WFormValidatorSettings(continueOnError: true, showBorderError: true);

    Widget build(WFormBorderStyle style) => MaterialApp(
      home: Scaffold(
        body: WForm(
          controller: form,
          borderStyle: style,
          validatorSettings: manual,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    await tester.pumpWidget(build(const WFormBorderStyle()));
    expect(form.validatorSettings, same(manual));

    // 只是换边框样式，和校验设置无关；不能把 WForm 注入的设置覆盖掉。
    await tester.pumpWidget(
      build(const WFormBorderStyle(errorStyle: TextStyle(color: Colors.red))),
    );

    expect(form.validatorSettings, same(manual));
  });
}
