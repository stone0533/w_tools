import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_toast/w_tools_toast.dart';

/// 下层页面铺一个全屏按钮：用来验证遮罩是否把点击透传下去。
Widget _app({required VoidCallback onUnderlayTap}) {
  return MaterialApp(
    builder: BotToastInit(),
    navigatorObservers: [BotToastNavigatorObserver()],
    home: Scaffold(
      body: SizedBox.expand(
        child: TextButton(onPressed: onUnderlayTap, child: const Text('underlay')),
      ),
    ),
  );
}

/// 遮罩之外的空白点（避开居中的 modal 内容）。
const Offset _barrierPoint = Offset(20, 20);

void main() {
  test('BotToast 未初始化时 showModal 不抛异常，回调 onError 并返回可调用函数', () {
    Object? error;
    final cancel = WToast.showModal(
      builder: (c) => const SizedBox.shrink(),
      onError: (e) => error = e,
    );
    expect(error, isNotNull);
    expect(cancel, isNotNull);
    cancel();
  });

  testWidgets('showModal 点遮罩即关闭并触发 onClose', (tester) async {
    await tester.pumpWidget(_app(onUnderlayTap: () {}));
    var closed = false;

    WToast.showModal(
      builder: (cancel) => const Text('modal'),
      onClose: () => closed = true,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('modal'), findsOneWidget);

    await tester.tapAt(_barrierPoint);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('modal'), findsNothing);
    expect(closed, isTrue);
  });

  testWidgets('showModal 拦截穿透：遮罩打开时点下层不触发', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_app(onUnderlayTap: () => taps++));

    WToast.showModal(builder: (cancel) => const Text('modal'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tapAt(_barrierPoint);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 20));

    expect(taps, 0, reason: '遮罩必须拦截点击，不能穿透到下层');
  });

  testWidgets('showModal barrierDismissible: false 时点遮罩不关闭', (tester) async {
    await tester.pumpWidget(_app(onUnderlayTap: () {}));

    WToast.showModal(
      builder: (cancel) => const Text('modal'),
      barrierDismissible: false,
      duration: null,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tapAt(_barrierPoint);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('modal'), findsOneWidget);

    WToast.hideAll();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 20));
  });

  testWidgets('showModal 默认 duration 到期后自动关闭', (tester) async {
    await tester.pumpWidget(_app(onUnderlayTap: () {}));

    WToast.showModal(
      builder: (cancel) => const Text('modal'),
      duration: const Duration(milliseconds: 100),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('modal'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('modal'), findsNothing);
  });
}
