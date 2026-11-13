import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

/// 测试专用：4.0 删除的旧静态预设的等价副本（用于断言 / 示例 style）。
class _LegacyButtonStyles {
  static final primary = WButtonStyle.filled(
    backgroundColor: const Color(0xFF3949AB),
    foregroundColor: Colors.white,
  );
  static final secondary = WButtonStyle.outlined(
    foregroundColor: const Color(0xFF3949AB),
    borderColor: const Color(0xFF3949AB),
  );
  static final text = WButtonStyle.text(foregroundColor: const Color(0xFF3949AB));
  static final danger = WButtonStyle.filled(
    backgroundColor: const Color(0xFFD32F2F),
    foregroundColor: Colors.white,
  );
}

void main() {
  group('WButtonStyle / motion / semantics', () {
    test('默认值与 copyWith', () {
      const style = WButtonStyle();
      const motion = WButtonMotion();
      const semantics = WButtonSemantics();
      expect(motion.effect, WPressEffect.opacity);
      expect(motion.pressedOpacity, 0.7);
      expect(motion.pressedScale, 0.95);
      expect(motion.duration, const Duration(milliseconds: 100));
      expect(semantics.label, isNull);
      expect(style.alignment, Alignment.center);

      final next = style.copyWith(
        alignment: Alignment.centerLeft,
        minHeight: 60,
        focusColor: Colors.black12,
      );
      expect(next.alignment, Alignment.centerLeft);
      expect(next.minHeight, 60);
      expect(next.focusColor, Colors.black12);
      expect(() => style.validate(), returnsNormally);
      expect(() => motion.validate(), returnsNormally);
    });

    test('filled 未传 foregroundColor 时按背景亮度推导前景色', () {
      final dark = WButtonStyle.filled(backgroundColor: Colors.black);
      expect(dark.foregroundColor?.resolve(<WidgetState>{}), Colors.white);

      final light = WButtonStyle.filled(backgroundColor: Colors.white);
      expect(light.foregroundColor?.resolve(<WidgetState>{}), Colors.black);

      final explicit = WButtonStyle.filled(
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
      );
      expect(explicit.foregroundColor?.resolve(<WidgetState>{}), Colors.amber);
    });

    test('backgroundColor 与 gradient 互斥（debug assert）', () {
      const style = WButtonStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.red),
        gradient: WidgetStatePropertyAll(
          LinearGradient(colors: [Colors.red, Colors.blue]),
        ),
      );
      expect(style.validate, throwsAssertionError);
    });

    test('WButtonMotion.copyWith 替换字段并保留其余', () {
      const motion = WButtonMotion(effect: WPressEffect.scale, pressedScale: 0.9);
      final next = motion.copyWith(
        effect: WPressEffect.none,
        pressedOpacity: 0.5,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      expect(next.effect, WPressEffect.none);
      expect(next.pressedOpacity, 0.5);
      expect(next.pressedScale, 0.9);
      expect(next.duration, const Duration(milliseconds: 200));
      expect(next.curve, Curves.easeOut);
      expect(motion.effect, WPressEffect.scale);
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
      final style = _LegacyButtonStyles.primary;
      expect(style.backgroundColor, isNotNull);
      expect(style.borderRadius, isNotNull);
      expect(style.withoutBackground().backgroundColor, isNull);
      expect(style.withoutBackground().borderRadius, isNotNull);
      expect(style.withoutDecoration().borderRadius, isNull);
      expect(style.withoutBorder().border, isNull);
      expect(style.withoutBorder().borderRadius, isNotNull);
      expect(style.withoutBoxShadow().boxShadow, isNull);
      expect(style.withoutTextStyle().textStyle, isNull);
      expect(style.withoutTextStyle().foregroundColor, isNotNull);
      expect(style.withoutText().textStyle, isNull);
      expect(style.withoutText().foregroundColor, isNull);
      expect(style.withoutForegroundColor().foregroundColor, isNull);
      expect(style.withoutFocusColor().focusColor, isNull);
      expect(style.withoutHoverColor().hoverColor, isNull);

      final bordered = style.withBorder(Border.all(color: Colors.black));
      expect(bordered.border!.resolve(const {}), isNotNull);
      final shadowed = style.withBoxShadow(const [BoxShadow()]);
      expect(shadowed.boxShadow!.resolve(const {}), hasLength(1));
      final textStyled = style.withTextStyle(const TextStyle(fontSize: 12));
      expect(textStyled.textStyle!.resolve(const {})!.fontSize, 12);

      const semantics = WButtonSemantics(label: 'label', hint: 'hint');
      expect(semantics.withoutLabel().label, isNull);
      expect(semantics.withoutLabel().hint, 'hint');
      expect(semantics.withoutHint().hint, isNull);
      expect(semantics.withoutHint().label, 'label');
    });

    test('静态预设与工厂可用', () {
      expect(_LegacyButtonStyles.primary.backgroundColor, isNotNull);
      expect(_LegacyButtonStyles.secondary.border, isNotNull);
      expect(_LegacyButtonStyles.text.foregroundColor, isNotNull);
      expect(_LegacyButtonStyles.danger.backgroundColor, isNotNull);

      final filled = WButtonStyle.filled(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      );
      expect(filled.backgroundColor!.resolve(const {}), Colors.red);
      expect(filled.foregroundColor!.resolve(const {}), Colors.white);
      expect(filled.borderRadius, isNotNull);

      final outlined = WButtonStyle.outlined(foregroundColor: Colors.blue);
      expect(outlined.border!.resolve(const {}), isNotNull);
      expect(outlined.foregroundColor!.resolve(const {}), Colors.blue);

      final text = WButtonStyle.text(foregroundColor: Colors.black);
      expect(text.foregroundColor!.resolve(const {}), Colors.black);
      expect(text.backgroundColor, isNull);

      final overridden = WButtonStyle.filled(
        backgroundColor: Colors.blue,
      ).withBackgroundColor(Colors.red);
      expect(overridden.backgroundColor!.resolve(const {}), Colors.red);
      expect(overridden.gradient, isNull);

      final withGradient = const WButtonStyle(
        gradient: WidgetStatePropertyAll(
          LinearGradient(
            colors: [Colors.blue, Colors.red],
          ),
        ),
      ).withBackgroundColor(Colors.green);
      expect(withGradient.gradient, isNull);
      expect(withGradient.backgroundColor!.resolve(const {}), Colors.green);
    });

    test('boxShadow 解析后不可变', () {
      const style = WButtonStyle(
        boxShadow: WidgetStatePropertyAll(<BoxShadow>[BoxShadow()]),
      );
      final resolved = style.resolve(const {});
      expect(resolved.boxShadow, hasLength(1));
      expect(
        () => resolved.boxShadow!.add(const BoxShadow()),
        throwsUnsupportedError,
      );
    });

    test('预设不可变且共享', () {
      final a = _LegacyButtonStyles.primary;
      final b = _LegacyButtonStyles.primary;
      expect(identical(a, b), isTrue);
      expect(identical(a.textStyle, b.textStyle), isTrue);
    });
  });

  testWidgets('WidgetStateProperty 按 pressed/disabled 解析', (tester) async {
    final style = WButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return Colors.grey;
        if (states.contains(WidgetState.pressed)) return Colors.red;
        return Colors.blue;
      }),
    );

    await tester.pumpWidget(
      _wrap(WButton(label: 'state', style: style, onTap: () {})),
    );
    BoxDecoration decoration() =>
        tester.widget<DecoratedBox>(find.byType(DecoratedBox).first).decoration as BoxDecoration;
    expect(decoration().color, Colors.blue);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('state')),
    );
    await tester.pump();
    expect(decoration().color, Colors.red);
    await gesture.up();
    await tester.pumpAndSettle();
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

    test('copyWith 传 null 表示保留，且仍接受 int 字面量', () {
      final sized = WButtonSize.small.copyWith(minHeight: 40, iconSize: 20);
      expect(sized.minHeight, 40.0);
      expect(sized.iconSize, 20.0);

      final kept = sized.copyWith(
        minHeight: null,
        iconSize: null,
        padding: null,
        fontSize: null,
        fontWeight: null,
        lineHeight: null,
        letterSpacing: null,
        gap: null,
      );
      expect(kept.minHeight, 40.0);
      expect(kept.iconSize, 20.0);
      expect(kept.padding, sized.padding);
      expect(kept.fontSize, sized.fontSize);
      expect(kept.fontWeight, sized.fontWeight);
      expect(kept.lineHeight, sized.lineHeight);
      expect(kept.letterSpacing, sized.letterSpacing);
      expect(kept.gap, sized.gap);
      expect(kept.tapTargetSize, 48);
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
            style: _LegacyButtonStyles.primary,
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

    testWidgets('contentBuilder 接收最终 style 和 states', (tester) async {
      Set<WidgetState>? states;
      await tester.pumpWidget(
        _wrap(
          WButton(
            style: _LegacyButtonStyles.primary,
            size: const WButtonSize(name: 'custom', iconSize: 32),
            contentBuilder: (context, style) {
              states = style.states;
              return Text('icon=${style.iconSize}');
            },
            onTap: () {},
          ),
        ),
      );
      expect(find.text('icon=32.0'), findsOneWidget);
      expect(states, isEmpty);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('icon=32.0')),
      );
      await tester.pump();
      expect(states, contains(WidgetState.pressed));
      expect(() => states!.add(WidgetState.hovered), throwsUnsupportedError);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('contentBuilder 可读取 disabled state', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(
            style: _LegacyButtonStyles.primary,
            enabled: false,
            contentBuilder: (context, style) {
              return Text(
                style.states.contains(WidgetState.disabled) ? '禁用内容' : '正常内容',
              );
            },
            onTap: () {},
          ),
        ),
      );
      expect(find.text('禁用内容'), findsOneWidget);
    });

    testWidgets('foregroundColor 同步应用到 label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(
            style: const WButtonStyle(
              foregroundColor: WidgetStatePropertyAll(Colors.red),
            ),
            label: 'red-label',
            onTap: () {},
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('red-label'));
      expect(text.style?.color, Colors.red);
    });

    testWidgets('label/icon/content 三选一', (tester) async {
      await tester.pumpWidget(
        _wrap(WButton(style: _LegacyButtonStyles.primary, label: '主按钮', onTap: () {})),
      );
      expect(find.text('主按钮'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          WButton(
            style: _LegacyButtonStyles.primary,
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
        _wrap(WButton(style: _LegacyButtonStyles.primary, label: '默认', onTap: () {})),
      );
      expect(
        tester.getSize(find.byType(WButton)).height,
        greaterThanOrEqualTo(48),
      );

      await tester.pumpWidget(
        _wrap(
          WButton(
            style: _LegacyButtonStyles.primary,
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
        _wrap(WButton(style: _LegacyButtonStyles.primary, label: '点击', onTap: () => taps++)),
      );

      await tester.tap(find.text('点击'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    test('没有 onTap/onLongPress 时构造断言', () {
      expect(
        () => WButton(label: 'no-action'),
        throwsAssertionError,
      );
    });

    testWidgets('禁用按钮可以不提供回调', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(
            style: _LegacyButtonStyles.primary,
            label: 'disabled-no-callback',
            enabled: false,
          ),
        ),
      );
      expect(find.text('disabled-no-callback'), findsOneWidget);
    });

    testWidgets('按下过程中禁用不触发 onTap', (tester) async {
      var taps = 0;
      Widget build(bool enabled) => _wrap(
        WButton(
          style: _LegacyButtonStyles.primary,
          label: 'mid-gesture',
          enabled: enabled,
          onTap: () => taps++,
        ),
      );

      await tester.pumpWidget(build(true));
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('mid-gesture')),
      );
      await tester.pump();
      await tester.pumpWidget(build(false));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 0);
    });

    testWidgets('禁用 / loading 不触发 onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          WButton(
            style: _LegacyButtonStyles.primary,
            label: '禁用',
            enabled: false,
            onTap: () => taps++,
          ),
        ),
      );
      await tester.tap(find.byType(WButton));
      await tester.pumpAndSettle();
      expect(taps, 0);

      await tester.pumpWidget(
        _wrap(
          WButton(
            style: _LegacyButtonStyles.primary,
            label: '加载中',
            loading: true,
            onTap: () => taps++,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(WButton));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('loading 保持按钮尺寸', (tester) async {
      Widget build(bool loading) => _wrap(
        WButton(style: _LegacyButtonStyles.primary, label: '提交', loading: loading, onTap: () {}),
      );

      await tester.pumpWidget(build(false));
      final normal = tester.getSize(find.byType(WButton));
      await tester.pumpWidget(build(true));
      final loading = tester.getSize(find.byType(WButton));
      expect(loading.width, normal.width);
      expect(loading.height, normal.height);
    });

    testWidgets('loading 指示器使用按钮前景色（主色按钮上可见）', (tester) async {
      const foreground = Color(0xFFFFFFFF);
      await tester.pumpWidget(
        _wrap(
          WButton(
            style: WButtonStyle.filled(
              backgroundColor: const Color(0xFF3949AB),
              foregroundColor: foreground,
            ),
            label: '提交',
            loading: true,
            onTap: () {},
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.color, foreground);
    });

    testWidgets('loading 语义是 liveRegion', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          WButton(
            style: _LegacyButtonStyles.primary,
            label: '提交',
            loading: true,
            onTap: () {},
          ),
        ),
      );

      final liveRegion = find.descendant(
        of: find.byType(WButton),
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.liveRegion == true,
        ),
      );
      expect(liveRegion, findsOneWidget);
      expect(tester.widget<Semantics>(liveRegion).properties.label, 'Loading');
      handle.dispose();
    });

    testWidgets('长按进入 Semantics 并触发 onLongPress', (tester) async {
      var longPressed = 0;
      await tester.pumpWidget(
        _wrap(
          WButton(
            style: _LegacyButtonStyles.primary,
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
              child: WButton(style: _LegacyButtonStyles.primary, label: '暗色', onTap: () {}),
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
            style: const WButtonStyle(focusColor: Colors.red),
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
                  child: WButton(style: _LegacyButtonStyles.primary, label: '提交', onTap: () {}),
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
            motion: const WButtonMotion(pressedOpacity: 0.4),
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
            motion: const WButtonMotion(
              effect: WPressEffect.scale,
              pressedScale: 0.8,
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

    testWidgets('只有 onLongPress 时不启用键盘焦点', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(
            style: _LegacyButtonStyles.primary,
            label: 'long-only',
            onLongPress: () {},
          ),
        ),
      );
      final detector = tester.widget<FocusableActionDetector>(
        find.descendant(
          of: find.byType(WButton),
          matching: find.byType(FocusableActionDetector),
        ),
      );
      expect(detector.enabled, isFalse);
    });

    testWidgets('没有 onTap 时键盘不触发按下状态', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(
            style: _LegacyButtonStyles.primary,
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
            motion: const WButtonMotion(pressedOpacity: 0.35),
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
            semantics: const WButtonSemantics(
              label: '关闭',
              hint: '关闭当前弹窗',
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

  testWidgets('全宽 WButton 的 label 居中', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 300,
          child: WButton(label: 'OK', onTap: () {}),
        ),
      ),
    );

    final button = tester.getRect(find.byType(WButton));
    final label = tester.getRect(find.text('OK'));
    expect(label.center.dx, closeTo(button.center.dx, 0.01));
  });

  group('WButton 默认样式跟随主题', () {
    testWidgets('未传 style 时使用 colorScheme.primary', (tester) async {
      final theme = ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green);

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: WButton(label: '提交', onTap: () {}),
          ),
        ),
      );

      final boxes = tester.widgetList<DecoratedBox>(
        find.descendant(of: find.byType(WButton), matching: find.byType(DecoratedBox)),
      );
      expect(
        boxes.any((box) => (box.decoration as BoxDecoration?)?.color == theme.colorScheme.primary),
        isTrue,
      );
    });

    testWidgets('深色主题下默认色来自暗色 ColorScheme', (tester) async {
      final theme = ThemeData(useMaterial3: true, brightness: Brightness.dark);

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: WButton(label: '提交', onTap: () {}),
          ),
        ),
      );

      final boxes = tester.widgetList<DecoratedBox>(
        find.descendant(of: find.byType(WButton), matching: find.byType(DecoratedBox)),
      );
      expect(
        boxes.any((box) => (box.decoration as BoxDecoration?)?.color == theme.colorScheme.primary),
        isTrue,
      );
    });

    testWidgets('WButtonStyles.of 按 ThemeData 缓存', (tester) async {
      final theme = ThemeData(useMaterial3: true);
      late BuildContext context;

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (inner) {
              context = inner;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final first = WButtonStyles.of(context);
      final second = WButtonStyles.of(context);
      expect(identical(first.primary, second.primary), isTrue);
      expect(first.danger.backgroundColor, isNotNull);
    });
  });

  group('WButtonResolvedStyle', () {
    test('值相等 / hashCode（states 与 boxShadow 按内容比较）', () {
      const a = WButtonResolvedStyle(
        states: {WidgetState.pressed, WidgetState.hovered},
        backgroundColor: Colors.red,
        boxShadow: [BoxShadow(color: Colors.black12)],
        iconSize: 20,
      );
      final states = <WidgetState>{WidgetState.hovered, WidgetState.pressed};
      final b = WButtonResolvedStyle(
        states: states,
        backgroundColor: Colors.red,
        boxShadow: const [BoxShadow(color: Colors.black12)],
        iconSize: 20,
      );
      expect(identical(a, b), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == const WButtonResolvedStyle(), isFalse);
    });
  });
}
