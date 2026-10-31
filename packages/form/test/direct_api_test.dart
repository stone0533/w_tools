import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  testWidgets('WForm + 直接字段构造', (tester) async {
    final form = WFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            borderConfig: WFormBorderConfig.standard(),
            child: Column(
              children: [
                WFormTextField(
                  name: 'email',
                  label: '邮箱',
                  validator: (value) => (value == null || value.isEmpty) ? '请输入邮箱' : null,
                ),
                const WFormDropdown<String>(
                  name: 'country',
                  label: '国家',
                  items: {'CN': '中国'},
                ),
                WFormButton(
                  name: 'coupon',
                  label: '选择优惠券',
                  onTap: (_, didChange) => didChange('new_user'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('邮箱'), findsWidgets);
    expect(find.text('国家'), findsWidgets);
    expect(find.text('选择优惠券'), findsOneWidget);
  });

  testWidgets('WForm 直接 API 走字段 validator', (tester) async {
    final form = WFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: WFormTextField(
              name: 'email',
              label: '邮箱',
              validator: (value) => (value == null || value.isEmpty) ? '请输入邮箱' : null,
            ),
          ),
        ),
      ),
    );

    final valid = form.validate(
      settings: WFormValidatorSettings()..showBorderError = true,
    );
    expect(valid, isFalse);
  });
}
