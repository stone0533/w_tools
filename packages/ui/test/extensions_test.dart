import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  group('Color Extensions', () {
    test('HexColor.fromHex - 6位颜色', () {
      final color = HexColor.fromHex('#FF5733');
      final value = color.toARGB32();
      expect((value >> 24) & 0xFF, 255); // alpha
      expect((value >> 16) & 0xFF, 255); // red
      expect((value >> 8) & 0xFF, 87); // green
      expect(value & 0xFF, 51); // blue
    });

    test('HexColor.fromHex - 8位颜色（带透明度）', () {
      final color = HexColor.fromHex('#80FF5733');
      final value = color.toARGB32();
      expect((value >> 24) & 0xFF, 128); // alpha
      expect((value >> 16) & 0xFF, 255); // red
      expect((value >> 8) & 0xFF, 87); // green
      expect(value & 0xFF, 51); // blue
    });

    test('HexColor.fromHex - 3位简写', () {
      final color = HexColor.fromHex('#F00');
      final value = color.toARGB32();
      expect((value >> 16) & 0xFF, 255); // red
      expect((value >> 8) & 0xFF, 0); // green
      expect(value & 0xFF, 0); // blue
    });

    test('HexColor.fromHex - 4位简写（带透明度）', () {
      final color = HexColor.fromHex('#8F00');
      final value = color.toARGB32();
      expect((value >> 24) & 0xFF, 136); // alpha ('8' * 17 = 136)
      expect((value >> 16) & 0xFF, 255); // red
      expect((value >> 8) & 0xFF, 0); // green
      expect(value & 0xFF, 0); // blue
    });

    test('HexColor.fromHex - 前后空格', () {
      final color = HexColor.fromHex(' #FF5733 ');
      expect(color.toARGB32(), const Color(0xFFFF5733).toARGB32());
    });

    test('HexColor.fromHex - 不带#前缀', () {
      final color = HexColor.fromHex('FF5733');
      final value = color.toARGB32();
      expect((value >> 16) & 0xFF, 255); // red
      expect((value >> 8) & 0xFF, 87); // green
      expect(value & 0xFF, 51); // blue
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
      final value = color.toARGB32();
      expect((value >> 16) & 0xFF, 255); // red
      expect((value >> 8) & 0xFF, 87); // green
      expect(value & 0xFF, 51); // blue
    });

    test('String.toColor - 带透明度', () {
      final color = '#80FF5733'.toColor();
      final value = color.toARGB32();
      expect((value >> 24) & 0xFF, 128); // alpha
      expect((value >> 16) & 0xFF, 255); // red
      expect((value >> 8) & 0xFF, 87); // green
      expect(value & 0xFF, 51); // blue
    });

    test('String.assetImagePath 读 WAssets.imagePath（资源前缀唯一开关）', () {
      final origin = WAssets.imagePath;
      WAssets.imagePath = 'assets/test/';
      expect('logo.png'.assetImagePath, 'assets/test/logo.png');
      WAssets.imagePath = origin;
      expect('logo.png'.assetImagePath, 'assets/images/logo.png');
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

    test('num.toThousand — 科学计数法展开', () {
      // 1e21 的 toString() 为 "1e+21"
      expect(1e21.toThousand, '1,000,000,000,000,000,000,000');
      expect((-1e21).toThousand, '-1,000,000,000,000,000,000,000');
      // 1.2345e+22 → 12345000000000000000000
      expect(1.2345e22.toThousand, '12,345,000,000,000,000,000,000');
      // 1.5e-7 的 toString() 为 "1.5e-7"
      expect(1.5e-7.toThousand, '0.00000015');
      expect(1e-7.toThousand, '0.0000001');
      expect(double.nan.toThousand, 'NaN');
      expect(double.infinity.toThousand, 'Infinity');
      expect((-double.infinity).toThousand, '-Infinity');
    });

    test('num.toCurrency', () {
      expect(1234.toCurrency(symbol: '¥'), '¥1,234');
      expect(1234.56.toCurrency(symbol: '\$'), '\$1,234.56');
      expect(0.toCurrency(symbol: '¥'), '¥0');
      expect((-1234.56).toCurrency(symbol: '\$'), '-\$1,234.56');
    });

    test('num.toCurrency — 科学计数法展开', () {
      expect(1e21.toCurrency(symbol: '¥'), '¥1,000,000,000,000,000,000,000');
      expect(
        1.2345e22.toCurrency(symbol: '¥', thousandSeparator: ' '),
        '¥12 345 000 000 000 000 000 000',
      );
      expect(
        1.5e-7.toCurrency(symbol: '\$', decimalSeparator: ','),
        '\$0,00000015',
      );
      expect(double.nan.toCurrency(symbol: '¥'), 'NaN');
      expect(double.infinity.toCurrency(symbol: '¥'), 'Infinity');
    });

    test('num.toPercent', () {
      expect(0.5.toPercent, '50%');
      expect(0.333.toPercent, '33.3%');
      expect(1.25.toPercentWithFixed(1), '125.0%');
      expect(0.0.toPercent, '0%');
      expect(2.0.toPercent, '200%');
    });

    test('num.toPadLeft', () {
      expect(1.toPadLeft(2), '01');
      expect(123.toPadLeft(2), '123');
      expect(5.toPadLeft(4), '0005');
      expect(0.toPadLeft(3), '000');
      expect((-1).toPadLeft(3), '-01');
      expect((-12).toPadLeft(4), '-012');
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

    testWidgets('Widget.toPressable', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Click').toPressable(onTap: () => tapped = true),
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
  });

  group('Row / Column / GlobalKey extensions', () {
    testWidgets('Row / Column withIntrinsicHeight', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Row(children: [Text('A')]).withIntrinsicHeight(),
                const Column(children: [Text('B')]).withIntrinsicHeight(),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(IntrinsicHeight), findsNWidgets(2));
    });

    testWidgets('GlobalKey offset / rect 使用全局坐标', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                key: key,
                width: 20,
                height: 10,
              ),
            ),
          ),
        ),
      );

      expect(key.offset(), Offset.zero);
      expect(key.rect(), const Rect.fromLTWH(0, 0, 20, 10));
    });

    testWidgets('未挂载的 GlobalKey 返回 null', (tester) async {
      final key = GlobalKey();
      expect(key.offset(), isNull);
      expect(key.rect(), isNull);
    });
  });
}
