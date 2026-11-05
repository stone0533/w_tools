import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:w_tools_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('黑盒：启动 → 提交表单 → 显示结果', (tester) async {
    await tester.pumpWidget(const AggregateExampleApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Ada');
    await tester.tap(find.text('提交'));
    await tester.pumpAndSettle();

    expect(find.text('提交结果'), findsOneWidget);
    expect(find.text('Ada / 香港'), findsOneWidget);
  });
}
