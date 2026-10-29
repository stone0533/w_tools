import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/button/button.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('WButtonStyle / motion / semantics', () {
    test('默认值与 copyWith', () {
      final style = WButtonStyle();
      expect(style.motion.effect, WButtonEffectType.opacity);
      expect(style.motion.pressedOpacity, 0.7);
      expect(style.motion.pressedScale, 0.95);
      expect(style.motion.duration, const Duration(milliseconds: 100));
      expect(style.semantics.label, isNull);

      final next = style.copyWith(
        motion: const WButtonMotion(
          effect: WButtonEffectType.scale,
          pressedScale: 0.9,
        ),
        semantics: const WButtonSemantics(label: '提交'),
        minHeight: 60,
        focusColor: Colors.black12,
      );
      expect(next.motion.effect, WButtonEffectType.scale);
      expect(next.motion.pressedScale, 0.9);
      expect(next.semantics.label, '提交');
      expect(next.minHeight, 60);
      expect(next.focusColor, Colors.black12);
      expect(style.motion.effect, WButtonEffectType.opacity);
      expect(() => style.validate(), returnsNormally);
    });

    test('非法值触发 assert', () {
      expect(
        () => const WButtonMotion(pressedOpacity: 1.5).validate(),
        throwsAssertionError,
      );
      expect(
        () => const WButtonMotion(pressedScale: 0).validate(),
        throwsAssertionError,
      );
      expect(
        () => const WButtonMotion(
          duration: Duration(milliseconds: -1),
        ).validate(),
        throwsAssertionError,
      );
    });

    test('typed copyWith 与 clear helpers', () {
      final style = WButtonStyles.primary;
      expect(style.backgroundColor, isNotNull);
      expect(style.borderRadius, isNotNull);
      expect(style.withoutBackground().backgroundColor, isNull);
      expect(style.withoutBackground().borderRadius, isNotNull);
      expect(style.withoutDecoration().borderRadius, isNull);
      expect(style.withoutTextStyle().textStyle, isNull);
      expect(style.withoutTextStyle().foregroundColor, isNull);
      expect(style.withoutForegroundColor().foregroundColor, isNull);
      expect(style.withoutFocusColor().focusColor, isNull);
      expect(style.withoutHoverColor().hoverColor, isNull);

      const semantics = WButtonSemantics(label: 'label', hint: 'hint');
      expect(semantics.withoutLabel().label, isNull);
      expect(semantics.withoutLabel().hint, 'hint');
      expect(semantics.withoutHint().hint, isNull);
      expect(semantics.withoutHint().label, 'label');
    });

    test('静态预设与工厂可用', () {
      expect(WButtonStyles.primary.backgroundColor, isNotNull);
      expect(WButtonStyles.secondary.border, isNotNull);
      expect(WButtonStyles.text.foregroundColor, isNotNull);
      expect(WButtonStyles.danger.backgroundColor, isNotNull);

      final filled = WButtonStyle.filled(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      );
      expect(filled.backgroundColor, Colors.red);
      expect(filled.foregroundColor, Colors.white);
      expect(filled.borderRadius, isNotNull);

      final outlined = WButtonStyle.outlined(foregroundColor: Colors.blue);
      expect(outlined.border, isNotNull);
      expect(outlined.foregroundColor, Colors.blue);

      final text = WButtonStyle.text(foregroundColor: Colors.black);
      expect(text.foregroundColor, Colors.black);
      expect(text.backgroundColor, isNull);
    });

    test('boxShadow 防御性不可变', () {
      final shadows = <BoxShadow>[const BoxShadow()];
      final style = WButtonStyle(boxShadow: shadows);
      shadows.add(const BoxShadow());
      expect(style.boxShadow, hasLength(1));
      expect(() => style.boxShadow!.add(const BoxShadow()), throwsUnsupportedError);
    });

    test('预设不可变且共享', () {
      final a = WButtonStyles.primary;
      final b = WButtonStyles.primary;
      expect(identical(a, b), isTrue);
      expect(identical(a.textStyle, b.textStyle), isTrue);
    });
  });

  group('WButtonSize', () {
    test('默认值与 copyWith', () {
      const small = WButtonSize.small;
      expect(small.name, 'small');
      expect(small.minHeight, 32);
      expect(small.fontSize, 13);
      expect(small.tapTargetSize, 48);

      final custom = small.copyWith(
        name: 'compact',
        minHeight: 28,
        lineHeight: 1.2,
        letterSpacing: 0.3,
      );
      expect(custom.name, 'compact');
      expect(custom.minHeight, 28);
      expect(custom.lineHeight, 1.2);
      expect(custom.letterSpacing, 0.3);
    });

    test('非法值触发 assert', () {
      expect(
        () => const WButtonSize(name: 'bad', minHeight: -1).validate(),
        throwsAssertionError,
      );
      expect(
        () => const WButtonSize(name: 'bad', fontSize: 0).validate(),
        throwsAssertionError,
      );
    });
  });

  group('WButton 构造与内容', () {
    testWidgets('公共构造支持 label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(
            label: '公共构造',
            onTap: () {},
          ),
        ),
      );
      expect(find.text('公共构造'), findsOneWidget);
    });

    testWidgets('content 支持静态复杂内容', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(
            style: WButtonStyles.primary,
            content: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 8),
                Text('自定义内容'),
              ],
            ),
            onTap: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('自定义内容'), findsOneWidget);

      final semantics = tester
          .widgetList<Semantics>(
            find.descendant(
              of: find.byType(WButton),
              matching: find.byType(Semantics),
            ),
          )
          .firstWhere((s) => s.properties.button == true);
      expect(semantics.properties.button, isTrue);
    });

    testWidgets('contentBuilder 接收最终 style', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(
            style: WButtonStyles.primary,
            size: const WButtonSize(name: 'custom', iconSize: 32),
            contentBuilder: (context, style) => Text('icon=${style.iconSize}'),
            onTap: () {},
          ),
        ),
      );
      expect(find.text('icon=32.0'), findsOneWidget);
    });

    testWidgets('label/icon/content 三选一', (tester) async {
      await tester.pumpWidget(
        _wrap(WButton(style: WButtonStyles.primary, label: '主按钮', onTap: () {})),
      );
      expect(find.text('主按钮'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          WButton(
            style: WButtonStyles.primary,
            icon: Icons.add,
            semanticLabel: '新增',
            onTap: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('默认尺寸和 small 都有 48 高点击区域', (tester) async {
      await tester.pumpWidget(
        _wrap(WButton(style: WButtonStyles.primary, label: '默认', onTap: () {})),
      );
      expect(
        tester.getSize(find.byType(WButton)).height,
        greaterThanOrEqualTo(48),
      );

      await tester.pumpWidget(
        _wrap(
          WButton(
            style: WButtonStyles.primary,
            label: '小按钮',
            size: WButtonSize.small,
            onTap: () {},
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(WButton)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('WButton 交互', () {
    testWidgets('点击触发 onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(WButton(style: WButtonStyles.primary, label: '点击', onTap: () => taps++)),
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
            style: WButtonStyles.primary,
            label: '禁用',
            enabled: false,
            onTap: () => taps++,
          ),
        ),
      );
      await tester.tap(find.text('禁用'));
      await tester.pumpAndSettle();
      expect(taps, 0);

      await tester.pumpWidget(
        _wrap(
          WButton(
            style: WButtonStyles.primary,
            label: '加载中',
            loading: true,
            onTap: () => taps++,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(CircularProgressIndicator));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('loading 保持按钮尺寸', (tester) async {
      Widget build(bool loading) => _wrap(
            WButton(style: WButtonStyles.primary, label: '提交', loading: loading, onTap: () {}),
          );

      await tester.pumpWidget(build(false));
      final normal = tester.getSize(find.byType(WButton));
      await tester.pumpWidget(build(true));
      final loading = tester.getSize(find.byType(WButton));
      expect(loading.width, normal.width);
      expect(loading.height, normal.height);
    });

    testWidgets('长按进入 Semantics 并触发 onLongPress', (tester) async {
      var longPressed = 0;
      await tester.pumpWidget(
        _wrap(
          WButton(
            style: WButtonStyles.primary,
            label: '长按',
            onLongPress: () => longPressed++,
          ),
        ),
      );

      final semantics = tester
          .widgetList<Semantics>(
            find.descendant(
              of: find.byType(WButton),
              matching: find.byType(Semantics),
            ),
          )
          .firstWhere((s) => s.properties.button == true);
      expect(semantics.properties.onLongPress, isNotNull);

      await tester.longPress(find.text('长按'));
      await tester.pumpAndSettle();
      expect(longPressed, 1);
    });

    testWidgets('暗色主题下可构建', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: Scaffold(
            body: Center(
              child: WButton(style: WButtonStyles.primary, label: '暗色', onTap: () {}),
            ),
          ),
        ),
      );
      expect(find.text('暗色'), findsOneWidget);
    });

    testWidgets('focus overlay 使用 focusColor', (tester) async {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() {
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
      });
      await tester.pumpWidget(
        _wrap(
          WButton(
            label: 'focus',
            autofocus: true,
            style: WButtonStyle(focusColor: Colors.red),
            onTap: () {},
          ),
        ),
      );
      await tester.pump();
      final boxes = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .where((box) => box.color == Colors.red);
      expect(boxes, isNotEmpty);
    });

    testWidgets('RTL 与大字号下可构建', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: Center(
                  child: WButton(style: WButtonStyles.primary, label: '提交', onTap: () {}),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('提交'), findsOneWidget);
    });
  });

  group('WButton 效果与键盘', () {
    testWidgets('opacity 效果按下时降低透明度', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(
            label: 'opacity',
            style: WButtonStyle(
              motion: const WButtonMotion(pressedOpacity: 0.4),
            ),
            onTap: () {},
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
            label: 'scale',
            style: WButtonStyle(
              motion: const WButtonMotion(
                effect: WButtonEffectType.scale,
                pressedScale: 0.8,
              ),
            ),
            onTap: () {},
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
      await tester.pumpAndSettle();
    });

    testWidgets('没有 onTap 时键盘不触发按下状态', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(
            style: WButtonStyles.primary,
            label: 'longpress-only',
            autofocus: true,
            onLongPress: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1.0,
      );
    });

    testWidgets('键盘 Enter 触发 onTap 和按下效果', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          WButton(
            label: '键盘',
            autofocus: true,
            style: WButtonStyle(
              motion: const WButtonMotion(pressedOpacity: 0.35),
            ),
            onTap: () => taps++,
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
            icon: Icons.close,
            style: WButtonStyle(
              semantics: const WButtonSemantics(
                label: '关闭',
                hint: '关闭当前弹窗',
              ),
            ),
            onTap: () {},
          ),
        ),
      );

      final semantics = tester
          .widgetList<Semantics>(
            find.descendant(
              of: find.byType(WButton),
              matching: find.byType(Semantics),
            ),
          )
          .firstWhere((s) => s.properties.button == true);
      expect(semantics.properties.label, '关闭');
      expect(semantics.properties.hint, '关闭当前弹窗');
      expect(semantics.properties.onTap, isNotNull);
    });
  });
}
