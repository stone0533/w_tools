import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('WListViewSliver — 普通列表', () {
    testWidgets('渲染 items', (tester) async {
      await tester.pumpWidget(
        _host(
          WListView(
            sliver: WListViewSliver.list(
              itemCount: 3,
              itemBuilder: (_, i) => Text('item-$i'),
            ),
          ),
        ),
      );

      expect(find.text('item-0'), findsOneWidget);
      expect(find.text('item-2'), findsOneWidget);
    });

    testWidgets('separated 渲染分隔线', (tester) async {
      await tester.pumpWidget(
        _host(
          WListView(
            sliver: WListViewSliver.separated(
              itemCount: 3,
              itemBuilder: (_, i) => Text('item-$i'),
              separatorBuilder: (_, __) => const Divider(),
            ),
          ),
        ),
      );

      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('grid 渲染网格', (tester) async {
      await tester.pumpWidget(
        _host(
          WListView(
            sliver: WListViewSliver.grid(
              itemCount: 4,
              itemBuilder: (_, i) => Text('item-$i'),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 40,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SliverGrid), findsOneWidget);
      expect(find.text('item-3'), findsOneWidget);
    });

    testWidgets('header / footer 与 empty 同时显示', (tester) async {
      await tester.pumpWidget(
        _host(
          WListView(
            sliver: WListViewSliver.list(
              itemCount: 0,
              itemBuilder: (_, i) => Text('item-$i'),
              header: const Text('header'),
              footer: const Text('footer'),
              empty: const Text('empty'),
            ),
          ),
        ),
      );

      expect(find.text('header'), findsOneWidget);
      expect(find.text('empty'), findsOneWidget);
      expect(find.text('footer'), findsOneWidget);
    });

    testWidgets('empty 无 header/footer 时仍显示', (tester) async {
      await tester.pumpWidget(
        _host(
          WListView(
            sliver: WListViewSliver.list(
              itemCount: 0,
              itemBuilder: (_, i) => Text('item-$i'),
              empty: const Text('empty'),
            ),
          ),
        ),
      );

      expect(find.text('empty'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('overlap 按 itemExtent - overlap 布局', (tester) async {
      await tester.pumpWidget(
        _host(
          WListView(
            sliver: WListViewSliver.overlap(
              itemExtent: 100,
              overlap: 20,
              itemCount: 3,
              itemBuilder: (_, i) => SizedBox(
                height: 100,
                child: Text('item-$i'),
              ),
            ),
          ),
        ),
      );

      final first = tester.getTopLeft(find.text('item-0')).dy;
      final second = tester.getTopLeft(find.text('item-1')).dy;
      final third = tester.getTopLeft(find.text('item-2')).dy;

      expect(second - first, 80);
      expect(third - second, 80);
    });

    testWidgets('独立 WListView 可滚动', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          SizedBox(
            height: 300,
            child: WListView(
              controller: controller,
              sliver: WListViewSliver.list(
                itemCount: 20,
                itemExtent: 100,
                itemBuilder: (_, i) => Text('item-$i'),
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.byType(WListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(controller.offset, greaterThan(0));
    });

    testWidgets('WListViewSliver 可直接放进 CustomScrollView', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          SizedBox(
            height: 300,
            child: CustomScrollView(
              controller: controller,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                WListViewSliver.list(
                  itemCount: 20,
                  itemExtent: 100,
                  itemBuilder: (_, i) => Text('item-$i'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(controller.offset, greaterThan(0));
    });
  });

  group('WListViewSliver — 校验', () {
    test('overlap 不能大于等于 itemExtent', () {
      expect(
        () => WListViewSliver.overlap(
          itemExtent: 100,
          overlap: 100,
          itemCount: 1,
          itemBuilder: (_, __) => const SizedBox(),
        ),
        throwsAssertionError,
      );
    });

    test('itemExtent 必须大于 0', () {
      expect(
        () => WListViewSliver.list(
          itemExtent: 0,
          itemCount: 1,
          itemBuilder: (_, __) => const SizedBox(),
        ),
        throwsAssertionError,
      );
    });

    test('itemCount 不能为负', () {
      expect(
        () => WListViewSliver.list(
          itemCount: -1,
          itemBuilder: (_, __) => const SizedBox(),
        ),
        throwsAssertionError,
      );
    });
  });
}
