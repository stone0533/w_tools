import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async_example/main.dart';

void main() {
  testWidgets('四态页面加载并展示数据', (tester) async {
    await tester.pumpWidget(const AsyncExampleApp());
    expect(find.text('四态视图'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('异步数据 A'), findsOneWidget);
  });

  testWidgets('分页页面可以追加下一页', (tester) async {
    await tester.pumpWidget(const AsyncExampleApp());
    await tester.tap(find.text('分页'));
    await tester.pumpAndSettle();
    expect(find.text('第 1 页 · 1'), findsOneWidget);

    await tester.ensureVisible(find.text('加载更多'));
    await tester.tap(find.text('加载更多'));
    await tester.pumpAndSettle();
    expect(find.text('第 2 页 · 1'), findsOneWidget);
  });

  testWidgets('执行页面可以运行 WAsync.run', (tester) async {
    await tester.pumpWidget(const AsyncExampleApp());
    await tester.tap(find.text('执行').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '执行'));
    await tester.pumpAndSettle();
    expect(find.text('run: 执行成功'), findsOneWidget);
  });

  testWidgets('Sliver 页面展示四态 sliver', (tester) async {
    await tester.pumpWidget(const AsyncExampleApp());
    await tester.tap(find.text('Sliver'));
    await tester.pumpAndSettle();
    expect(find.text('Sliver 数据 1'), findsOneWidget);
  });
}
