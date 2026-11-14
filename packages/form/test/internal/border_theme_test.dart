import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/src/components/border/border.dart';

void main() {
  group('WFormBorderStyle.fromTheme', () {
    test('边框 / 聚焦 / 错误 / 只读底色都来自 ColorScheme', () {
      final theme = ThemeData(useMaterial3: true);
      final scheme = theme.colorScheme;
      final style = WFormBorderStyle.fromTheme(theme);

      expect(style.defaultDecoration?.color, scheme.surface);
      expect((style.defaultDecoration!.border! as Border).top.color, scheme.outlineVariant);
      expect((style.focusedDecoration!.border! as Border).top.color, scheme.primary);
      expect((style.errorDecoration!.border! as Border).top.color, scheme.error);
      expect(style.readOnlyDecoration?.color, scheme.surfaceContainerLow);
    });

    test('明暗主题给出不同颜色（不再是写死白底）', () {
      final light = WFormBorderStyle.fromTheme(ThemeData(useMaterial3: true));
      final dark = WFormBorderStyle.fromTheme(
        ThemeData(useMaterial3: true, brightness: Brightness.dark),
      );

      expect(light.defaultDecoration?.color, isNot(dark.defaultDecoration?.color));
      expect(
        (light.defaultDecoration!.border! as Border).top.color,
        isNot((dark.defaultDecoration!.border! as Border).top.color),
      );
    });

    test('同一主题派生出的配置值相等（避免每帧重建）', () {
      final theme = ThemeData(useMaterial3: true);
      expect(WFormBorderStyle.fromTheme(theme), WFormBorderStyle.fromTheme(theme));
      expect(
        WFormBorderStyle.fromTheme(theme).hashCode,
        WFormBorderStyle.fromTheme(theme).hashCode,
      );
    });

    testWidgets('hint / error 文字来自 TextTheme.bodySmall，颜色分别取 onSurfaceVariant / error', (
      tester,
    ) async {
      final theme = ThemeData(useMaterial3: true);
      final scheme = theme.colorScheme;
      final style = WFormBorderStyle.fromTheme(theme);
      final errorChannel = ValueNotifier<List<String>?>(null);

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: WFormBorder(
              style: style,
              errorChannel: errorChannel,
              hintTextList: const ['请输入'],
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      final hint = tester.widget<Text>(find.text('请输入'));
      expect(hint.style?.color, scheme.onSurfaceVariant);
      expect(hint.style?.fontSize, theme.textTheme.bodySmall?.fontSize);

      errorChannel.value = const ['格式不对'];
      await tester.pump();
      final error = tester.widget<Text>(find.text('格式不对'));
      expect(error.style?.color, scheme.error);
    });

    testWidgets('显式 helperStyle 的颜色优先', (tester) async {
      final theme = ThemeData(useMaterial3: true);
      final style = WFormBorderStyle.fromTheme(
        theme,
        helperStyle: const TextStyle(fontSize: 13, color: Color(0xFF112233)),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: WFormBorder(
              style: style,
              hintTextList: const ['x'],
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      final hint = tester.widget<Text>(find.text('x'));
      expect(hint.style?.color, const Color(0xFF112233));
      expect(hint.style?.fontSize, 13);
    });

    testWidgets('深色主题下 WFormBorder 渲染的是深色可读文字', (tester) async {
      final theme = ThemeData(useMaterial3: true, brightness: Brightness.dark);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: WFormBorder(
              style: WFormBorderStyle.fromTheme(theme),
              hintTextList: const ['请输入'],
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('请输入'));
      expect(text.style?.color, theme.colorScheme.onSurfaceVariant);
    });
  });
}
