import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:w_tools_core_example/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('邮箱校验与 AES 示例', (tester) async {
    await tester.pumpWidget(const CoreExampleApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'dev@example.com');
    await tester.tap(find.text('校验邮箱'));
    await tester.pump();
    expect(find.text('邮箱有效：dev@example.com'), findsOneWidget);

    await tester.tap(find.text('哈希 + AES'));
    await tester.pump();
    expect(find.textContaining('sha256:'), findsOneWidget);
    expect(find.textContaining('decrypted: dev@example.com'), findsOneWidget);
  });

  testWidgets('保存并读取 token', (tester) async {
    await tester.pumpWidget(const CoreExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('保存 token'));
    await tester.pumpAndSettle();
    expect(find.text('已保存 token'), findsOneWidget);

    await tester.tap(find.text('读取 token'));
    await tester.pumpAndSettle();
    expect(find.text('读取 token：demo-token'), findsOneWidget);
  });
}
