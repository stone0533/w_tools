import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

final _goldenSkip = !Platform.isMacOS || kIsWeb;

Widget _app(Widget child) => MaterialApp(
  theme: ThemeData(useMaterial3: true),
  home: Scaffold(body: child),
);

void main() {
  test('非法尺寸在构造期断言', () {
    expect(() => WDashedLine(thickness: 0), throwsAssertionError);
    expect(() => WDashedLine(dashWidth: 0), throwsAssertionError);
    expect(() => WDashedLine(dashGap: -1), throwsAssertionError);
    expect(() => WDashedLine(indent: -1), throwsAssertionError);
    expect(() => WDashedLine(endIndent: -1), throwsAssertionError);
  });

  testWidgets('默认铺满父级宽度、高度为 thickness', (tester) async {
    await tester.pumpWidget(_app(const WDashedLine()));

    final size = tester.getSize(find.byType(WDashedLine));
    expect(size.width, 800);
    expect(size.height, 1);
    expect(
      find.descendant(of: find.byType(WDashedLine), matching: find.byType(CustomPaint)),
      findsOneWidget,
    );
  });

  testWidgets('indent / endIndent 只收缩线本身，不改变外层宽度', (tester) async {
    await tester.pumpWidget(
      _app(
        const Align(
          alignment: Alignment.topLeft,
          child: WDashedLine(thickness: 2, indent: 20, endIndent: 30),
        ),
      ),
    );

    final line = tester.getRect(
      find.descendant(of: find.byType(WDashedLine), matching: find.byType(CustomPaint)),
    );
    expect(line.left, 20);
    expect(line.width, 800 - 20 - 30);
    expect(line.height, 2);
  });

  testWidgets('dashGap: 0 不死循环（实线）', (tester) async {
    await tester.pumpWidget(_app(const WDashedLine(dashGap: 0)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('父级宽度小于 dashWidth 时只画到边界、不越界', (tester) async {
    await tester.pumpWidget(
      _app(
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 1, child: WDashedLine(dashWidth: 10)),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('跟随 DividerTheme 颜色', (tester) async {
    await tester.pumpWidget(
      _app(
        const DividerTheme(
          data: DividerThemeData(color: Color(0xFFFF0000)),
          child: WDashedLine(),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('WDashedLine golden', skip: _goldenSkip, (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _app(
        Center(
          child: RepaintBoundary(
            key: key,
            child: const SizedBox(
              width: 240,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WDashedLine(color: Color(0xFF333333)),
                  SizedBox(height: 16),
                  WDashedLine(
                    color: Color(0xFF333333),
                    thickness: 2,
                    dashWidth: 6,
                    dashGap: 3,
                  ),
                  SizedBox(height: 16),
                  WDashedLine(
                    color: Color(0xFF333333),
                    indent: 20,
                    endIndent: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/w_dashed_line.png'),
    );
  });
}
