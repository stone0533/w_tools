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
}
