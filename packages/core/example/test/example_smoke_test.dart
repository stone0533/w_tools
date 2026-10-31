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

  testWidgets('正则与 Base64', (tester) async {
    await tester.pumpWidget(const CoreExampleApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'dev@example.com');
    await tester.ensureVisible(find.text('正则匹配'));
    await tester.tap(find.text('正则匹配'));
    await tester.pumpAndSettle();
    expect(find.text('regex: dev@example.com'), findsOneWidget);

    await tester.ensureVisible(find.text('Base64 往返'));
    await tester.tap(find.text('Base64 往返'));
    await tester.pumpAndSettle();
    expect(find.textContaining('decoded: dev@example.com'), findsOneWidget);
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
  testWidgets('计数持久化与倒计时', (tester) async {
    await tester.pumpWidget(const CoreExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('计数 +1'));
    await tester.pumpAndSettle();
    expect(find.text('已保存计数：1'), findsOneWidget);

    await tester.tap(find.text('读取计数'));
    await tester.pumpAndSettle();
    expect(find.text('读取计数：1'), findsOneWidget);

    await tester.ensureVisible(find.text('开始 5 秒倒计时'));
    await tester.tap(find.text('开始 5 秒倒计时'));
    await tester.pump();
    expect(find.text('剩余：5 秒'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('剩余：4 秒'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('剩余：0 秒'), findsOneWidget);
  });
}
