import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  final position = RelativeRect.fromRect(
    const Rect.fromLTWH(0, 100, 200, 50),
    const Rect.fromLTWH(0, 0, 400, 800),
  );

  group('WFormPopupRoute — 构造 + getter', () {
    test('默认值', () {
      final route = WFormPopupRoute<void>(
        builder: (_) => const SizedBox.shrink(),
        position: position,
        barrierLabel: 'dismiss',
      );

      expect(route.position, position);
      expect(route.barrierLabel, 'dismiss');
      expect(route.elevation, isNull);
      expect(route.shadowColor, isNull);
      expect(route.barrierColor, isNull);
      expect(route.barrierDismissible, true);
      expect(route.transitionDuration, const Duration(milliseconds: 200));
      expect(route.traversalEdgeBehavior, TraversalEdgeBehavior.closedLoop);
      expect(route.settings.name, isNull);
    });

    test('自定义 elevation / shadowColor / duration', () {
      final route = WFormPopupRoute<void>(
        builder: (_) => const SizedBox.shrink(),
        position: position,
        barrierLabel: 'label',
        elevation: 8,
        shadowColor: Colors.black54,
        animationDuration: const Duration(milliseconds: 350),
      );

      expect(route.elevation, 8);
      expect(route.shadowColor, Colors.black54);
      expect(route.transitionDuration, const Duration(milliseconds: 350));
    });

    test('animationDuration null → 用默认 200ms', () {
      final route = WFormPopupRoute<void>(
        builder: (_) => const SizedBox.shrink(),
        position: position,
        barrierLabel: 'label',
        // animationDuration 未指定 → 默认 200ms
      );
      expect(route.transitionDuration, const Duration(milliseconds: 200));
    });

    test('builder — 非 null 且可调用返回 Widget', () {
      final route = WFormPopupRoute<void>(
        builder: (_) => const Text('popup-content'),
        position: position,
        barrierLabel: 'dismiss',
      );

      // builder 签名 WidgetBuilder = Widget Function(BuildContext)
      // 不传参数直接检查 builder 类型
      expect(route.builder, isNotNull);
      // 不能实际调用 builder（需要 context），但类型已正确
      expect(route.builder, isA<WidgetBuilder>());
    });

    test('继承自 PopupRoute + Route', () {
      final route = WFormPopupRoute<void>(
        builder: (_) => const SizedBox.shrink(),
        position: position,
        barrierLabel: 'dismiss',
      );
      expect(route, isA<PopupRoute<void>>());
      expect(route, isA<Route<void>>());
    });

    test('泛型参数 <String>', () {
      final route = WFormPopupRoute<String>(
        builder: (_) => const SizedBox.shrink(),
        position: position,
        barrierLabel: 'dismiss',
      );
      expect(route, isA<WFormPopupRoute<String>>());
      expect(route, isA<PopupRoute<String>>());
    });

    test('自定义 position 可独立实例化', () {
      final p1 = RelativeRect.fromRect(
        const Rect.fromLTWH(10, 20, 100, 30),
        const Rect.fromLTWH(0, 0, 500, 900),
      );
      final p2 = RelativeRect.fromRect(
        const Rect.fromLTWH(200, 500, 100, 30),
        const Rect.fromLTWH(0, 0, 500, 900),
      );

      final r1 = WFormPopupRoute<void>(
        builder: (_) => const SizedBox.shrink(),
        position: p1,
        barrierLabel: 'a',
      );
      final r2 = WFormPopupRoute<void>(
        builder: (_) => const SizedBox.shrink(),
        position: p2,
        barrierLabel: 'b',
      );

      expect(r1.position, isNot(r2.position));
      expect(r1.barrierLabel, 'a');
      expect(r2.barrierLabel, 'b');
    });

    test('自定义 settings / width / 外观参数', () {
      final route = WFormPopupRoute<void>(
        builder: (_) => const SizedBox.shrink(),
        position: position,
        barrierLabel: 'label',
        width: 240,
        backgroundColor: Colors.white,
        borderRadius: BorderRadius.circular(8),
        settings: const RouteSettings(name: 'test-popup'),
      );

      expect(route.width, 240);
      expect(route.backgroundColor, Colors.white);
      expect(route.borderRadius, BorderRadius.circular(8));
      expect(route.settings.name, 'test-popup');
    });
  });

  group('WFormPopupRoute — transitionDuration 覆盖', () {
    test('PopupRoute 默认 transitionDuration 会被覆盖', () {
      // PopupRoute 默认 transitionDuration 较短，WFormPopupRoute 覆盖为 animationDuration
      final route = WFormPopupRoute<void>(
        builder: (_) => const SizedBox.shrink(),
        position: position,
        barrierLabel: 'dismiss',
        animationDuration: const Duration(milliseconds: 500),
      );
      // 验证 override getter 正确返回 animationDuration
      expect(route.transitionDuration, const Duration(milliseconds: 500));
    });

    test('reverseTransitionDuration 由 PopupRoute 基类决定', () {
      final route = WFormPopupRoute<void>(
        builder: (_) => const SizedBox.shrink(),
        position: position,
        barrierLabel: 'dismiss',
      );
      // PopupRoute.reverseTransitionDuration 默认等于 transitionDuration
      // 但 WFormPopupRoute 没 override reverseTransitionDuration
      // 所以这里只是验证 getter 存在且可访问
      expect(route.reverseTransitionDuration, isA<Duration>());
    });
  });

  group('WFormPopup — 布局边界', () {
    testWidgets('锚点靠近底部 → 向上翻转且不抛异常', (tester) async {
      tester.view.physicalSize = const Size(400, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const popupKey = Key('popup-content');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () => WFormPopup.show(
                    context: context,
                    builder: (_) => const SizedBox(
                      key: popupKey,
                      width: 100,
                      height: 200,
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byKey(popupKey), findsOneWidget);
      expect(tester.takeException(), isNull);

      final popupRect = tester.getRect(find.byKey(popupKey));
      final anchorRect = tester.getRect(find.byType(TextButton));
      expect(popupRect.bottom, lessThanOrEqualTo(anchorRect.top + 0.5));
    });

    testWidgets('极小视口 → 不抛 BoxConstraints 负数断言', (tester) async {
      tester.view.physicalSize = const Size(120, 80);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => WFormPopup.show(
                  context: context,
                  builder: (_) => const SizedBox(
                    height: 400,
                    child: Text('tiny-popup'),
                  ),
                ),
                child: const SizedBox.expand(child: Center(child: Text('open'))),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('show 返回关闭时回传的结果', (tester) async {
      String? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await WFormPopup.show<String>(
                    context: context,
                    builder: (popupContext) => TextButton(
                      onPressed: () => WFormPopup.hide(popupContext, 'ok'),
                      child: const Text('close'),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('close'));
      await tester.pumpAndSettle();

      expect(result, 'ok');
    });

    testWidgets('同一 Navigator 重复 show 只保留一个弹层', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  WFormPopup.show(
                    context: context,
                    builder: (_) => const Text('popup-A'),
                  );
                  WFormPopup.show(
                    context: context,
                    builder: (_) => const Text('popup-B'),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('popup-A'), findsOneWidget);
      expect(find.text('popup-B'), findsNothing);
    });

    testWidgets('width 参数覆盖锚点宽度', (tester) async {
      const popupKey = Key('width-popup');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: Builder(
                builder: (context) => SizedBox(
                  width: 100,
                  child: TextButton(
                    onPressed: () => WFormPopup.show(
                      context: context,
                      width: 240,
                      builder: (_) => const SizedBox(
                        key: popupKey,
                        width: double.infinity,
                        height: 50,
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byKey(popupKey)).width, 240);
    });

    testWidgets('未指定 width 时与锚点同宽', (tester) async {
      const popupKey = Key('anchor-width-popup');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: Builder(
                builder: (context) => SizedBox(
                  width: 100,
                  child: TextButton(
                    onPressed: () => WFormPopup.show(
                      context: context,
                      builder: (_) => const SizedBox(key: popupKey, height: 50),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byKey(popupKey)).width, 100);
    });

    testWidgets('键盘弹起时压缩下方空间并向上翻转', (tester) async {
      tester.view.physicalSize = const Size(400, 300);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: 120);
      addTearDown(tester.view.reset);

      const popupKey = Key('keyboard-popup');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const SizedBox(height: 100),
                Builder(
                  builder: (context) => TextButton(
                    onPressed: () => WFormPopup.show(
                      context: context,
                      builder: (_) => const SizedBox(
                        key: popupKey,
                        width: 100,
                        height: 100,
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final popupRect = tester.getRect(find.byKey(popupKey));
      final anchorRect = tester.getRect(find.byType(TextButton));
      expect(popupRect.bottom, lessThanOrEqualTo(anchorRect.top + 0.5));
    });
  });
}
