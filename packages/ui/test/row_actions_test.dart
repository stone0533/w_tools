import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('WActionRow 渲染子项并透传点击', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      _host(
        WActionRow(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            TextButton(onPressed: () => taps++, child: const Text('A')),
            TextButton(onPressed: () => taps++, child: const Text('B')),
          ],
        ),
      ),
    );

    expect(find.text('A'), findsOneWidget);
    await tester.tap(find.text('B'));
    expect(taps, 1);
  });

  testWidgets('WActionRow 不同高度子项垂直居中', (tester) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 200,
          child: WActionRow(
            children: [
              SizedBox(key: Key('short'), width: 40, height: 20),
              SizedBox(key: Key('tall'), width: 40, height: 40),
            ],
          ),
        ),
      ),
    );

    final short = tester.getRect(find.byKey(const Key('short')));
    final tall = tester.getRect(find.byKey(const Key('tall')));
    expect(short.center.dy, closeTo(tall.center.dy, 0.5));
  });

  testWidgets('WActionRow 不传 controller 时 onScroll 仍回调', (tester) async {
    final offsets = <double>[];

    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 200,
          child: WActionRow(
            spacing: 8,
            onScroll: offsets.add,
            children: List.generate(
              20,
              (index) => SizedBox(width: 80, child: Text('item-$index')),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(WActionRow), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(offsets, isNotEmpty);
    expect(offsets.last, greaterThan(0));
  });

  testWidgets('WSelectableRow 点击回调与选中态', (tester) async {
    var selected = 0;
    late StateSetter setState;

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setter) {
            setState = setter;
            return WSelectableRow(
              itemCount: 3,
              selectedIndex: selected,
              onSelected: (index) => setState(() => selected = index),
              builder: (context, index, isSelected) => Text(
                'item-$index${isSelected ? '-selected' : ''}',
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('item-0-selected'), findsOneWidget);
    expect(find.byType(WPressable), findsNWidgets(3));
    await tester.tap(find.text('item-2'));
    await tester.pumpAndSettle();
    expect(find.text('item-2-selected'), findsOneWidget);
    expect(find.text('item-0'), findsOneWidget);
  });
  testWidgets('WSelectableRow 初始选中项自动滚入视口', (tester) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 200,
          height: 40,
          child: WSelectableRow(
            itemCount: 20,
            selectedIndex: 15,
            onSelected: (_) {},
            builder: (context, index, isSelected) => SizedBox(
              width: 80,
              child: Text('item-$index'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rect = tester.getRect(find.text('item-15'));
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(200));
  });

  testWidgets('WSelectableRow scrollToSelected: false 不主动滚动', (tester) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 200,
          height: 40,
          child: WSelectableRow(
            itemCount: 20,
            selectedIndex: 15,
            scrollToSelected: false,
            onSelected: (_) {},
            builder: (context, index, isSelected) => SizedBox(
              width: 80,
              child: Text('item-$index'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getRect(find.text('item-15')).left, greaterThan(200));
  });

  testWidgets('WSelectableRow itemCount 变化后选中项仍可渲染', (tester) async {
    Widget build(int count, int selected) => _host(
      SizedBox(
        width: 200,
        height: 40,
        child: WSelectableRow(
          itemCount: count,
          selectedIndex: selected,
          onSelected: (_) {},
          builder: (context, index, isSelected) => SizedBox(width: 80, child: Text('item-$index')),
        ),
      ),
    );

    await tester.pumpWidget(build(3, 2));
    await tester.pumpAndSettle();
    await tester.pumpWidget(build(6, 5));
    await tester.pumpAndSettle();

    expect(find.text('item-5'), findsOneWidget);
  });
}
