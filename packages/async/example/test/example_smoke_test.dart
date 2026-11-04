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

  testWidgets('状态构建器页面保持滚动壳并展示数据', (tester) async {
    await tester.pumpWidget(const AsyncExampleApp());
    await tester.tap(find.text('Builder'));
    await tester.pumpAndSettle();
    expect(find.text('Builder 数据 1'), findsOneWidget);
  });

  testWidgets('执行页面可以运行 WAsync.run', (tester) async {
    await tester.pumpWidget(const AsyncExampleApp());
    await tester.tap(find.text('执行 API'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '执行'));
    await tester.pumpAndSettle();
    expect(find.text('run: 执行成功'), findsOneWidget);
  });

  testWidgets('场景页可以提交订单（重试后成功）', (tester) async {
    await tester.pumpWidget(const AsyncExampleApp());
    await tester.tap(find.text('真实场景'));
    await tester.pumpAndSettle();
    expect(find.text('真实场景'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, '提交'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.textContaining('提交成功'), findsOneWidget);
  });

  testWidgets('执行页覆盖 map / serial / first', (tester) async {
    await tester.pumpWidget(const AsyncExampleApp());
    await tester.tap(find.text('执行 API'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'map'));
    await tester.pumpAndSettle();
    expect(find.text('map: answer=42'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'serial'));
    await tester.pumpAndSettle();
    expect(find.text('serial: step 1 -> step 2'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'first'));
    await tester.pumpAndSettle();
    expect(find.text('first: fast'), findsOneWidget);
  });

  testWidgets('Sliver 页面展示四态 sliver', (tester) async {
    await tester.pumpWidget(const AsyncExampleApp());
    await tester.tap(find.text('Sliver'));
    await tester.pumpAndSettle();
    expect(find.text('Sliver 数据 1'), findsOneWidget);
  });
}
