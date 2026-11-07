import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  testWidgets('WFormCheckbox.message 在有边框时作为提示显示', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            borderConfig: WFormBorderConfig.standard(),
            child: const WFormCheckbox(
              name: 'agree',
              title: Text('同意'),
              message: '请先同意协议',
              bordered: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('请先同意协议'), findsOneWidget);
  });

  testWidgets('WFormRadioGroup.message 在有边框时作为提示显示', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            borderConfig: WFormBorderConfig.standard(),
            child: const WFormRadioGroup<String>(
              name: 'gender',
              items: {'female': '女', 'male': '男'},
              message: '请选择性别',
              bordered: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('请选择性别'), findsOneWidget);
  });
}
