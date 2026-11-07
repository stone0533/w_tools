import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  testWidgets('WFormFieldButton<int> 存 int 值并使用泛型选中渲染', (tester) async {
    final form = WFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: WFormFieldButton<int>(
              name: 'level',
              label: '选择等级',
              selectedWidgetBuilder: (value) => Text('已选等级 $value'),
              onTap: (_, didChange) => didChange(3),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('选择等级'));
    await tester.pump();

    expect(form.getFieldsValue<int>('level'), 3);
    expect(find.text('已选等级 3'), findsOneWidget);
  });
}
