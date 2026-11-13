// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  test('WNavBarStyle 值相等 / hashCode', () {
    const a = WNavBarStyle(
      decoration: BoxDecoration(color: Colors.white),
      padding: EdgeInsets.all(8),
    );
    const b = WNavBarStyle(
      decoration: BoxDecoration(color: Colors.white),
      padding: EdgeInsets.all(8),
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(const WNavBarStyle(padding: EdgeInsets.all(4))));
  });

  test('WTabBarStyle copyWith / noSplash / 值相等', () {
    const style = WTabBarStyle(isScrollable: true, indicatorWeight: 3);
    final next = style.copyWith(labelStyle: const TextStyle(fontSize: 14));
    expect(style.isScrollable, isTrue);
    expect(next.labelStyle?.fontSize, 14);
    expect(next.indicatorWeight, 3);
    expect(next.copyWith(isScrollable: false).isScrollable, isFalse);
    expect(WTabBarStyle.noSplash.overlayColor, Colors.transparent);
    expect(WTabBarStyle.noSplash.splashFactory, NoSplash.splashFactory);
    expect(style, const WTabBarStyle(isScrollable: true, indicatorWeight: 3));
  });

  test('WBadgeStyle copyWith / 值相等', () {
    const base = WBadgeStyle(backgroundColor: Colors.red);
    final next = base.copyWith(foregroundColor: Colors.white);
    expect(next.backgroundColor, Colors.red);
    expect(next.foregroundColor, Colors.white);
    expect(base, const WBadgeStyle(backgroundColor: Colors.red));
    expect(base, isNot(const WBadgeStyle(backgroundColor: Colors.blue)));
    expect(
      const WBadgePosition.topEnd(top: 2).toString(),
      contains('topEnd'),
    );
  });

  test('WButtonSize 预设 / copyWith / 值相等', () {
    expect(WButtonSize.small.minHeight, 32);
    expect(WButtonSize.medium.minHeight, 40);
    expect(WButtonSize.large.minHeight, 48);
    expect(WButtonSize.small, WButtonSize.small);
    expect(WButtonSize.small, isNot(WButtonSize.medium));
    final next = WButtonSize.small.copyWith(name: 'custom', minHeight: 36);
    expect(next.name, 'custom');
    expect(next.minHeight, 36);
    expect(next.padding, WButtonSize.small.padding);
    expect(() => const WButtonSize(minHeight: -1).validate(), throwsAssertionError);
  });

  test('WStepFlow 值相等 / copyWith 保留字段', () {
    final a = WStepFlow(labels: const ['下单', '付款', '完成']);
    final b = WStepFlow(labels: const ['下单', '付款', '完成']);
    expect(identical(a, b), isFalse);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(WStepFlow(labels: const ['下单'])));

    final next = a.copyWith(labels: const ['A', 'B']);
    expect(next.labels, const ['A', 'B']);
    expect(next.style, a.style);
  });

  test('WButtonMotion copyWith / validate / 值相等', () {
    const motion = WButtonMotion(duration: Duration(milliseconds: 200));
    final next = motion.copyWith(pressedScale: 0.9);
    expect(next.duration, const Duration(milliseconds: 200));
    expect(next.pressedScale, 0.9);
    expect(motion, const WButtonMotion(duration: Duration(milliseconds: 200)));
    expect(
      () => const WButtonMotion(pressedOpacity: 2).validate(),
      throwsAssertionError,
    );
  });

  test('WTextStyles copyWith / lerp / 值相等', () {
    final base = WTextStyles.fromTextTheme(ThemeData(useMaterial3: true).textTheme);
    final next = base.copyWith(title: const TextStyle(fontSize: 21));
    expect(next.title.fontSize, 21);
    expect(base.title.fontSize, isNot(21));
    expect(base.lerp(next, 0.5), isA<WTextStyles>());
    expect(base, WTextStyles.fromTextTheme(ThemeData(useMaterial3: true).textTheme));
  });

  test('WScreenData 值相等包含 scaler 身份', () {
    const a = WScreenData(size: Size(390, 844), padding: EdgeInsets.zero);
    const b = WScreenData(size: Size(390, 844), padding: EdgeInsets.zero);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    final scaled = WScreenData(
      size: const Size(390, 844),
      padding: EdgeInsets.zero,
      widthScaler: (v) => v * 2,
    );
    expect(a, isNot(scaled));
    expect(scaled.w(10), 20);
    expect(scaled.h(10), 10);
    expect(scaled.sp(10), 10);
  });

  test('WImageSource 值相等 / key', () {
    expect(
      WImageSource.network('https://x/a.png', headers: const {'a': 'b'}),
      WImageSource.network('https://x/a.png', headers: const {'a': 'b'}),
    );
    expect(
      WImageSource.network('https://x/a.png'),
      isNot(WImageSource.network('https://x/b.png')),
    );
    expect(WImageSource.asset('a.png', prefix: true), WImageSource.asset('a.png', prefix: true));
    expect(WImageSource.base64('AAAA'), WImageSource.base64('AAAA'));
    expect(WImageSource.file('/tmp/a.png'), WImageSource.file('/tmp/a.png'));
    expect(WImageSource.network('https://x/a.png').key, contains('network:'));
  });

  test('WImageFrame 应用边框 / 阴影 / margin / padding', () {
    const style = WImageStyle(
      border: Border.fromBorderSide(BorderSide(color: Colors.black12)),
      boxShadow: [BoxShadow(color: Colors.black12)],
      margin: EdgeInsets.all(2),
      padding: EdgeInsets.all(3),
      borderRadius: BorderRadius.all(Radius.circular(6)),
    );
    const frame = WImageFrame(style: style, child: SizedBox(width: 10, height: 10));
    expect(frame.style.border, isNotNull);
    expect(frame.style.boxShadow, isNotEmpty);
    expect(frame.style.margin, const EdgeInsets.all(2));
  });

  testWidgets('WButtonStyles.of 四种样式与值相等', (tester) async {
    late WButtonStyleSet first;
    late WButtonStyleSet second;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Builder(
          builder: (context) {
            first = WButtonStyles.of(context);
            second = WButtonStyles.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(first.primary, isNot(first.danger));
  });

  testWidgets('WImageFrame 构建阴影与前景边框', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WImageFrame(
          style: WImageStyle(
            border: Border.fromBorderSide(BorderSide(color: Colors.black12)),
            boxShadow: [BoxShadow(color: Colors.black12)],
            borderRadius: BorderRadius.all(Radius.circular(6)),
            margin: EdgeInsets.all(2),
            padding: EdgeInsets.all(3),
          ),
          child: SizedBox(width: 10, height: 10),
        ),
      ),
    );
    expect(find.byType(DecoratedBox), findsNWidgets(2));
  });

  testWidgets('WBadge 自定义 style 应用边框与内边距', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WBadge(
            badgeContent: Text('9'),
            style: WBadgeStyle(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.all(4),
              borderRadius: BorderRadius.all(Radius.circular(4)),
              border: Border.fromBorderSide(BorderSide(color: Colors.black12)),
            ),
          ),
        ),
      ),
    );
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(WBadge), matching: find.byType(DecoratedBox)).last,
    );
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.color, Colors.green);
    expect(decoration.border, isNotNull);
  });

  test('WImageLoadOptions withoutMemCache*', () {
    const options = WImageLoadOptions(memCacheWidth: 10, memCacheHeight: 20);
    expect(options.withoutMemCacheWidth().memCacheWidth, isNull);
    expect(options.withoutMemCacheWidth().memCacheHeight, 20);
    expect(options.withoutMemCacheHeight().memCacheWidth, 10);
    expect(options.withoutMemCacheHeight().memCacheHeight, isNull);
  });

  testWidgets('WImageTheme of / maybeOf', (tester) async {
    WImageSlots? scoped;
    WImageSlots? fallback;
    await tester.pumpWidget(
      WImageTheme(
        slots: const WImageSlots(showRetryButton: true),
        child: Builder(
          builder: (context) {
            scoped = WImageTheme.maybeOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(scoped?.showRetryButton, isTrue);

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          fallback = WImageTheme.maybeOf(context);
          expect(WImageTheme.of(context).showRetryButton, isNull);
          return const SizedBox.shrink();
        },
      ),
    );
    expect(fallback, isNull);
  });

  testWidgets('WImageTheme 不同 slots 触发更新', (tester) async {
    var builds = 0;
    Widget build(WImageSlots slots) => WImageTheme(
      slots: slots,
      child: Builder(
        builder: (context) {
          builds++;
          WImageTheme.of(context);
          return const SizedBox.shrink();
        },
      ),
    );

    await tester.pumpWidget(build(const WImageSlots(showRetryButton: true)));
    final first = builds;
    await tester.pumpWidget(build(const WImageSlots(showRetryButton: false)));
    expect(builds, greaterThan(first));
  });
}
