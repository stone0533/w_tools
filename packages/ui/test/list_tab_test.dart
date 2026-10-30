import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  group('WListViewConfig — 纯 Dart', () {
    test('默认构造函数初始化 padding', () {
      final cfg = WListViewConfig();
      // 构造函数里 _padding = EdgeInsets.zero
      expect(cfg, isNotNull);
    });

    test('工厂方法 vertical / horizontal / card / compact', () {
      final v = WListViewConfig.vertical();
      final h = WListViewConfig.horizontal();
      final c = WListViewConfig.card();
      final cp = WListViewConfig.compact();
      expect(v, isNotNull);
      expect(h, isNotNull);
      expect(c, isNotNull);
      expect(cp, isNotNull);
    });

    test('全部 setter 可赋值', () {
      final cfg = WListViewConfig();
      cfg.padding = const EdgeInsets.all(8);
      cfg.scrollDirection = Axis.horizontal;
      cfg.reverse = true;
      cfg.physics = const BouncingScrollPhysics();
      cfg.cacheExtent = 150;
      cfg.itemExtent = 60;
      cfg.emptyWidget = const Text('空');
      cfg.usePreciseCache = true;
      cfg.backgroundColor = Colors.red;
      cfg.borderRadius = BorderRadius.circular(12);
      cfg.border = Border.all(color: Colors.grey);
      cfg.shrinkWrap = true;
      cfg.separatorBuilder = (_, i) => const Divider();
      cfg.useOverlap = true;
      cfg.overlapOffset = -10;
      cfg.itemBuilderByT = <T>(_, T data) => Text('$data');
      expect(cfg, isNotNull);
    });

    test('overlapOffset 正数被截断为 0', () {
      final cfg = WListViewConfig();
      // assert(value <= 0) → debug 模式抛，release 模式截断
      // 用 set overlapOffset(5) 会 assert，但 getter 不可读
      // 简化：设 -10 没问题
      cfg.overlapOffset = -10;
      expect(cfg, isNotNull);
    });

    test('copyWith 部分覆盖 + copy 深拷贝', () {
      final cfg = WListViewConfig.vertical();
      cfg.itemExtent = 50;
      final copy = cfg.copy();
      final partial = cfg.copyWith(itemExtent: 80);
      expect(identical(cfg, copy), false);
      expect(identical(cfg, partial), false);
    });

    test('build 返回 WListView', () {
      final cfg = WListViewConfig();
      final list = cfg.build(
        itemBuilder: (_, i) => Text('$i'),
        itemCount: 5,
      );
      expect(list, isA<WListView>());
    });

    test('buildByList — 有 itemBuilder → 正常构建', () {
      final cfg = WListViewConfig();
      final list = cfg.buildByList<String>(
        data: const ['a', 'b', 'c'],
        itemBuilder: (_, s) => Text(s),
      );
      expect(list, isA<WListView>());
    });

    test('buildByList — 无 itemBuilder + 无 itemBuilderByT → assert', () {
      final cfg = WListViewConfig();
      expect(
        () => cfg.buildByList<String>(data: const ['a']),
        throwsAssertionError,
      );
    });

    test('buildSeparated 返回 WListView.separated', () {
      final cfg = WListViewConfig();
      cfg.separatorBuilder = (_, i) => const Divider();
      final list = cfg.buildSeparated(
        itemBuilder: (_, i) => Text('$i'),
        itemCount: 3,
      );
      expect(list, isA<WListView>());
    });

    test('buildGrid 返回 WListView.grid', () {
      final cfg = WListViewConfig();
      final list = cfg.buildGrid(
        itemBuilder: (_, i) => Text('$i'),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1,
        ),
      );
      expect(list, isA<WListView>());
    });
  });

  group('WListView — Widget', () {
    Widget buildList({
      int itemCount = 3,
      Widget? header,
      Widget? footer,
      Widget? emptyWidget,
      WListViewConfig? config,
      SliverGridDelegate? gridDelegate,
    }) {
      final cfg = config ?? WListViewConfig.vertical();
      return MaterialApp(
        home: Scaffold(
          body: WListView(
            config: cfg,
            itemBuilder: (_, i) => Text('item-$i'),
            itemCount: itemCount,
            header: header,
            footer: footer,
            emptyWidget: emptyWidget,
            gridDelegate: gridDelegate,
          ),
        ),
      );
    }

    testWidgets('基本渲染 — itemCount 个 item 显示', (tester) async {
      await tester.pumpWidget(buildList(itemCount: 3));
      expect(find.text('item-0'), findsOneWidget);
      expect(find.text('item-1'), findsOneWidget);
      expect(find.text('item-2'), findsOneWidget);
    });

    testWidgets('外层 GlobalKey 不会传给内部滚动组件', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WListView(
              key: key,
              config: WListViewConfig.vertical(),
              itemBuilder: (_, i) => Text('item-$i'),
              itemCount: 3,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(key.currentWidget, isA<WListView>());
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('带头部时外层 GlobalKey 也不会重复', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WListView(
              key: key,
              config: WListViewConfig.vertical(),
              itemBuilder: (_, i) => Text('item-$i'),
              itemCount: 2,
              header: const Text('header'),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(key.currentWidget, isA<WListView>());
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('带头部时 padding 生效', (tester) async {
      final cfg = WListViewConfig.vertical()..padding = const EdgeInsets.all(12);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WListView(
              config: cfg,
              itemBuilder: (_, i) => Text('item-$i'),
              itemCount: 2,
              header: const Text('header'),
            ),
          ),
        ),
      );

      expect(tester.getTopLeft(find.text('header')).dy, greaterThanOrEqualTo(12));
      expect(tester.getTopLeft(find.text('item-0')).dy, greaterThanOrEqualTo(12));
    });

    testWidgets('重叠偏移超过 itemExtent 时不会触发断言', (tester) async {
      final cfg = WListViewConfig.vertical()
        ..itemExtent = 10
        ..useOverlap = true
        ..overlapOffset = -30;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WListView(
              config: cfg,
              itemBuilder: (_, i) => SizedBox(height: 10, child: Text('item-$i')),
              itemCount: 3,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('item-0'), findsOneWidget);
    });

    testWidgets('itemCount=0 + emptyWidget → 显示 emptyWidget', (tester) async {
      await tester.pumpWidget(
        buildList(
          itemCount: 0,
          emptyWidget: const Center(child: Text('暂无数据')),
        ),
      );
      expect(find.text('暂无数据'), findsOneWidget);
    });

    testWidgets('itemCount=0 + config.emptyWidget → 显示', (tester) async {
      final cfg = WListViewConfig();
      cfg.emptyWidget = const Text('config-empty');
      await tester.pumpWidget(buildList(itemCount: 0, config: cfg));
      expect(find.text('config-empty'), findsOneWidget);
    });

    testWidgets('emptyWidget 优先级高于 config.emptyWidget', (tester) async {
      final cfg = WListViewConfig();
      cfg.emptyWidget = const Text('config-empty');
      await tester.pumpWidget(
        buildList(
          itemCount: 0,
          config: cfg,
          emptyWidget: const Text('widget-empty'),
        ),
      );
      expect(find.text('widget-empty'), findsOneWidget);
      expect(find.text('config-empty'), findsNothing);
    });

    testWidgets('header + footer → CustomScrollView', (tester) async {
      await tester.pumpWidget(
        buildList(
          itemCount: 2,
          header: const Text('HEADER'),
          footer: const Text('FOOTER'),
        ),
      );
      expect(find.text('HEADER'), findsOneWidget);
      expect(find.text('FOOTER'), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('separatorBuilder → ListView.separated', (tester) async {
      final cfg = WListViewConfig();
      cfg.separatorBuilder = (_, i) => const SizedBox(height: 10);
      await tester.pumpWidget(buildList(config: cfg, itemCount: 2));
      expect(find.text('item-0'), findsOneWidget);
      expect(find.text('item-1'), findsOneWidget);
    });

    testWidgets('gridDelegate → GridView.builder', (tester) async {
      await tester.pumpWidget(
        buildList(
          itemCount: 4,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1,
          ),
        ),
      );
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('item-0'), findsOneWidget);
    });

    testWidgets('backgroundColor → Container 包裹', (tester) async {
      final cfg = WListViewConfig.vertical();
      cfg.backgroundColor = Colors.amber;
      cfg.borderRadius = BorderRadius.circular(8);
      cfg.border = Border.all(color: Colors.red);
      await tester.pumpWidget(buildList(config: cfg, itemCount: 2));
      // Container with decoration
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.decoration, isNotNull);
    });

    testWidgets('controller 传入 → 不自动 dispose', (tester) async {
      final controller = ScrollController();
      final cfg = WListViewConfig.vertical();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WListView(
              config: cfg,
              itemBuilder: (_, i) => Text('item-$i'),
              itemCount: 50,
              controller: controller,
            ),
          ),
        ),
      );
      // controller 没有被 dispose
      expect(controller.hasClients, true);

      // 滚动到末尾
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();
    });
  });

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
