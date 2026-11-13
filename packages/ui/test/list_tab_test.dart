// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  group('WTabBarStyle — 纯 Dart', () {
    test('默认构造', () {
      expect(const WTabBarStyle(), isNotNull);
    });

    test('构造字段与 copyWith', () {
      const style = WTabBarStyle(
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
        splashFactory: NoSplash.splashFactory,
      );
      expect(style.isScrollable, isTrue);
      expect(style.indicatorWeight, 3.0);
      expect(style.dividerHeight, 1.0);
      expect(style.splashFactory, NoSplash.splashFactory);

      final updated = style.copyWith(dividerHeight: 2.0, dividerColor: Colors.red);
      expect(updated.dividerHeight, 2.0);
      expect(updated.dividerColor, Colors.red);
      expect(updated.labelStyle, style.labelStyle);
      expect(updated.splashFactory, NoSplash.splashFactory);
    });

    test('值相等', () {
      const a = WTabBarStyle(isScrollable: true);
      const b = WTabBarStyle(isScrollable: true);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
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
                  style: const WTabBarStyle(),
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

    testWidgets('自定义 style.indicatorColor / indicatorWeight', (tester) async {
      const cfg = WTabBarStyle(
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
                    style: cfg,
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

    testWidgets('WTabBar 透传 labelColor / labelPadding / textScaler', (tester) async {
      const cfg = WTabBarStyle(
        labelColor: Colors.red,
        unselectedLabelColor: Colors.blueGrey,
        labelPadding: EdgeInsets.symmetric(horizontal: 6),
        indicatorPadding: EdgeInsets.symmetric(horizontal: 2),
        textScaler: TextScaler.linear(1.2),
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              body: WTabBar(
                style: cfg,
                tabs: [Text('A'), Text('B')],
              ),
            ),
          ),
        ),
      );
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.labelColor, Colors.red);
      expect(tabBar.unselectedLabelColor, Colors.blueGrey);
      expect(tabBar.labelPadding, const EdgeInsets.symmetric(horizontal: 6));
      expect(tabBar.indicatorPadding, const EdgeInsets.symmetric(horizontal: 2));
      expect(tabBar.textScaler, const TextScaler.linear(1.2));
    });
  });

  testWidgets('WTabBar overlayColor 可配置', (tester) async {
    const cfg = WTabBarStyle(overlayColor: Colors.red);
    await tester.pumpWidget(
      const MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: Scaffold(
            body: WTabBar(
              style: cfg,
              tabs: [Text('A'), Text('B')],
            ),
          ),
        ),
      ),
    );
    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.overlayColor?.resolve({}), Colors.red);
  });
  testWidgets('WTabBar noSplash 预设同时关 overlay 与水波纹', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: WTabBar(
            style: WTabBarStyle.noSplash,
            tabs: [Text('A'), Text('B')],
          ),
        ),
      ),
    );
    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.overlayColor?.resolve({}), Colors.transparent);
    expect(tabBar.splashFactory, NoSplash.splashFactory);
  });

  testWidgets('WTabBar 默认不强制透明 overlay，交给 TabBarTheme', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DefaultTabController(
          length: 1,
          child: WTabBar(tabs: [Text('A')]),
        ),
      ),
    );
    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.overlayColor, isNull);
  });
  testWidgets('WTabBar 直接传 style', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: WTabBar(
            style: WTabBarStyle(
              labelStyle: TextStyle(fontSize: 20),
              isScrollable: true,
            ),
            tabs: [Text('A'), Text('B')],
          ),
        ),
      ),
    );
    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.labelStyle, const TextStyle(fontSize: 20));
    expect(tabBar.isScrollable, isTrue);
  });
}
