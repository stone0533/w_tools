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

  testWidgets('WForm(readOnly: true) 覆盖下拉 / 多选 / 日期 / 单选', (tester) async {
    final form = WFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            readOnly: true,
            child: ListView(
              children: const [
                WFormDropdown<String>(
                  name: 'country',
                  hintText: '国家',
                  items: {'CN': '中国'},
                ),
                WFormMultiDropdown<String>(
                  name: 'tags',
                  hintText: '标签',
                  items: {'a': 'A'},
                ),
                WFormDatePicker(name: 'birthday', hintText: '生日'),
                WFormRadioGroup<String>(
                  name: 'gender',
                  items: {'male': '男'},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('国家'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('中国'), findsNothing);

    await tester.tap(find.text('标签'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('A'), findsNothing);

    await tester.tap(find.text('生日'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);

    await tester.tap(find.text('男'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(form.value['gender'], isNull);

    expect(form.value['country'], isNull);
    expect(form.value['tags'], isNull);
    expect(form.value['birthday'], isNull);
  });
}
