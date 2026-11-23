import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  testWidgets('字段自己的 onChanged 回写同值：no-op，不递归', (tester) async {
    final form = WFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: WFormTextField(
              name: 'email',
              onChanged: (value) => form.setValue('email', value),
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'stone@sam');
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(form.value['email'], 'stone@sam');
  });

  testWidgets('程序化 setValue 仍能写值并清错误', (tester) async {
    final form = WFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: const WFormTextField(name: 'email'),
          ),
        ),
      ),
    );

    form.setValue('email', 'manual@example.com');
    await tester.pump();

    expect(form.value['email'], 'manual@example.com');
  });

  testWidgets('挂载前 setValue 会断言失败（不再静默丢值）', (tester) async {
    final form = WFormController();

    expect(() => form.setValue('q', 'abc'), throwsAssertionError);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: const WFormTextField(name: 'q', hintText: '搜索'),
          ),
        ),
      ),
    );

    form.setValue('q', 'abc');
    await tester.pump();
    expect(form.value['q'], 'abc');
    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, 'abc');
  });

  testWidgets('initialValue 变更不会让清除按钮与字段真实值分叉', (tester) async {
    final form = WFormController();

    Widget build(String? initial) => MaterialApp(
      home: Scaffold(
        body: WForm(
          controller: form,
          child: WFormTextField(
            name: 'q',
            hintText: '搜索',
            initialValue: initial,
            actions: const [WFormTextFieldClearButton()],
          ),
        ),
      ),
    );

    await tester.pumpWidget(build(null));
    expect(find.byIcon(Icons.clear), findsNothing);

    // initialValue 只在首次挂载生效；rebuild 不写值，按钮也不能假装有值。
    await tester.pumpWidget(build('abc'));
    await tester.pump();

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, '');
    expect(form.value['q'], isNull);
    expect(find.byIcon(Icons.clear), findsNothing);
  });
}
