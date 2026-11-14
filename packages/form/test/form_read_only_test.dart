import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  testWidgets('WForm(readOnly: true) 禁用文本 / 复选 / 字段按钮', (tester) async {
    final form = WFormController();
    var buttonTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            readOnly: true,
            child: Column(
              children: [
                const WFormTextField(name: 'email', hintText: '邮箱'),
                const WFormCheckbox(name: 'agree', title: Text('同意')),
                WFormButton(
                  name: 'coupon',
                  label: '选择优惠券',
                  onTap: (_, didChange) {
                    buttonTaps++;
                    didChange('new_user');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.enabled, isFalse);
    expect(textField.readOnly, isTrue);

    await tester.tap(find.text('同意'));
    await tester.pump();
    expect(form.value['agree'], isFalse);

    await tester.tap(find.text('选择优惠券'));
    await tester.pump();
    expect(buttonTaps, 0);
    expect(form.value['coupon'], isNull);
  });

  testWidgets('WForm(readOnly: false) 可编辑', (tester) async {
    final form = WFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: const WFormTextField(name: 'email', hintText: '邮箱'),
          ),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.enabled, isTrue);
  });
}
