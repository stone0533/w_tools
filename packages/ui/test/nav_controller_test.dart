import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  group('WNavController — 构造 + getter', () {
    test('initialIndex 默认 0', () {
      final ctrl = WNavController(length: 3);
      addTearDown(ctrl.dispose);
      expect(ctrl.currentIndex, 0);
      expect(ctrl.length, 3);
    });

    test('initialIndex 自定义', () {
      final ctrl = WNavController(initialIndex: 1, length: 4);
      addTearDown(ctrl.dispose);
      expect(ctrl.currentIndex, 1);
    });

    test('非法 initialIndex 触发 assert', () {
      expect(
        () => WNavController(initialIndex: 3, length: 3),
        throwsAssertionError,
      );
    });
  });

  group('WNavController — currentIndex setter', () {
    test('setter 触发状态切换 + notifyListeners', () {
      int listenerCount = 0;
      final ctrl = WNavController(length: 3);
      addTearDown(ctrl.dispose);
      ctrl.addListener(() => listenerCount++);

      ctrl.currentIndex = 2;
      expect(ctrl.currentIndex, 2);
      expect(listenerCount, 1);

      // 相同值不触发
      ctrl.currentIndex = 2;
      expect(listenerCount, 1);
    });

    test('out of range 值被拒绝', () {
      int listenerCount = 0;
      final ctrl = WNavController(length: 3);
      addTearDown(ctrl.dispose);
      ctrl.addListener(() => listenerCount++);

      ctrl.currentIndex = -1;
      expect(ctrl.currentIndex, 0);
      expect(listenerCount, 0);

      ctrl.currentIndex = 5;
      expect(ctrl.currentIndex, 0);
      expect(listenerCount, 0);
    });
  });

  group('WNavBar — controller 生命周期', () {
    Widget buildNav(WNavController controller) => MaterialApp(
      home: Scaffold(
        body: WNavBar(
          decoration: const BoxDecoration(),
          controller: controller,
          itemBuilder: (_, i, selected) => Text('item-$i'),
        ),
      ),
    );

    testWidgets('卸载后不释放外部 controller', (tester) async {
      final controller = WNavController(length: 2);
      addTearDown(controller.dispose);

      await tester.pumpWidget(buildNav(controller));
      await tester.pumpWidget(const SizedBox());

      controller.currentIndex = 1;
      expect(controller.currentIndex, 1);
    });

    testWidgets('替换 controller 后监听迁移到新实例', (tester) async {
      final first = WNavController(length: 2);
      final second = WNavController(length: 2);
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

  testWidgets('WNavBar 暴露 button / selected 语义', (tester) async {
    final controller = WNavController(length: 2);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WNavBar(
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

  testWidgets('WNavBar onBeforeTap 异步乱序时以最后一次点击为准', (tester) async {
    final controller = WNavController(length: 3);
    addTearDown(controller.dispose);
    final firstTap = Completer<bool>();
    final secondTap = Completer<bool>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WNavBar(
            controller: controller,
            onBeforeTap: (index) => index == 1 ? firstTap.future : secondTap.future,
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

  testWidgets('WNavBar onBeforeTap 返回 false 时阻止切换', (tester) async {
    final controller = WNavController(length: 2);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WNavBar(
            controller: controller,
            onBeforeTap: (index) async => false,
            itemBuilder: (_, index, selected) => Text('item-$index'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('item-1'));
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 0);
  });

  testWidgets('WNavBar destinations 渲染默认图标 / 文字', (tester) async {
    final controller = WNavController(length: 2);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WNavBar(
            controller: controller,
            destinations: const [
              WNavDestination(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: '首页',
              ),
              WNavDestination(icon: Icons.person_outline, label: '我的'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('首页'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsNothing);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('WNavBar itemBuilder 与 destinations 互斥', (tester) async {
    final controller = WNavController(length: 1);
    addTearDown(controller.dispose);

    expect(
      () => WNavBar(
        controller: controller,
        itemBuilder: (context, index, selected) => const SizedBox(),
        destinations: const [WNavDestination(icon: Icons.home, label: '首页')],
      ),
      throwsAssertionError,
    );
    expect(
      () => WNavBar(controller: controller),
      throwsAssertionError,
    );
  });

  testWidgets('WNavBar 默认避开底部安全区', (tester) async {
    final ctrl = WNavController(length: 2);
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
    final ctrl = WNavController(length: 2);
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

  testWidgets('WNavBar 直接传 decoration / padding', (tester) async {
    final ctrl = WNavController(length: 2);
    addTearDown(ctrl.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: WNavBar(
            controller: ctrl,
            decoration: const BoxDecoration(color: Colors.white),
            padding: const EdgeInsets.all(4),
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
