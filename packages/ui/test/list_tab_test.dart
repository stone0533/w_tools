import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  group('WTabBarConfig — 纯 Dart', () {
    test('默认构造', () {
      expect(const WTabBarConfig(), isNotNull);
    });

    test('构造字段与 copyWith', () {
      const cfg = WTabBarConfig(
        labelStyle: TextStyle(fontSize: 16),
        unselectedLabelStyle: TextStyle(fontSize: 14),
        dividerColor: Colors.grey,
        dividerHeight: 1.0,
        padding: EdgeInsets.all(8),
        isScrollable: true,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorColor: Colors.blue,
        indicatorWeight: 3.0,
        tabAlignment: TabAlignment.center,
      );
      expect(cfg.isScrollable, isTrue);
      expect(cfg.indicatorWeight, 3.0);
      expect(cfg.dividerHeight, 1.0);

      final updated = cfg.copyWith(dividerHeight: 2.0, dividerColor: Colors.red);
      expect(updated.dividerHeight, 2.0);
      expect(updated.dividerColor, Colors.red);
      expect(updated.labelStyle, cfg.labelStyle);
    });

    test('build 返回 WTabBar', () {
      const cfg = WTabBarConfig();
      final tab = cfg.build(tabs: const [Text('A'), Text('B')]);
      expect(tab, isA<WTabBar>());
    });
  });

  group('WTabBarConfig — copy', () {
    test('copy / copyWith 返回新实例', () {
      const cfg = WTabBarConfig(
        labelStyle: TextStyle(fontSize: 14),
        isScrollable: true,
        indicatorWeight: 3,
      );

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
                  config: const WTabBarConfig(),
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
      const cfg = WTabBarConfig(
        indicatorColor: Colors.orange,
        indicatorWeight: 4,
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              body: Column(
                children: [
                  WTabBar(
                    config: cfg,
                    tabs: [Text('A'), Text('B')],
                  ),
                  Expanded(
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

  testWidgets('WTabBar overlayColor 可配置', (tester) async {
    const cfg = WTabBarConfig(overlayColor: Colors.red);
    await tester.pumpWidget(
      const MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: Scaffold(
            body: WTabBar(
              config: cfg,
              tabs: [Text('A'), Text('B')],
            ),
          ),
        ),
      ),
    );
    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.overlayColor?.resolve({}), Colors.red);
  });
}
