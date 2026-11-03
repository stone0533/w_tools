// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  testWidgets('WClipRRect 不传 config 也能渲染', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WClipRRect(child: SizedBox(width: 10, height: 10)),
      ),
    );
    expect(find.byType(WClipRRect), findsOneWidget);
  });

  testWidgets('WBadge 不传 config 时显示 badgeContent', (tester) async {
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

  testWidgets('WTabBar 不传 config 也能渲染 tabs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: const Scaffold(
            body: WTabBar(
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
