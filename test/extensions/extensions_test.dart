import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools/src/extensions/extensions.dart';

void main() {
  group('Color Extensions', () {
    test('HexColor.fromHex - 6位颜色', () {
      final color = HexColor.fromHex('#FF5733');
      // ignore: deprecated_member_use
      final value = color.value;
      expect((value >> 24) & 0xFF, 255); // alpha
      expect((value >> 16) & 0xFF, 255); // red
      expect((value >> 8) & 0xFF, 87);  // green
      expect(value & 0xFF, 51);         // blue
    });

    test('HexColor.fromHex - 8位颜色（带透明度）', () {
      final color = HexColor.fromHex('#80FF5733');
      // ignore: deprecated_member_use
      final value = color.value;
      expect((value >> 24) & 0xFF, 128); // alpha
      expect((value >> 16) & 0xFF, 255); // red
      expect((value >> 8) & 0xFF, 87);  // green
      expect(value & 0xFF, 51);         // blue
    });

    test('HexColor.fromHex - 3位简写', () {
      final color = HexColor.fromHex('#F00');
      // ignore: deprecated_member_use
      final value = color.value;
      expect((value >> 16) & 0xFF, 255); // red
      expect((value >> 8) & 0xFF, 0);   // green
      expect(value & 0xFF, 0);          // blue
    });

    test('HexColor.fromHex - 4位简写（带透明度）', () {
      final color = HexColor.fromHex('#8F00');
      // ignore: deprecated_member_use
      final value = color.value;
      expect((value >> 24) & 0xFF, 136); // alpha ('8' * 17 = 136)
      expect((value >> 16) & 0xFF, 255); // red
      expect((value >> 8) & 0xFF, 0);   // green
      expect(value & 0xFF, 0);          // blue
    });

    test('HexColor.fromHex - 不带#前缀', () {
      final color = HexColor.fromHex('FF5733');
      // ignore: deprecated_member_use
      final value = color.value;
      expect((value >> 16) & 0xFF, 255); // red
      expect((value >> 8) & 0xFF, 87);  // green
      expect(value & 0xFF, 51);         // blue
    });

    test('HexColor.fromHex - 无效格式抛出异常', () {
      expect(() => HexColor.fromHex(''), throwsFormatException);
      expect(() => HexColor.fromHex('#FFF'), returnsNormally); // 有效的3位
      expect(() => HexColor.fromHex('#FFFF'), returnsNormally); // 有效的4位
      expect(() => HexColor.fromHex('#FFFFF'), throwsFormatException); // 无效的5位
    });

    test('Color.toHex', () {
      const color = Color(0xFFFF5733);
      expect(color.toHex(), '#ffff5733');
      expect(color.toHex(leadingHashSign: false), 'ffff5733');
    });
  });

  group('String Extensions', () {
    test('String.toInt', () {
      expect('123'.toInt(), 123);
      expect('abc'.toInt(), isNull);
      expect(''.toInt(), isNull);
      expect('  456  '.toInt(), 456);
    });

    test('String.toDouble', () {
      expect('123.45'.toDouble(), 123.45);
      expect('abc'.toDouble(), isNull);
      expect(''.toDouble(), isNull);
      expect('1.23e4'.toDouble(), 12300.0);
    });

    test('String.trimAll', () {
      expect('  hello  world  '.trimAll(), 'helloworld');
      expect('hello\nworld'.trimAll(), 'helloworld');
      expect(''.trimAll(), '');
      expect('  \n\t  '.trimAll(), '');
    });

    test('String.toColor', () {
      final color = '#FF5733'.toColor();
      // ignore: deprecated_member_use
      final value = color.value;
      expect((value >> 16) & 0xFF, 255); // red
      expect((value >> 8) & 0xFF, 87);  // green
      expect(value & 0xFF, 51);         // blue
    });

    test('String.toColor - 带透明度', () {
      final color = '#80FF5733'.toColor();
      // ignore: deprecated_member_use
      final value = color.value;
      expect((value >> 24) & 0xFF, 128); // alpha
      expect((value >> 16) & 0xFF, 255); // red
      expect((value >> 8) & 0xFF, 87);   // green
      expect(value & 0xFF, 51);          // blue
    });
  });

  group('Num Extensions', () {
    test('num.heightBox', () {
      final box = 10.heightBox;
      expect(box.height, 10);
    });

    test('num.widthBox', () {
      final box = 10.widthBox;
      expect(box.width, 10);
    });

    test('num.squareBox', () {
      final box = 10.squareBox;
      expect(box.width, 10);
      expect(box.height, 10);
    });

    test('num.allPadding', () {
      final padding = 10.allPadding;
      expect(padding, const EdgeInsets.all(10));
    });

    test('num.horizontalPadding', () {
      final padding = 10.horizontalPadding;
      expect(padding, const EdgeInsets.symmetric(horizontal: 10));
    });

    test('num.verticalPadding', () {
      final padding = 10.verticalPadding;
      expect(padding, const EdgeInsets.symmetric(vertical: 10));
    });

    test('num.borderRadius', () {
      final radius = 10.borderRadius;
      expect(radius, BorderRadius.circular(10));
    });

    test('num.toThousand', () {
      expect(1234.toThousand, '1,234');
      expect(1234567.toThousand, '1,234,567');
      expect(1234.56.toThousand, '1,234.56');
      expect(0.toThousand, '0');
      expect((-1234).toThousand, '-1,234');
    });

    test('num.toCurrency', () {
      expect(1234.toCurrency(symbol: '¥'), '¥1,234');
      expect(1234.56.toCurrency(symbol: '\$'), '\$1,234.56');
      expect(0.toCurrency(symbol: '¥'), '¥0');
      expect((-1234.56).toCurrency(symbol: '\$'), '\$-1,234.56');
    });

    test('num.toPercent', () {
      expect(0.5.toPercent, '50.0%');
      expect(1.25.toPercentWithFixed(1), '125.0%');
      expect(0.0.toPercent, '0.0%');
      expect(2.0.toPercent, '200.0%');
    });

    test('num.toPadLeft', () {
      expect(1.toPadLeft(2), '01');
      expect(123.toPadLeft(2), '123');
      expect(5.toPadLeft(4), '0005');
      expect(0.toPadLeft(3), '000');
      expect((-1).toPadLeft(3), '0-1');
    });
  });

  group('Map Extensions', () {
    test('Map.sortedByKeys - 默认排序', () {
      final map = {'b': 2, 'a': 1, 'c': 3};
      final sorted = map.sortedByKeys();
      expect(sorted.keys.toList(), ['a', 'b', 'c']);
    });

    test('Map.sortedByKeys - 自定义排序', () {
      final map = {'b': 2, 'a': 1, 'c': 3};
      final sorted = map.sortedByKeys((a, b) => b.compareTo(a));
      expect(sorted.keys.toList(), ['c', 'b', 'a']);
    });

    test('Map.sortedByKeys - 空Map', () {
      final map = <String, int>{};
      final sorted = map.sortedByKeys();
      expect(sorted.isEmpty, isTrue);
    });

    test('Map.merge - 默认覆盖', () {
      final map1 = {'a': 1, 'b': 2};
      final map2 = {'b': 3, 'c': 4};
      map1.merge(map2);
      expect(map1, {'a': 1, 'b': 3, 'c': 4});
    });

    test('Map.merge - 不覆盖', () {
      final map1 = {'a': 1, 'b': 2};
      final map2 = {'b': 3, 'c': 4};
      map1.merge(map2, overwrite: false);
      expect(map1, {'a': 1, 'b': 2, 'c': 4});
    });

    test('Map.merge - 空Map合并', () {
      final map1 = {'a': 1};
      final map2 = <String, int>{};
      map1.merge(map2);
      expect(map1, {'a': 1});

      final map3 = <String, int>{};
      final map4 = {'b': 2};
      map3.merge(map4);
      expect(map3, {'b': 2});
    });
  });

  group('Widget Extensions', () {
    testWidgets('Widget.expanded', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Container().expanded(2),
                Container().expanded(1),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(Expanded), findsNWidgets(2));
    });

    testWidgets('Widget.withHorizontalPadding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container().withHorizontalPadding(16),
          ),
        ),
      );
      expect(find.byType(Padding), findsOneWidget);
    });

    testWidgets('Widget.withVerticalPadding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container().withVerticalPadding(16),
          ),
        ),
      );
      expect(find.byType(Padding), findsOneWidget);
    });

    testWidgets('Widget.toButton', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Click').toButton(onTap: () => tapped = true),
          ),
        ),
      );
      await tester.tap(find.text('Click'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('WRow / WColumn', () {
    testWidgets('WRow.min', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WRow.min(
              children: [const Text('A'), const Text('B')],
            ),
          ),
        ),
      );
      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisSize, MainAxisSize.min);
    });

    testWidgets('WColumn.min', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WColumn.min(
              children: [const Text('A'), const Text('B')],
            ),
          ),
        ),
      );
      final column = tester.widget<Column>(find.byType(Column));
      expect(column.mainAxisSize, MainAxisSize.min);
    });
  });

  group('WPadding', () {
    testWidgets('WPadding.horizontal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WPadding.horizontal(10, child: const Text('Test')),
          ),
        ),
      );
      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, const EdgeInsets.symmetric(horizontal: 10));
    });

    testWidgets('WPadding.vertical', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WPadding.vertical(10, child: const Text('Test')),
          ),
        ),
      );
      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, const EdgeInsets.symmetric(vertical: 10));
    });
  });

  group('WSizeBox', () {
    test('WSizeBox.height', () {
      final box = WSizeBox.height(10);
      expect(box.height, 10);
    });

    test('WSizeBox.width', () {
      final box = WSizeBox.width(20);
      expect(box.width, 20);
    });

    test('WSizeBox.size', () {
      final box = WSizeBox.size(10, 20, null);
      expect(box.width, 10);
      expect(box.height, 20);
    });

    test('便捷常量', () {
      expect(h(10).height, 10);
      expect(w(20).width, 20);
      expect(s(10, 20, null).width, 10);
    });
  });
}
