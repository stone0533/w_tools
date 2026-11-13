import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  testWidgets('WFormMultiDropdown<int> 使用 Set<int> 值', (tester) async {
    final form = WFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: const WFormMultiDropdown<int>(
              name: 'levels',
              items: {1: '一级', 2: '二级'},
              initialValue: {1},
            ),
          ),
        ),
      ),
    );

    expect(find.text('一级'), findsOneWidget);

    await tester.tap(find.byType(WFormMultiDropdown<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('二级'));
    await tester.pumpAndSettle();

    expect(form.value['levels'], {1, 2});
  });
}
