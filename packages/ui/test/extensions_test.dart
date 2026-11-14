// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  group('Color Extensions', () {
    test('WColorExtension.fromHex - 6位颜色', () {
      final color = WColorExtension.fromHex('#FF5733');
      final value = color.toARGB32();
      expect((value >> 24) & 0xFF, 255); // alpha
      expect((value >> 16) & 0xFF, 255); // red
      expect((value >> 8) & 0xFF, 87); // green
      expect(value & 0xFF, 51); // blue
    });

    test('WColorExtension.fromHex - 8位颜色（带透明度）', () {
      final color = WColorExtension.fromHex('#80FF5733');
      final value = color.toARGB32();
      expect((value >> 24) & 0xFF, 128); // alpha
      expect((value >> 16) & 0xFF, 255); // red
      expect((value >> 8) & 0xFF, 87); // green
      expect(value & 0xFF, 51); // blue
    });

    test('WColorExtension.fromHex - 3位简写', () {
      final color = WColorExtension.fromHex('#F00');
      final value = color.toARGB32();
      expect((value >> 16) & 0xFF, 255); // red
      expect((value >> 8) & 0xFF, 0); // green
      expect(value & 0xFF, 0); // blue
    });

    test('WColorExtension.fromHex - 4位简写（带透明度）', () {
      final color = WColorExtension.fromHex('#8F00');
      final value = color.toARGB32();
      expect((value >> 24) & 0xFF, 136); // alpha ('8' * 17 = 136)
      expect((value >> 16) & 0xFF, 255); // red
      expect((value >> 8) & 0xFF, 0); // green
      expect(value & 0xFF, 0); // blue
    });

    test('WColorExtension.fromHex - 前后空格', () {
      final color = WColorExtension.fromHex(' #FF5733 ');
      expect(color.toARGB32(), const Color(0xFFFF5733).toARGB32());
    });

    test('WColorExtension.fromHex - 不带#前缀', () {
      final color = WColorExtension.fromHex('FF5733');
      final value = color.toARGB32();
      expect((value >> 16) & 0xFF, 255); // red
      expect((value >> 8) & 0xFF, 87); // green
      expect(value & 0xFF, 51); // blue
    });

    test('WColorExtension.fromHex - 无效格式抛出异常', () {
      expect(() => WColorExtension.fromHex(''), throwsFormatException);
      expect(() => WColorExtension.fromHex('#FFF'), returnsNormally); // 有效的3位
      expect(() => WColorExtension.fromHex('#FFFF'), returnsNormally); // 有效的4位
      expect(() => WColorExtension.fromHex('#FFFFF'), throwsFormatException); // 无效的5位
      expect(() => WColorExtension.fromHex('#12#34'), throwsFormatException); // # 只能有一个前缀
      expect(() => WColorExtension.fromHex('12#34'), throwsFormatException);
    });

    test('Color.toHex', () {
      const color = Color(0xFFFF5733);
      expect(color.toHex(), '#ffff5733');
      expect(color.toHex(leadingHashSign: false), 'ffff5733');
    });

    test('fromCssHex 按 RRGGBBAA 解析（与 fromHex 相反）', () {
      final css = WColorExtension.fromCssHex('#FF573380');
      final value = css.toARGB32();
      expect((value >> 24) & 0xFF, 128); // alpha 在最后两位
      expect((value >> 16) & 0xFF, 255); // red
      expect((value >> 8) & 0xFF, 87); // green
      expect(value & 0xFF, 51); // blue

      expect(
        WColorExtension.fromCssHex('#FF5733').toARGB32(),
        const Color(0xFFFF5733).toARGB32(),
      );
      expect(WColorExtension.fromCssHex('FF573380').toARGB32(), value);
    });

    test('fromCssHex 无效格式抛出 FormatException', () {
      expect(() => WColorExtension.fromCssHex(''), throwsFormatException);
      expect(() => WColorExtension.fromCssHex('#FFF'), throwsFormatException);
      expect(() => WColorExtension.fromCssHex('#FF573'), throwsFormatException);
      expect(() => WColorExtension.fromCssHex('#FF57#380'), throwsFormatException);
    });

    test('toCssHex 输出 RRGGBBAA', () {
      const color = Color(0x80FF5733);
      expect(color.toCssHex(), '#ff573380');
      expect(color.toCssHex(leadingHashSign: false), 'ff573380');
      expect(WColorExtension.fromCssHex(color.toCssHex()).toARGB32(), color.toARGB32());
    });
  });

  group('String Extensions', () {
    test('String.toCssColor 按 CSS 顺序解析', () {
      final color = '#FF573380'.toCssColor();
      final value = color.toARGB32();
      expect((value >> 24) & 0xFF, 128);
      expect((value >> 16) & 0xFF, 255);
      expect((value >> 8) & 0xFF, 87);
      expect(value & 0xFF, 51);
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
  });

  group('Num Layout Extensions', () {
    test('num.allPadding', () {
      final padding = 10.allPadding;
      expect(padding, const EdgeInsets.all(10));
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

  group('Row / Column extensions', () {
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
  });

  group('WWidgetExtension', () {
    testWidgets('withStartPadding / withEndPadding 跟随 Directionality', (tester) async {
      Widget build(TextDirection direction) => MaterialApp(
        home: Directionality(
          textDirection: direction,
          child: Column(
            children: [
              Container(key: const ValueKey('s'), child: const SizedBox().withStartPadding(4)),
              Container(key: const ValueKey('e'), child: const SizedBox().withEndPadding(6)),
            ],
          ),
        ),
      );
      EdgeInsetsDirectional paddingOf(String key) =>
          tester
                  .widget<Padding>(
                    find
                        .descendant(of: find.byKey(ValueKey(key)), matching: find.byType(Padding))
                        .first,
                  )
                  .padding
              as EdgeInsetsDirectional;

      await tester.pumpWidget(build(TextDirection.ltr));
      expect(paddingOf('s').resolve(TextDirection.ltr), const EdgeInsets.only(left: 4));
      expect(paddingOf('e').resolve(TextDirection.ltr), const EdgeInsets.only(right: 6));

      await tester.pumpWidget(build(TextDirection.rtl));
      expect(paddingOf('s').resolve(TextDirection.rtl), const EdgeInsets.only(right: 4));
      expect(paddingOf('e').resolve(TextDirection.rtl), const EdgeInsets.only(left: 6));
    });

    test('withIntrinsicHeight / expanded 包装正确', () {
      const child = SizedBox();
      expect(child.withIntrinsicHeight(), isA<IntrinsicHeight>());
      final expanded = child.expanded(2);
      expect(expanded, isA<Expanded>());
      expect((expanded as Expanded).flex, 2);
    });

    testWidgets('toPressable 触发 onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: const Text('卡片').toPressable(onTap: () => taps++),
        ),
      );
      await tester.tap(find.text('卡片'));
      expect(taps, 1);
    });
  });
  group('上下文相关扩展', () {
    testWidgets('withTopSafeSpaceOf / withBottomSafeSpaceOf 读 MediaQuery', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(top: 24, bottom: 12),
            ),
            child: Builder(
              builder: (context) => Column(
                children: [
                  const SizedBox(width: 10, height: 10).withTopSafeSpaceOf(context),
                  const SizedBox(width: 10, height: 10).withBottomSafeSpaceOf(context),
                ],
              ),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) => widget is Padding && widget.padding == const EdgeInsets.only(top: 24),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Padding && widget.padding == const EdgeInsets.only(bottom: 12),
        ),
        findsOneWidget,
      );
    });

    testWidgets('num.borderSideOf 使用主题 outline 颜色', (tester) async {
      late BorderSide side;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              side = 2.borderSideOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(side.width, 2);
      expect(side.color, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.outline);
    });

    test('withBackground 清空另一种背景', () {
      final colorOnly = const BoxDecoration().withBackground(color: Colors.red);
      expect(colorOnly.color, Colors.red);
      expect(colorOnly.gradient, isNull);

      const gradient = LinearGradient(colors: [Colors.red, Colors.blue]);
      final gradientOnly = const BoxDecoration().withBackground(gradient: gradient);
      expect(gradientOnly.gradient, gradient);
      expect(gradientOnly.color, isNull);

      expect(
        () => const BoxDecoration().withBackground(color: Colors.red, gradient: gradient),
        throwsAssertionError,
      );
    });
  });
}
