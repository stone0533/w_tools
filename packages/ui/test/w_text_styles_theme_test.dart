import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

WTextStyles _customStyles() => const WTextStyles(
  display: TextStyle(fontSize: 40),
  headline: TextStyle(fontSize: 28),
  title: TextStyle(fontSize: 20),
  body: TextStyle(fontSize: 14),
  bodyStrong: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  caption: TextStyle(fontSize: 12),
  label: TextStyle(fontSize: 12),
  button: TextStyle(fontSize: 14),
  price: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
  number: TextStyle(fontSize: 16, fontFeatures: [FontFeature.tabularFigures()]),
  badge: TextStyle(fontSize: 10),
);

void main() {
  test('toTextTheme / fromTextTheme 对 10 个投影角色互逆', () {
    final styles = _customStyles();
    final base = ThemeData(useMaterial3: true).textTheme;
    final back = WTextStyles.fromTextTheme(styles.toTextTheme(base));

    expect(back.display, styles.display);
    expect(back.headline, styles.headline);
    expect(back.title, styles.title);
    expect(back.body, styles.body);
    expect(back.bodyStrong, styles.bodyStrong);
    expect(back.caption, styles.caption);
    expect(back.label, styles.label);
    expect(back.button, styles.button);
    expect(back.price, styles.price);
    expect(back.badge, styles.badge);
    // number 不投影到 TextTheme，兜底与 body 同尺寸（WText 仍用扩展里的 number）
    expect(back.number, back.body);
  });

  test('未映射的槽位保留 base', () {
    final base = ThemeData(useMaterial3: true).textTheme;
    final mapped = _customStyles().toTextTheme(base);
    expect(mapped.titleSmall, base.titleSmall);
    expect(mapped.headlineLarge, base.headlineLarge);
  });

  test('body 同时驱动输入框与正文；number 不污染输入框', () {
    final styles = _customStyles();
    final mapped = styles.toTextTheme(ThemeData(useMaterial3: true).textTheme);

    // TextField 读 bodyLarge，普通正文读 bodyMedium
    expect(mapped.bodyLarge, styles.body);
    expect(mapped.bodyMedium, styles.body);
    // number 是 WText 专属语义，不投影
    expect(mapped.bodyLarge, isNot(styles.number));
  });

  test('price 不再与 title 共用槽位', () {
    final styles = _customStyles();
    final mapped = styles.toTextTheme(ThemeData(useMaterial3: true).textTheme);
    expect(mapped.titleLarge, styles.title);
    expect(mapped.headlineSmall, styles.price);
    expect(mapped.headlineSmall, isNot(mapped.titleLarge));
  });

  testWidgets('withWTextStyles 同时装好 TextTheme 与扩展', (tester) async {
    final styles = _customStyles();
    final theme = ThemeData(useMaterial3: true).withWTextStyles(styles);

    expect(theme.extension<WTextStyles>(), styles);
    expect(theme.textTheme.titleLarge, styles.title);
    expect(theme.textTheme.headlineSmall, styles.price);
    expect(theme.textTheme.bodySmall, styles.caption);

    late TextTheme observed;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) {
            observed = Theme.of(context).textTheme;
            return const WText(text: '价格', variant: WTextVariant.price);
          },
        ),
      ),
    );

    // Material 组件（form / toast / async 走的就是这条）+ WText 看到同一份样式
    expect(observed.bodySmall?.fontSize, 12);
    expect(tester.widget<Text>(find.text('价格')).style?.fontSize, 24);
  });

  testWidgets('未安装扩展时兜底样式按 TextTheme 缓存，不会每次 build 重建', (tester) async {
    late WTextStyles first;
    late WTextStyles second;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            first = WTextStyles.of(context);
            second = WTextStyles.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(identical(first, second), isTrue);
  });

  test('值相等 / hashCode；ThemeData.extensions 的比较依赖它', () {
    final base = ThemeData(useMaterial3: true).textTheme;
    final a = WTextStyles.fromTextTheme(base);
    final b = WTextStyles.fromTextTheme(base);
    expect(identical(a, b), isFalse);
    expect(a, b);
    expect(a.hashCode, b.hashCode);

    final themeA = ThemeData(useMaterial3: true).withWTextStyles(a);
    final themeB = ThemeData(useMaterial3: true).withWTextStyles(b);
    expect(themeA, themeB);

    expect(a == a.copyWith(title: const TextStyle(fontSize: 21)), isFalse);
  });

  testWidgets('装了扩展时直接返回安装的实例', (tester) async {
    final styles = _customStyles();
    late WTextStyles observed;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true).withWTextStyles(styles),
        home: Builder(
          builder: (context) {
            observed = WTextStyles.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(identical(observed, styles), isTrue);
  });
}
