import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

Future<void> _pump(
  WidgetTester tester, {
  required WFormController form,
  required Widget child,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WForm(
          controller: form,
          borderStyle: WFormBorderStyle.standard(),
          child: child,
        ),
      ),
    ),
  );
}

void _focusField(WFormController form, String name) {
  form.formKey.currentState!.fields[name]!.focus();
}

void main() {
  testWidgets('checkbox：focusNode 接到可交互控件，Enter 可切换值', (tester) async {
    final form = WFormController();
    final node = FocusNode();
    addTearDown(node.dispose);

    await _pump(
      tester,
      form: form,
      child: WFormCheckbox(name: 'agree', title: const Text('同意'), focusNode: node),
    );

    _focusField(form, 'agree');
    await tester.pump();
    expect(node.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(form.value['agree'], isTrue);
  });

  testWidgets('radio：focusNode 聚焦首个选项，Enter 可选中', (tester) async {
    final form = WFormController();
    final node = FocusNode();
    addTearDown(node.dispose);

    await _pump(
      tester,
      form: form,
      child: WFormRadioGroup<String>(
        name: 'gender',
        items: const {'female': '女', 'male': '男'},
        focusNode: node,
      ),
    );

    _focusField(form, 'gender');
    await tester.pump();
    expect(node.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(form.value['gender'], 'female');
  });

  testWidgets('date：focusNode 聚焦触发区，Enter 可打开日期选择器', (tester) async {
    final form = WFormController();
    final node = FocusNode();
    addTearDown(node.dispose);

    await _pump(
      tester,
      form: form,
      child: WFormDatePicker(name: 'birthday', focusNode: node),
    );

    _focusField(form, 'birthday');
    await tester.pump();
    expect(node.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('multi：focusNode 聚焦触发区，Space 可打开弹层', (tester) async {
    final form = WFormController();
    final node = FocusNode();
    addTearDown(node.dispose);

    await _pump(
      tester,
      form: form,
      child: WFormMultiDropdown(
        name: 'tags',
        items: const {'a': '选项 A'},
        focusNode: node,
      ),
    );

    _focusField(form, 'tags');
    await tester.pump();
    expect(node.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text('选项 A'), findsOneWidget);

    // 关闭弹层，避免路由留到下一个用例。
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
  });

  testWidgets('button：focusNode 接到 InkWell，Enter 可触发 onTap', (tester) async {
    final form = WFormController();
    final node = FocusNode();
    addTearDown(node.dispose);
    var tapped = 0;

    await _pump(
      tester,
      form: form,
      child: WFormFieldButton<String>(
        name: 'coupon',
        label: '选择优惠券',
        focusNode: node,
        onTap: (value, didChange) {
          tapped++;
          didChange('new_user');
        },
      ),
    );

    _focusField(form, 'coupon');
    await tester.pump();
    expect(node.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(tapped, 1);
    expect(form.value['coupon'], 'new_user');
  });
}
