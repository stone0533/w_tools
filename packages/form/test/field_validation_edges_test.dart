import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  testWidgets('bordered: false 的字段同样拒绝空 name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: const WFormTextField(name: '', bordered: false),
          ),
        ),
      ),
    );

    // 空 name 在两种 bordered 分支下都必须是 ArgumentError，
    // 不能只有 bordered: true 走外框时才校验。
    expect(tester.takeException(), isArgumentError);
  });
}
