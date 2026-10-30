import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  group('WTabBarConfig — 纯 Dart', () {
    test('默认构造', () {
      expect(WTabBarConfig(), isNotNull);
    });

    test('全部 setter + 链式方法', () {
      final cfg = WTabBarConfig();
      cfg.labelStyle = const TextStyle(fontSize: 16);
      cfg.unselectedLabelStyle = const TextStyle(fontSize: 14);
      cfg.dividerColor = Colors.grey;
      cfg.dividerHeight = 1.0;
      cfg.padding = const EdgeInsets.all(8);
      cfg.isScrollable = true;
      cfg.indicatorSize = TabBarIndicatorSize.label;
      cfg.indicatorColor = Colors.blue;
      cfg.indicatorWeight = 3.0;
      cfg.tabAlignment = TabAlignment.center;

      // 链式方法
      cfg.divider(2, Colors.red).indicatorWithHeightAndColor(4, Colors.green);
      expect(cfg, isNotNull);
    });

    test('build 返回 WTabBar', () {
      final cfg = WTabBarConfig();
      final tab = cfg.build(tabs: const [Text('A'), Text('B')]);
      expect(tab, isA<WTabBar>());
    });
  });

  group('WTabBarConfig — copy', () {
    test('copy / copyWith 返回新实例', () {
      final cfg = WTabBarConfig()
        ..labelStyle = const TextStyle(fontSize: 14)
        ..isScrollable = true
        ..indicatorWeight = 3;

      final copy = cfg.copy();
      expect(copy, isA<WTabBarConfig>());
      expect(identical(cfg, copy), false);

      final updated = copy.copyWith(indicatorWeight: 5);
      expect(updated, isA<WTabBarConfig>());
    });
  });

  group('WTabBar + TabBarView — Widget', () {
    Widget buildTabBar({int tabCount = 3, void Function(int)? onTap}) {
      return MaterialApp(
        home: DefaultTabController(
          length: tabCount,
          child: Scaffold(
            body: Column(
              children: [
                WTabBar(
                  config: WTabBarConfig(),
                  tabs: List.generate(tabCount, (i) => Text('Tab $i')),
                  onTap: onTap,
                ),
                Expanded(
                  child: TabBarView(
                    children: List.generate(tabCount, (i) => Text('Content $i')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('基本渲染 — tab 标签显示', (tester) async {
      await tester.pumpWidget(buildTabBar(tabCount: 3));
      expect(find.text('Tab 0'), findsOneWidget);
      expect(find.text('Tab 1'), findsOneWidget);
      expect(find.text('Tab 2'), findsOneWidget);
    });

    testWidgets('TabBarView 切换 — 默认 tab 0', (tester) async {
      await tester.pumpWidget(buildTabBar(tabCount: 3));
      expect(find.text('Content 0'), findsOneWidget);
      expect(find.text('Content 1'), findsNothing);
    });

    testWidgets('点击 Tab 1 → 切换 Content 1', (tester) async {
      await tester.pumpWidget(buildTabBar(tabCount: 3));
      await tester.tap(find.text('Tab 1'));
      await tester.pumpAndSettle();
      expect(find.text('Content 1'), findsOneWidget);
      expect(find.text('Content 0'), findsNothing);
    });

    testWidgets('onTap 回调', (tester) async {
      int? tapped;
      await tester.pumpWidget(
        buildTabBar(
          tabCount: 3,
          onTap: (i) => tapped = i,
        ),
      );
      await tester.tap(find.text('Tab 2'));
      await tester.pumpAndSettle();
      expect(tapped, 2);
    });

    testWidgets('自定义 config.indicatorColor / indicatorWeight', (tester) async {
      final cfg = WTabBarConfig();
      cfg.indicatorColor = Colors.orange;
      cfg.indicatorWeight = 4;
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              body: Column(
                children: [
                  WTabBar(
                    config: cfg,
                    tabs: const [Text('A'), Text('B')],
                  ),
                  const Expanded(
                    child: TabBarView(children: [Text('a'), Text('b')]),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.byType(TabBar), findsOneWidget);
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.indicatorWeight, 4);
    });
  });
}
