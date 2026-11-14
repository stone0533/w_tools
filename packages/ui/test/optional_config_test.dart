// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  testWidgets('WBadge 只传 badgeContent 时显示', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WBadge(
          badgeContent: const Text('1'),
          child: const Icon(Icons.mail),
        ),
      ),
    );
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('TabBar 渲染 tabs（WTabBar 已在 12.0 删除）', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: const Scaffold(
            body: TabBar(
              tabs: [
                Tab(text: 'A'),
                Tab(text: 'B'),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('A'), findsOneWidget);
  });
}
