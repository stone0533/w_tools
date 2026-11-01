import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools/w.dart';
import 'package:w_tools_example/main.dart';

void main() {
  testWidgets('聚合入口表单可以提交', (tester) async {
    await tester.pumpWidget(const AggregateExampleApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Ada');
    await tester.tap(find.widgetWithText(WButton, '提交'));
    await tester.pumpAndSettle();

    expect(find.text('提交结果'), findsOneWidget);
    expect(find.text('Ada / 香港'), findsOneWidget);
    expect(find.text('聚合入口的异步结果'), findsOneWidget);
  });
}
