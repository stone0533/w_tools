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
    await tester.tap(find.text('item-2'));
    await tester.pumpAndSettle();
    expect(find.text('item-2-selected'), findsOneWidget);
    expect(find.text('item-0'), findsOneWidget);
  });
}
