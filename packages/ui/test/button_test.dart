import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/button.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('WButtonStyle', () {
    test('默认值 / copyWith / validate', () {
      const style = WButtonStyle();
      expect(style.effect, WButtonEffectType.opacity);
      expect(style.pressedOpacity, 0.7);
      expect(style.pressedScale, 0.95);
      expect(style.animationDuration, const Duration(milliseconds: 100));
      expect(style.semanticLabel, isNull);

      final next = style.copyWith(
        effect: WButtonEffectType.scale,
        pressedScale: 0.9,
        semanticLabel: '提交',
      );
      expect(next.effect, WButtonEffectType.scale);
      expect(next.pressedScale, 0.9);
      expect(next.semanticLabel, '提交');
      expect(style.effect, WButtonEffectType.opacity);
      expect(() => style.validate(), returnsNormally);
    });

    test('非法值触发 assert', () {
      expect(
        () => const WButtonStyle(pressedOpacity: 1.5).validate(),
        throwsAssertionError,
      );
      expect(
        () => const WButtonStyle(pressedScale: 0).validate(),
        throwsAssertionError,
      );
      expect(
        () => const WButtonStyle(animationDuration: Duration(milliseconds: -1)).validate(),
        throwsAssertionError,
      );
    });

    test('静态预设可用', () {
      expect(WButtonStyles.primary.container, isNotNull);
      expect(WButtonStyles.secondary.container, isNotNull);
      expect(WButtonStyles.text.textStyle, isNotNull);
      expect(WButtonStyles.danger.container, isNotNull);
    });
  });

  group('WButton 基础交互', () {
    testWidgets('点击触发 onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          WButton(
            onTap: () => taps++,
            child: const Text('点击'),
          ),
        ),
      );

      await tester.tap(find.text('点击'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('禁用 / loading 不触发 onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          WButton(
            enabled: false,
            onTap: () => taps++,
            child: const Text('禁用'),
          ),
        ),
      );
      await tester.tap(find.text('禁用'));
      await tester.pumpAndSettle();
      expect(taps, 0);

      await tester.pumpWidget(
        _wrap(
          WButton(
            loading: true,
            onTap: () => taps++,
            child: const Text('加载中'),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(CircularProgressIndicator));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('禁用时 child 的点击也被阻断', (tester) async {
      var childTaps = 0;
      await tester.pumpWidget(
        _wrap(
          WButton(
            enabled: false,
            child: GestureDetector(
              onTap: () => childTaps++,
              child: const SizedBox(width: 80, height: 40, child: Text('child')),
            ),
          ),
        ),
      );

      await tester.tap(find.text('child'));
      await tester.pumpAndSettle();
      expect(childTaps, 0);
    });

    testWidgets('最小点击区域为 48x48', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(
            onTap: () {},
            child: const SizedBox(width: 1, height: 1),
          ),
        ),
      );

      final box = tester.widget<ConstrainedBox>(
        find
            .descendant(
              of: find.byType(WButton),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(box.constraints.minWidth, 48);
      expect(box.constraints.minHeight, 48);
    });

    testWidgets('loading 保持 child 占位尺寸', (tester) async {
      Widget build(bool loading) => _wrap(
            WButton(
              loading: loading,
              onTap: () {},
              child: const SizedBox(width: 120, height: 40),
            ),
          );

      await tester.pumpWidget(build(false));
      final normal = tester.getSize(find.byType(WButton));
      await tester.pumpWidget(build(true));
      final loading = tester.getSize(find.byType(WButton));
      expect(loading.width, normal.width);
      expect(loading.height, normal.height);
    });

    testWidgets('tooltip 与 onPressedChanged', (tester) async {
      final pressed = <bool>[];
      await tester.pumpWidget(
        _wrap(
          WButton(
            tooltip: '提交提示',
            onPressedChanged: pressed.add,
            onTap: () {},
            child: const Text('tooltip'),
          ),
        ),
      );
      expect(find.byType(Tooltip), findsOneWidget);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('tooltip')),
      );
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(pressed, [true, false]);
    });

    testWidgets('长按进入 Semantics', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(
            onLongPress: () {},
            child: const Text('semantic-longpress'),
          ),
        ),
      );
      final semantics = tester
          .widgetList<Semantics>(
            find.descendant(of: find.byType(WButton), matching: find.byType(Semantics)),
          )
          .firstWhere((s) => s.properties.button == true);
      expect(semantics.properties.onLongPress, isNotNull);
    });

    testWidgets('长按触发 onLongPress', (tester) async {
      var longPressed = 0;
      await tester.pumpWidget(
        _wrap(
          WButton(
            onLongPress: () => longPressed++,
            child: const Text('长按'),
          ),
        ),
      );

      await tester.longPress(find.text('长按'));
      await tester.pumpAndSettle();
      expect(longPressed, 1);
    });
  });

  group('WButton 效果与无障碍', () {
    testWidgets('opacity 效果按下时降低透明度', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(
            style: const WButtonStyle(pressedOpacity: 0.4),
            onTap: () {},
            child: const Text('opacity'),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('opacity')),
      );
      await tester.pump();
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0.4,
      );

      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1.0,
      );
    });

    testWidgets('scale 效果按下时缩小', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(
            style: const WButtonStyle(
              effect: WButtonEffectType.scale,
              pressedScale: 0.8,
            ),
            onTap: () {},
            child: const Text('scale'),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('scale')),
      );
      await tester.pump();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        0.8,
      );
      await gesture.up();
    });

    testWidgets('键盘 Enter 触发 onTap 和按下效果', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          WButton(
            autofocus: true,
            style: const WButtonStyle(pressedOpacity: 0.35),
            onTap: () => taps++,
            child: const Text('键盘'),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0.35,
      );
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpAndSettle();
    });

    testWidgets('semanticLabel / hint 进入 Semantics', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(
            style: const WButtonStyle(
              semanticLabel: '关闭',
              semanticHint: '关闭当前弹窗',
            ),
            onTap: () {},
            child: const Icon(Icons.close),
          ),
        ),
      );

      final semantics = tester
          .widgetList<Semantics>(
            find.descendant(of: find.byType(WButton), matching: find.byType(Semantics)),
          )
          .firstWhere((s) => s.properties.button == true);
      expect(semantics.properties.label, '关闭');
      expect(semantics.properties.hint, '关闭当前弹窗');
      expect(semantics.properties.onTap, isNotNull);
    });
  });

  group('WButtonTheme', () {
    testWidgets('未传 style 时使用 theme.primary', (tester) async {
      await tester.pumpWidget(
        WButtonTheme(
          data: const WButtonThemeData(
            primary: WButtonStyle(semanticLabel: '主题按钮'),
          ),
          child: _wrap(
            WButton(
              onTap: () {},
              child: const Text('themed'),
            ),
          ),
        ),
      );

      final semantics = tester
          .widgetList<Semantics>(
            find.descendant(of: find.byType(WButton), matching: find.byType(Semantics)),
          )
          .firstWhere((s) => s.properties.button == true);
      expect(semantics.properties.label, '主题按钮');
    });

    testWidgets('显式 style 覆盖 theme', (tester) async {
      await tester.pumpWidget(
        WButtonTheme(
          data: const WButtonThemeData(
            primary: WButtonStyle(semanticLabel: '主题按钮'),
          ),
          child: _wrap(
            WButton(
              style: const WButtonStyle(semanticLabel: '局部按钮'),
              onTap: () {},
              child: const Text('override'),
            ),
          ),
        ),
      );

      final semantics = tester
          .widgetList<Semantics>(
            find.descendant(of: find.byType(WButton), matching: find.byType(Semantics)),
          )
          .firstWhere((s) => s.properties.button == true);
      expect(semantics.properties.label, '局部按钮');
    });
  });
}
