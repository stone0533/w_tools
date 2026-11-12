// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  setUp(() {
    // 重置所有 delegate
    WScreen.delegateWidth = null;
    WScreen.delegateHeight = null;
    WScreen.delegateFont = null;
  });

  tearDown(() {
    WScreen.delegateWidth = null;
    WScreen.delegateHeight = null;
    WScreen.delegateFont = null;
  });

  group('WScreen.of(context)', () {
    testWidgets('跟随树内 MediaQuery', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(412, 915),
            padding: EdgeInsets.only(top: 24, bottom: 12),
          ),
          child: Builder(
            builder: (context) {
              final data = WScreen.of(context);
              expect(data.width, 412);
              expect(data.height, 915);
              expect(data.statusBarHeight, 24);
              expect(data.bottomSafeAreaHeight, 12);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });

  group('WScreenScope', () {
    testWidgets('scope 注入 w/h/sp，优先于全局 delegate', (tester) async {
      WScreen.delegateWidth = (v) => v * 10;
      await tester.pumpWidget(
        MaterialApp(
          home: WScreenScope(
            widthScaler: (v) => v * 2,
            heightScaler: (v) => v + 3,
            fontScaler: (v) => v * 1.5,
            child: Builder(
              builder: (context) {
                final screen = WScreen.of(context);
                expect(screen.w(10), 20);
                expect(screen.h(10), 13);
                expect(screen.sp(10), 15);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('无 scope 时 WScreen.of 回退到旧 delegate', (tester) async {
      WScreen.delegateWidth = (v) => v * 3;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(WScreen.of(context).w(10), 30);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });

  group('WScreen 设备信息', () {
    testWidgets('screenWidth / screenHeight / statusBarHeight / bottomSafeAreaHeight', (
      tester,
    ) async {
      // 设置测试设备属性（iPhone 14 Pro 逻辑尺寸）
      const logicalSize = Size(393, 852);
      tester.view.physicalSize = logicalSize;
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
      // 确保 MediaQuery 重建
      await tester.pumpWidget(const SizedBox.shrink());

      expect(WScreen.screenWidth, 393);
      expect(WScreen.screenHeight, 852);
      expect(WScreen.statusBarHeight, 59);
      expect(WScreen.bottomSafeAreaHeight, 34);

      // restore — 避免影响后续测试
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewPadding();
      });
    });

    testWidgets('零 padding 时 statusBarHeight 和 bottomSafeAreaHeight 为 0', (tester) async {
      const logicalSize = Size(375, 667);
      tester.view.physicalSize = logicalSize;
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = FakeViewPadding.zero;
      await tester.pumpWidget(const SizedBox.shrink());

      expect(WScreen.statusBarHeight, 0);
      expect(WScreen.bottomSafeAreaHeight, 0);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewPadding();
      });
    });
  });

  group('WScreen.delegate 委托', () {
    testWidgets('无 delegate 时 w/h/sp 返回原始值', (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());

      expect(WScreen.w(100), 100);
      expect(WScreen.h(200), 200);
      expect(WScreen.sp(14), 14);
    });

    testWidgets('注入 delegateWidth 后 w() 走委托', (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      WScreen.delegateWidth = (v) => v * 2;

      expect(WScreen.w(100), 200);
      // h 和 sp 无 delegate，返回原始
      expect(WScreen.h(100), 100);
      expect(WScreen.sp(100), 100);
    });

    testWidgets('注入 delegateHeight 后 h() 走委托', (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      WScreen.delegateHeight = (v) => v + 10;

      expect(WScreen.h(100), 110);
    });

    testWidgets('注入 delegateFont 后 sp() 走委托', (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      WScreen.delegateFont = (v) => v * 1.5;

      expect(WScreen.sp(14), 21);
    });

    testWidgets('delegate 为 null 时走原始值（撤销注入）', (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      WScreen.delegateWidth = (v) => v * 10;
      // 先验证委托生效
      expect(WScreen.w(5), 50);

      // 撤销 delegate
      WScreen.delegateWidth = null;
      expect(WScreen.w(5), 5);
    });

    testWidgets('三个 delegate 可以同时注入', (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      WScreen.delegateWidth = (v) => v * 1.2;
      WScreen.delegateHeight = (v) => v * 1.3;
      WScreen.delegateFont = (v) => v * 1.4;

      expect(WScreen.w(10), 12);
      expect(WScreen.h(10), 13);
      expect(WScreen.sp(10), 14);
    });
  });
  test('reset 恢复默认 delegate', () {
    WScreen.delegateWidth = (v) => v * 2;
    WScreen.delegateHeight = (v) => v * 2;
    WScreen.delegateFont = (v) => v * 2;
    WScreen.reset();
    expect(WScreen.w(10), 10);
    expect(WScreen.h(10), 10);
    expect(WScreen.sp(10), 10);
  });

  test('WAssets.reset 恢复默认前缀', () {
    WAssets.imagePath = 'assets/icons/';
    expect('logo.png'.assetImagePath, 'assets/icons/logo.png');
    WAssets.reset();
    expect(WAssets.imagePath, 'assets/images/');
  });
}
