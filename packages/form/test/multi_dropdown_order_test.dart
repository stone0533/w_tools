import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  testWidgets('多选展示顺序 = 选择先后（不是 items 顺序）', (tester) async {
    final form = WFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: const WFormMultiDropdown(
              name: 'tags',
              items: {'a': 'A', 'b': 'B'},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(WFormMultiDropdown<String>));
    await tester.pumpAndSettle();

    // 先选 B，再选 A：展示必须按点击先后拼成 "B, A"。
    await tester.tap(find.text('B').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('A').last);
    await tester.pumpAndSettle();

    expect(form.value['tags'], {'b', 'a'});
    expect(find.text('B, A'), findsOneWidget);
  });
}
