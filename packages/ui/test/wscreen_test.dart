import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
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
    testWidgets('scope 注入 w/h/sp', (tester) async {
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

    testWidgets('无 scope 时 w/h/sp 是恒等函数', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final screen = WScreen.of(context);
              expect(screen.w(10), 10);
              expect(screen.h(10), 10);
              expect(screen.sp(10), 10);
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

  test('WAssets.reset 恢复默认前缀', () {
    WAssets.imagePath = 'assets/icons/';
    expect('logo.png'.assetImagePath, 'assets/icons/logo.png');
    WAssets.reset();
    expect(WAssets.imagePath, 'assets/images/');
  });
}
