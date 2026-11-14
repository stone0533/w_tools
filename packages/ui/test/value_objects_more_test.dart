// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
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
    expect(WImageSource.asset('a.png'), WImageSource.asset('a.png'));
    expect(WImageSource.base64('AAAA'), WImageSource.base64('AAAA'));
    expect(WImageSource.file('/tmp/a.png'), WImageSource.file('/tmp/a.png'));
    expect(WImageSource.network('https://x/a.png').key, contains('network:'));
  });

  testWidgets('WButtonTheme.of 缺省回退到 ColorScheme，覆盖优先', (tester) async {
    late WButtonTheme fallback;
    late WButtonTheme custom;
    final scheme = ThemeData(useMaterial3: true).colorScheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Builder(
          builder: (context) {
            fallback = WButtonTheme.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(fallback.filled?.backgroundColor?.resolve({}), scheme.primary);
    expect(fallback.outlined?.foregroundColor?.resolve({}), scheme.primary);
    expect(fallback.danger?.backgroundColor?.resolve({}), scheme.error);

    final customTheme = ThemeData(
      useMaterial3: true,
      extensions: const [
        WButtonTheme(
          filled: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.black),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: customTheme,
        home: Builder(
          builder: (context) {
            custom = WButtonTheme.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(custom.filled?.backgroundColor?.resolve({}), Colors.black);
    // 未覆盖的变体仍然用派生值
    expect(custom.outlined?.foregroundColor?.resolve({}), scheme.primary);
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
    final themed = WImageSlots(placeholderBuilder: (context, data) => const SizedBox());
    await tester.pumpWidget(
      WImageTheme(
        slots: themed,
        child: Builder(
          builder: (context) {
            scoped = WImageTheme.maybeOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(scoped?.placeholderBuilder, isNotNull);

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          fallback = WImageTheme.maybeOf(context);
          expect(WImageTheme.of(context).placeholderBuilder, isNull);
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

    await tester.pumpWidget(build(const WImageSlots()));
    final first = builds;
    await tester.pumpWidget(
      build(WImageSlots(placeholderBuilder: (context, data) => const SizedBox())),
    );
    expect(builds, greaterThan(first));
  });
}
