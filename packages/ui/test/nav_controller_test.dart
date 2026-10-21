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
    testWidgets('dispose 后再访问 setter 抛 FlutterError', (tester) async {
      final ctrl = WNavController(length: 3, vsync: tester);
      ctrl.dispose();

      // dispose 后 ChangeNotifier.mounted = false
      // setter 内部调 notifyListeners() → 抛 "not active"
      expect(() => ctrl.currentIndex = 1, throwsFlutterError);
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
          config: WNavBarConfig(),
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
}
