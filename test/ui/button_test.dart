import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/button.dart';

void main() {
  group('WButtonConfig', () {
    test('should create default config', () {
      final config = WButtonConfig();
      expect(config, isNotNull);
    });

    test('should support chaining methods', () {
      final config = WButtonConfig()
        ..tapOpacity = (0.5)
        ..animationDuration = (const Duration(milliseconds: 200))
        ..enabled = (false)
        ..behavior = (HitTestBehavior.translucent)
        ..effectType = (WButtonEffectType.scale)
        ..scale = (0.9)
        ..curve = (Curves.bounceIn);
      expect(config, isNotNull);
    });

    test('should create opacity effect config', () {
      final config = WButtonConfig.opacityEffect(opacity: 0.6);
      expect(config, isNotNull);
    });

    test('should create scale effect config', () {
      final config = WButtonConfig.scaleEffect(scale: 0.9);
      expect(config, isNotNull);
    });

    test('should create shake effect config', () {
      final config = WButtonConfig.shakeEffect();
      expect(config, isNotNull);
    });

    test('should clear cache', () {
      // Create some configs to populate cache
      WButtonConfig.opacityEffect();
      WButtonConfig.scaleEffect();

      // Clear cache
      WButtonConfig.clearCache();
      // Cache should be empty after clearing
      // Note: We can't directly access the private _configCache, but we can verify the method exists and doesn't throw
      expect(() => WButtonConfig.clearCache(), returnsNormally);
    });

    test('should trim cache', () {
      // Create some configs to populate cache
      for (int i = 0; i < 5; i++) {
        WButtonConfig.opacityEffect(opacity: 0.1 * i);
      }

      // Trim cache
      WButtonConfig.trimCache();
      // Method should not throw
      expect(() => WButtonConfig.trimCache(), returnsNormally);
    });
  });

  group('WButton', () {
    testWidgets('should render with default config', (WidgetTester tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WButton(
                onTap: () => tapCount++,
                child: const Text('Test Button'),
              ),
            ),
          ),
        ),
      );

      // Verify button is rendered
      expect(find.text('Test Button'), findsOneWidget);

      // Tap the button
      await tester.tap(find.text('Test Button'));
      await tester.pumpAndSettle();

      // Verify tap callback is called
      expect(tapCount, 1);
    });

    testWidgets('具备 button 语义', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WButton(
              onTap: () {},
              child: const Text('semantic-button'),
            ),
          ),
        ),
      );

      final semantics = tester
          .widgetList<Semantics>(
            find.descendant(of: find.byType(WButton), matching: find.byType(Semantics)),
          )
          .firstWhere((s) => s.properties.button == true);
      expect(semantics.properties.enabled, isTrue);
    });

    testWidgets('should render with opacity effect', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WButton(
                onTap: () {},
                config: WButtonConfig.opacityEffect(),
                child: const Text('Opacity Button'),
              ),
            ),
          ),
        ),
      );

      // Verify button is rendered
      expect(find.text('Opacity Button'), findsOneWidget);
    });

    testWidgets('should render with scale effect', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WButton(
                onTap: () {},
                config: WButtonConfig.scaleEffect(),
                child: const Text('Scale Button'),
              ),
            ),
          ),
        ),
      );

      // Verify button is rendered
      expect(find.text('Scale Button'), findsOneWidget);
    });

    testWidgets('should render with shake effect', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WButton(
                onTap: () {},
                config: WButtonConfig.shakeEffect(),
                child: const Text('Shake Button'),
              ),
            ),
          ),
        ),
      );

      // Verify button is rendered
      expect(find.text('Shake Button'), findsOneWidget);
    });

    testWidgets('should not respond to taps when disabled', (WidgetTester tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WButton(
                onTap: () => tapCount++,
                config: WButtonConfig()..enabled = (false),
                child: const Text('Disabled Button'),
              ),
            ),
          ),
        ),
      );

      // Verify button is rendered
      expect(find.text('Disabled Button'), findsOneWidget);

      // Tap the button
      await tester.tap(find.text('Disabled Button'));
      await tester.pumpAndSettle();

      // Verify tap callback is not called
      expect(tapCount, 0);
    });
  });

  group('WButtonEffectType', () {
    test('should have all effect types', () {
      expect(WButtonEffectType.values.length, 3);
      expect(WButtonEffectType.opacity, isNotNull);
      expect(WButtonEffectType.scale, isNotNull);
      expect(WButtonEffectType.shake, isNotNull);
    });
  });

  group('WButtonConfig 缓存隔离（回归）', () {
    test('快捷方法每次返回独立实例，不与缓存共享', () {
      final a = WButtonConfig.opacityEffect(opacity: 0.3);
      final b = WButtonConfig.opacityEffect(opacity: 0.3);
      // 修复前：两次返回同一个缓存实例（identical 为 true）
      expect(identical(a, b), isFalse);
    });

    test('copy() 返回独立实例', () {
      final origin = WButtonConfig()
        ..tapOpacity = 0.2
        ..enabled = false;
      final copied = origin.copy();
      expect(identical(origin, copied), isFalse);
    });

    testWidgets('修改已取回的配置，不会污染后续使用者', (WidgetTester tester) async {
      // 修复前该配置与缓存共享，禁用后会连带影响下一次获取
      final polluted = WButtonConfig.opacityEffect(opacity: 0.3);
      polluted.enabled = false;

      int taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WButton(
                onTap: () => taps++,
                config: WButtonConfig.opacityEffect(opacity: 0.3),
                child: const Text('cached button'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('cached button'));
      await tester.pumpAndSettle();

      // 新配置仍应为「启用」状态，点击回调可触发
      expect(taps, 1);
    });
  });
}
