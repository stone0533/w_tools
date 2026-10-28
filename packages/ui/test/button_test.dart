import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/button/button.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('WButtonStyle', () {
    test('默认值 / copyWith / validate', () {
      final style = WButtonStyle();
      expect(style.effect, WButtonEffectType.opacity);
      expect(style.pressedOpacity, 0.7);
      expect(style.pressedScale, 0.95);
      expect(style.animationDuration, const Duration(milliseconds: 100));
      expect(style.semanticLabel, isNull);

      final next = style.copyWith(
        effect: WButtonEffectType.scale,
        pressedScale: 0.9,
        semanticLabel: '提交',
        minHeight: 60,
        focusColor: Colors.black12,
      );
      expect(next.effect, WButtonEffectType.scale);
      expect(next.pressedScale, 0.9);
      expect(next.semanticLabel, '提交');
      expect(next.minHeight, 60);
      expect(next.focusColor, Colors.black12);
      expect(style.effect, WButtonEffectType.opacity);
      expect(() => style.validate(), returnsNormally);
    });

    test('非法值触发 assert', () {
      expect(
        () => WButtonStyle(pressedOpacity: 1.5).validate(),
        throwsAssertionError,
      );
      expect(
        () => WButtonStyle(pressedScale: 0).validate(),
        throwsAssertionError,
      );
      expect(
        () => WButtonStyle(
          animationDuration: const Duration(milliseconds: -1),
        ).validate(),
        throwsAssertionError,
      );
    });

    test('静态预设与工厂可用', () {
      expect(WButtonStyles.primary.container, isNotNull);
      expect(WButtonStyles.secondary.container, isNotNull);
      expect(WButtonStyles.text.textStyle, isNotNull);
      expect(WButtonStyles.danger.container, isNotNull);

      final filled = WButtonStyle.filled(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      );
      expect(filled.container, isNotNull);
      expect(filled.textStyle, isNotNull);
      expect(filled.overlayBorderRadius, isNotNull);

      final outlined = WButtonStyle.outlined(foregroundColor: Colors.blue);
      expect(outlined.container, isNotNull);
      expect(outlined.textStyle, isNotNull);

      final text = WButtonStyle.text(foregroundColor: Colors.black);
      expect(text.container, isNotNull);
      expect(text.textStyle, isNotNull);
    });

    test('预设返回独立副本', () {
      final a = WButtonStyles.primary;
      final b = WButtonStyles.primary;
      expect(identical(a, b), isFalse);
      expect(identical(a.container, b.container), isFalse);

      final deep = a.copy();
      expect(identical(a.container, deep.container), isFalse);
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

  group('WButton 构造与尺寸', () {
    testWidgets('公共构造支持 variant + label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(
            variant: 'primary',
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
            variant: 'primary',
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
            variant: 'primary',
            size: const WButtonSize(name: 'custom', iconSize: 32),
            contentBuilder: (context, style) => Text('icon=${style.iconSize}'),
            onTap: () {},
          ),
        ),
      );
      expect(find.text('icon=32.0'), findsOneWidget);
    });

    testWidgets('loading 保留 content 尺寸', (tester) async {
      Widget build(bool loading) => _wrap(
            WButton(
              variant: 'primary',
              loading: loading,
              content: const SizedBox(width: 120, height: 40),
              onTap: () {},
            ),
          );

      await tester.pumpWidget(build(false));
      final normal = tester.getSize(find.byType(WButton));
      await tester.pumpWidget(build(true));
      final loading = tester.getSize(find.byType(WButton));
      expect(loading.width, normal.width);
      expect(loading.height, normal.height);
    });

    testWidgets('WButton.primary / icon 可用', (tester) async {
      await tester.pumpWidget(
        _wrap(WButton.primary('主按钮', onTap: () {})),
      );
      expect(find.text('主按钮'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(WButton.icon(Icons.add, label: '新增', onTap: () {})),
      );
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('新增'), findsOneWidget);
    });

    testWidgets('默认尺寸和 small 都有 48 高点击区域', (tester) async {
      await tester.pumpWidget(
        _wrap(WButton.primary('默认', onTap: () {})),
      );
      expect(
        tester.getSize(find.byType(WButton)).height,
        greaterThanOrEqualTo(48),
      );

      await tester.pumpWidget(
        _wrap(
          WButton.primary(
            '小按钮',
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

    testWidgets('图标按钮 tooltip 作为语义标签', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton.icon(Icons.close, tooltip: '关闭', onTap: () {}),
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
    });

    testWidgets('自定义 variant 从 theme 解析', (tester) async {
      await tester.pumpWidget(
        WButtonTheme(
          data: WButtonThemeData(
            variants: {
              'brand': WButtonStyle(semanticLabel: '品牌按钮'),
            },
          ),
          child: _wrap(
            WButton.variant('brand', '品牌', onTap: () {}),
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
      expect(semantics.properties.label, '品牌按钮');
    });

    testWidgets('sizeName 从 theme 解析', (tester) async {
      await tester.pumpWidget(
        WButtonTheme(
          data: WButtonThemeData(
            sizes: const {
              'hero': WButtonSize(name: 'hero', minHeight: 60),
            },
          ),
          child: _wrap(
            WButton.primary('大按钮', sizeName: 'hero', onTap: () {}),
          ),
        ),
      );

      final box = tester
          .widgetList<ConstrainedBox>(find.byType(ConstrainedBox))
          .firstWhere((b) => b.constraints.minHeight == 60);
      expect(box.constraints.minHeight, 60);
    });
  });

  group('WButton 交互', () {
    testWidgets('点击触发 onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          WButton.primary('点击', onTap: () => taps++),
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
          WButton.primary(
            '禁用',
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
          WButton.primary(
            '加载中',
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
            WButton.primary(
              '提交',
              loading: loading,
              onTap: () {},
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
            variant: 'primary',
            label: 'tooltip',
            tooltip: '提交提示',
            onPressedChanged: pressed.add,
            onTap: () {},
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

    testWidgets('长按进入 Semantics 并触发 onLongPress', (tester) async {
      var longPressed = 0;
      await tester.pumpWidget(
        _wrap(
          WButton.primary(
            '长按',
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

    testWidgets('RTL 与大字号下可构建', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: Center(
                  child: WButton.primary('提交', onTap: () {}),
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
          WButton.primary(
            'opacity',
            style: WButtonStyle(pressedOpacity: 0.4),
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
          WButton.primary(
            'scale',
            style: WButtonStyle(
              effect: WButtonEffectType.scale,
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
    });

    testWidgets('没有 onTap 时键盘不触发按下状态', (tester) async {
      final pressed = <bool>[];
      await tester.pumpWidget(
        _wrap(
          WButton(
            variant: 'primary',
            label: 'longpress-only',
            autofocus: true,
            onLongPress: () {},
            onPressedChanged: pressed.add,
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(pressed, isEmpty);
    });

    testWidgets('键盘 press 不会被后续指针 press 的旧 timer 提前复位', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton.primary(
            'race',
            autofocus: true,
            style: WButtonStyle(pressedOpacity: 0.35),
            onTap: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('race')),
      );
      await tester.pump(const Duration(milliseconds: 150));
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0.35,
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('键盘 Enter 触发 onTap 和按下效果', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          WButton.primary(
            '键盘',
            autofocus: true,
            style: WButtonStyle(pressedOpacity: 0.35),
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
          WButton.icon(
            Icons.close,
            style: WButtonStyle(
              semanticLabel: '关闭',
              semanticHint: '关闭当前弹窗',
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

  group('WButtonTheme', () {
    testWidgets('支持 ThemeData.extensions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              WButtonThemeData(
                primary: WButtonStyle(semanticLabel: 'extension-button'),
              ),
            ],
          ),
          home: Scaffold(
            body: WButton.primary('extension', onTap: () {}),
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
      expect(semantics.properties.label, 'extension-button');
    });

    test('copyWith 保留未覆盖字段', () {
      final data = WButtonThemeData(
        primary: WButtonStyles.primary,
        danger: WButtonStyles.danger,
      );
      final next = data.copyWith(primary: WButtonStyles.secondary);
      expect(identical(next.danger, data.danger), isTrue);
      expect(identical(next.primary, data.primary), isFalse);
    });

    testWidgets('未传 style 时使用 theme.primary', (tester) async {
      await tester.pumpWidget(
        WButtonTheme(
          data: WButtonThemeData(
            primary: WButtonStyle(semanticLabel: '主题按钮'),
          ),
          child: _wrap(
            WButton.primary('themed', onTap: () {}),
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
      expect(semantics.properties.label, '主题按钮');
    });

    testWidgets('显式 style 覆盖 theme', (tester) async {
      await tester.pumpWidget(
        WButtonTheme(
          data: WButtonThemeData(
            primary: WButtonStyle(semanticLabel: '主题按钮'),
          ),
          child: _wrap(
            WButton.primary(
              'override',
              style: WButtonStyle(semanticLabel: '局部按钮'),
              onTap: () {},
            ),
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
      expect(semantics.properties.label, '局部按钮');
    });
  });
}
