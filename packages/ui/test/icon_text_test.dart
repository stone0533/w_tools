import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

Widget _wrap(Widget child, {TextDirection textDirection = TextDirection.ltr, ThemeData? theme}) {
  return MaterialApp(
    theme: theme,
    home: Directionality(
      textDirection: textDirection,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

Text _textWidget(WidgetTester tester) => tester.widget<Text>(
  find.descendant(of: find.byType(WIconText), matching: find.byType(Text)),
);

TextSpan _span(WidgetTester tester) => _textWidget(tester).textSpan! as TextSpan;

void main() {
  testWidgets('默认渲染 icon + text，WidgetSpan 按行盒中点对齐', (tester) async {
    await tester.pumpWidget(
      _wrap(const WIconText(icon: Icons.star, text: '收藏')),
    );

    expect(find.byIcon(Icons.star), findsOneWidget);
    final span = _span(tester);
    expect(span.toPlainText(), contains('收藏'));
    final placeholder = span.children!.first as WidgetSpan;
    expect(placeholder.alignment, PlaceholderAlignment.middle);
    expect(span.children!.last, isA<TextSpan>());
    expect((span.children!.last as TextSpan).text, '收藏');
  });

  testWidgets('variant / style / color 的优先级与图标跟随', (tester) async {
    final base = ThemeData(useMaterial3: true);
    final styles = WTextStyles.fromTextTheme(base.textTheme);
    final theme = base.withWTextStyles(styles);

    await tester.pumpWidget(
      _wrap(
        const WIconText(
          icon: Icons.info_outline,
          text: '说明',
          variant: WTextVariant.title,
          style: TextStyle(fontWeight: FontWeight.w700),
          color: Colors.red,
        ),
        theme: theme,
      ),
    );

    final textWidget = _textWidget(tester);
    expect(textWidget.style?.fontSize, styles.title.fontSize);
    expect(textWidget.style?.fontWeight, FontWeight.w700);
    expect(textWidget.style?.color, Colors.red);

    final icon = tester.widget<Icon>(find.byIcon(Icons.info_outline));
    expect(icon.size, (styles.title.fontSize ?? 14) + 2);
    expect(icon.color, Colors.red);
  });

  testWidgets('iconSize / iconColor / iconOffset 可覆盖', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const WIconText(
          icon: Icons.star,
          text: '收藏',
          iconSize: 20,
          iconColor: Colors.green,
          iconOffset: Offset(0, 2),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.star));
    expect(icon.size, 20);
    expect(icon.color, Colors.green);

    final transform = tester.widget<Transform>(
      find.descendant(of: find.byType(WIconText), matching: find.byType(Transform)),
    );
    expect(transform.transform.storage[13], 2.0);
  });

  testWidgets('默认图标尺寸跟随 textScaler', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const WIconText(
          icon: Icons.star,
          text: '收藏',
          style: TextStyle(fontSize: 20),
          textScaler: TextScaler.linear(2),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.star));
    expect(icon.size, 44); // (20 + 2) * 2
  });

  testWidgets('gap 用 EdgeInsetsDirectional：LTR 在右，RTL 在左', (tester) async {
    const child = WIconText(icon: Icons.star, text: '收藏', gap: 8);

    await tester.pumpWidget(_wrap(child));
    final ltrPadding = tester.widget<Padding>(
      find.descendant(of: find.byType(WIconText), matching: find.byType(Padding)),
    );
    expect(ltrPadding.padding.resolve(TextDirection.ltr), const EdgeInsets.only(right: 8));

    await tester.pumpWidget(_wrap(child, textDirection: TextDirection.rtl));
    final rtlPadding = tester.widget<Padding>(
      find.descendant(of: find.byType(WIconText), matching: find.byType(Padding)),
    );
    expect(rtlPadding.padding.resolve(TextDirection.rtl), const EdgeInsets.only(left: 8));
  });

  testWidgets('maxLines / overflow / softWrap / textAlign 透传', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const WIconText(
          icon: Icons.star,
          text: '一段比较长的文字',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          textAlign: TextAlign.center,
        ),
      ),
    );

    final textWidget = _textWidget(tester);
    expect(textWidget.maxLines, 1);
    expect(textWidget.overflow, TextOverflow.ellipsis);
    expect(textWidget.softWrap, isFalse);
    expect(textWidget.textAlign, TextAlign.center);
  });

  testWidgets('semanticsLabel 覆盖整行，图标不重复朗读', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(
        const WIconText(
          icon: Icons.info_outline,
          text: '说明',
          semanticsLabel: '说明文字',
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(WIconText));
    expect(semantics.label, contains('说明文字'));
    handle.dispose();
  });
}
