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

    testWidgets('empty + shrinkWrap 不崩溃', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              WListView(
                shrinkWrap: true,
                sliver: WListViewSliver.list(
                  itemCount: 0,
                  itemBuilder: (_, i) => Text('item-$i'),
                  empty: const Text('empty'),
                ),
              ),
              const Text('after'),
            ],
          ),
        ),
      );

      expect(find.text('empty'), findsOneWidget);
      expect(find.text('after'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('emptyFill + shrinkWrap 应断言', (tester) async {
      await tester.pumpWidget(
        _host(
          WListView(
            shrinkWrap: true,
            sliver: WListViewSliver.list(
              itemCount: 0,
              itemBuilder: (_, i) => Text('item-$i'),
              empty: const Text('empty'),
              emptyFill: true,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('emptyFill false 可直接放进 shrinkWrap CustomScrollView', (tester) async {
      await tester.pumpWidget(
        _host(
          CustomScrollView(
            shrinkWrap: true,
            slivers: [
              WListViewSliver.list(
                itemCount: 0,
                itemBuilder: (_, i) => Text('item-$i'),
                empty: const Text('empty'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('empty'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('emptyFill + header/footer 时忽略 fill', (tester) async {
      await tester.pumpWidget(
        _host(
          WListView(
            sliver: WListViewSliver.list(
              itemCount: 0,
              itemBuilder: (_, i) => Text('item-$i'),
              header: const Text('header'),
              footer: const Text('footer'),
              empty: const Text('empty'),
              emptyFill: true,
            ),
          ),
        ),
      );

      expect(find.text('header'), findsOneWidget);
      expect(find.text('empty'), findsOneWidget);
      expect(find.text('footer'), findsOneWidget);
      expect(find.byType(SliverFillRemaining), findsNothing);
    });

    testWidgets('emptyFill 时 empty 填满剩余视口', (tester) async {
      await tester.pumpWidget(
        _host(
          WListView(
            sliver: WListViewSliver.list(
              itemCount: 0,
              itemBuilder: (_, i) => Text('item-$i'),
              empty: const Text('empty'),
              emptyFill: true,
            ),
          ),
        ),
      );

      expect(find.byType(SliverFillRemaining), findsOneWidget);
      expect(find.text('empty'), findsOneWidget);
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

    testWidgets('overlap 与 padding / footer 一起工作', (tester) async {
      await tester.pumpWidget(
        _host(
          WListView(
            sliver: WListViewSliver.overlap(
              itemExtent: 100,
              overlap: 20,
              itemCount: 2,
              padding: const EdgeInsets.all(10),
              footer: const Text('footer'),
              itemBuilder: (_, i) => SizedBox(
                height: 100,
                child: Text('item-$i'),
              ),
            ),
          ),
        ),
      );

      expect(tester.getTopLeft(find.text('item-0')).dy, 10);
      expect(
        tester.getTopLeft(find.text('item-1')).dy - tester.getTopLeft(find.text('item-0')).dy,
        80,
      );
      expect(find.text('footer'), findsOneWidget);
    });

    testWidgets('keepAlive 开启后 item 可保持', (tester) async {
      await tester.pumpWidget(
        _host(
          WListView(
            sliver: WListViewSliver.list(
              itemCount: 3,
              keepAlive: true,
              itemBuilder: (_, i) => Text('item-$i'),
            ),
          ),
        ),
      );

      expect(find.byType(AutomaticKeepAlive), findsNWidgets(3));
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

    testWidgets('overlap 不能用于水平列表', (tester) async {
      await tester.pumpWidget(
        _host(
          WListView(
            scrollDirection: Axis.horizontal,
            sliver: WListViewSliver.overlap(
              itemExtent: 100,
              overlap: 20,
              itemCount: 2,
              itemBuilder: (_, i) => SizedBox(
                width: 100,
                child: Text('item-$i'),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('overlap 不能用于 reverse', (tester) async {
      await tester.pumpWidget(
        _host(
          WListView(
            reverse: true,
            sliver: WListViewSliver.overlap(
              itemExtent: 100,
              overlap: 20,
              itemCount: 2,
              itemBuilder: (_, i) => SizedBox(
                height: 100,
                child: Text('item-$i'),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('空 overlap 不产生额外底部 spacer', (tester) async {
      await tester.pumpWidget(
        _host(
          WListView(
            sliver: WListViewSliver.overlap(
              itemExtent: 100,
              overlap: 20,
              itemCount: 0,
              itemBuilder: (_, i) => const SizedBox(),
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsNothing);
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
