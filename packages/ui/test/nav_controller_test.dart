import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  group('WNavController — 构造 + getter', () {
    testWidgets('initialIndex 默认 0', (tester) async {
      final ctrl = WNavController(
        length: 3,
        vsync: tester,
      );
      expect(ctrl.currentIndex, 0);
      expect(ctrl.previousIndex, 0);
      expect(ctrl.length, 3);
      expect(ctrl.animation, isA<Animation<double>>());
      expect(ctrl.offset, 0.0);
      expect(ctrl.indexIsChanging, false);
      ctrl.dispose();
    });

    testWidgets('initialIndex 自定义', (tester) async {
      final ctrl = WNavController(
        initialIndex: 1,
        length: 4,
        vsync: tester,
      );
      expect(ctrl.currentIndex, 1);
      expect(ctrl.previousIndex, 1);
      ctrl.dispose();
    });
  });

  group('WNavController — currentIndex setter', () {
    testWidgets('setter 触发状态切换 + notifyListeners', (tester) async {
      int listenerCount = 0;
      final ctrl = WNavController(length: 3, vsync: tester);
      ctrl.addListener(() => listenerCount++);

      ctrl.currentIndex = 2;
      expect(ctrl.currentIndex, 2);
      expect(ctrl.previousIndex, 0);
      expect(listenerCount, 1);

      // 相同值不触发
      ctrl.currentIndex = 2;
      expect(listenerCount, 1);

      ctrl.dispose();
    });

    testWidgets('setter 打断进行中的动画', (tester) async {
      final ctrl = WNavController(length: 3, vsync: tester);
      addTearDown(ctrl.dispose);

      final transition = ctrl.animateTo(1);
      ctrl.currentIndex = 2;
      expect(ctrl.currentIndex, 2);
      expect(ctrl.offset, 0);
      await tester.pumpAndSettle();
      await transition;
      expect(tester.takeException(), isNull);
    });

    testWidgets('out of range 值被拒绝', (tester) async {
      int listenerCount = 0;
      final ctrl = WNavController(length: 3, vsync: tester);
      ctrl.addListener(() => listenerCount++);

      // 负数
      ctrl.currentIndex = -1;
      expect(ctrl.currentIndex, 0); // 不变
      expect(listenerCount, 0);

      // >= length
      ctrl.currentIndex = 5;
      expect(ctrl.currentIndex, 0);
      expect(listenerCount, 0);

      ctrl.dispose();
    });
  });

  group('WNavController — dispose', () {
    testWidgets('dispose 后 setter 安全返回', (tester) async {
      final ctrl = WNavController(length: 3, vsync: tester);
      ctrl.dispose();

      expect(() => ctrl.currentIndex = 1, returnsNormally);
      expect(ctrl.currentIndex, 0);
    });
  });

  group('WNavController — animateTo', () {
    testWidgets('应用传入的 curve', (tester) async {
      final ctrl = WNavController(length: 3, vsync: tester);
      addTearDown(ctrl.dispose);

      final future = ctrl.animateTo(1, curve: Curves.linear);
      expect((ctrl.animation as CurvedAnimation).curve, Curves.linear);

      await tester.pumpAndSettle();
      await future;
    });
  });

  group('WNavBar — controller 生命周期', () {
    Widget buildNav(WNavController controller) => MaterialApp(
      home: Scaffold(
        body: WNavBar(
          style: const WNavBarStyle(),
          controller: controller,
          itemBuilder: (_, i, selected) => Text('item-$i'),
        ),
      ),
    );

    testWidgets('卸载后不释放外部 controller', (tester) async {
      final controller = WNavController(length: 2, vsync: tester);
      addTearDown(controller.dispose);

      await tester.pumpWidget(buildNav(controller));
      await tester.pumpWidget(const SizedBox());

      // 旧实现会在组件 dispose 时释放 controller，这里会抛 FlutterError
      controller.currentIndex = 1;
      expect(controller.currentIndex, 1);
    });

    testWidgets('替换 controller 后监听迁移到新实例', (tester) async {
      final first = WNavController(length: 2, vsync: tester);
      final second = WNavController(length: 2, vsync: tester);
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      await tester.pumpWidget(buildNav(first));
      await tester.pumpWidget(buildNav(second));

      await tester.tap(find.text('item-1'));
      await tester.pumpAndSettle();

      expect(second.currentIndex, 1);
      expect(first.currentIndex, 0);
    });
  });

  group('WNavController — hardening', () {
    testWidgets('非法 initialIndex 触发 assert', (tester) async {
      expect(
        () => WNavController(initialIndex: 3, length: 3, vsync: tester),
        throwsAssertionError,
      );
    });

    testWidgets('连续 animateTo 后以最后一次为准', (tester) async {
      final ctrl = WNavController(length: 3, vsync: tester);
      addTearDown(ctrl.dispose);

      final first = ctrl.animateTo(1);
      final second = ctrl.animateTo(2);
      await tester.pumpAndSettle();
      await Future.wait([first, second]);

      expect(ctrl.currentIndex, 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dispose 后 animateTo 安全返回', (tester) async {
      final ctrl = WNavController(length: 3, vsync: tester);
      final future = ctrl.animateTo(1);
      ctrl.dispose();
      await tester.pump();
      await future;
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('WNavBar 暴露 button / selected 语义', (tester) async {
    final controller = WNavController(length: 2, vsync: tester);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WNavBar(
            style: const WNavBarStyle(),
            controller: controller,
            itemBuilder: (_, index, selected) => Text('item-$index'),
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.button == true &&
            widget.properties.selected == true,
      ),
      findsOneWidget,
    );
  });

  testWidgets('WNavBar 异步回调乱序时以最后一次点击为准', (tester) async {
    final controller = WNavController(length: 3, vsync: tester);
    addTearDown(controller.dispose);
    final firstTap = Completer<bool?>();
    final secondTap = Completer<bool?>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WNavBar(
            style: const WNavBarStyle(),
            controller: controller,
            onItemTap: (index) => index == 1 ? firstTap.future : secondTap.future,
            itemBuilder: (_, index, selected) => Text('item-$index'),
          ),
        ),
      ),
    );

    // 先点 item-1（慢），再点 item-2（快）；第二次回调先返回。
    await tester.tap(find.text('item-1'));
    await tester.pump();
    await tester.tap(find.text('item-2'));
    await tester.pump();

    secondTap.complete(true);
    await tester.pump();
    firstTap.complete(true);
    await tester.pumpAndSettle();

    expect(controller.currentIndex, 2, reason: '最后一次点击应赢');
  });

  testWidgets('WNavBar onItemTap 返回 false 时阻止切换', (tester) async {
    final controller = WNavController(length: 2, vsync: tester);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WNavBar(
            style: const WNavBarStyle(),
            controller: controller,
            onItemTap: (index) async => false,
            itemBuilder: (_, index, selected) => Text('item-$index'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('item-1'));
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 0);
  });

  testWidgets('WNavBar 默认避开底部安全区', (tester) async {
    final ctrl = WNavController(length: 2, vsync: tester);
    addTearDown(ctrl.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(bottom: 34),
            ),
            child: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: WNavBar(
                  controller: ctrl,
                  itemBuilder: (context, index, selected) => SizedBox(
                    key: Key('nav-item-$index'),
                    width: 10,
                    height: 10,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final item = tester.getRect(find.byKey(const Key('nav-item-0')));
    expect(item.bottom, closeTo(566, 0.1));
  });

  testWidgets('WNavBar safeArea: false 时贴底', (tester) async {
    final ctrl = WNavController(length: 2, vsync: tester);
    addTearDown(ctrl.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(bottom: 34),
            ),
            child: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: WNavBar(
                  controller: ctrl,
                  safeArea: false,
                  itemBuilder: (context, index, selected) => SizedBox(
                    key: Key('nav-item-$index'),
                    width: 10,
                    height: 10,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final item = tester.getRect(find.byKey(const Key('nav-item-0')));
    expect(item.bottom, closeTo(600, 0.1));
  });

  testWidgets('WNavBar 直接传 style', (tester) async {
    final ctrl = WNavController(length: 2, vsync: tester);
    addTearDown(ctrl.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: WNavBar(
            controller: ctrl,
            style: const WNavBarStyle(
              decoration: BoxDecoration(color: Colors.white),
              padding: EdgeInsets.all(4),
            ),
            itemBuilder: (context, index, selected) => Text('$index'),
          ),
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.descendant(of: find.byType(WNavBar), matching: find.byType(Container)),
    );
    expect(container.decoration, const BoxDecoration(color: Colors.white));
    expect(container.padding, const EdgeInsets.all(4));
  });
}
