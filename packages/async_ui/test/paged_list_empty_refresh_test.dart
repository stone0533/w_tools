import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';
import 'package:w_tools_async_ui/w_tools_async_ui.dart';

/// 刷新提示只允许出现一个（async_ui 2.3.1 / issue #422）：
///
/// 没有内容可保留时（首屏未回 / 空结果 / 首屏失败），`WAsyncStateSliver` 会渲染
/// 居中 loading；此时不能再让 `RefreshIndicator` 叠一个下拉圈，否则用户会看到
/// 两个加载提示 —— 程序化 `reloadRequests` 和空态手动下拉两条路径都覆盖。
void main() {
  /// 屏幕上的加载指示器总数。
  ///
  /// `RefreshProgressIndicator` 是 `CircularProgressIndicator` 的子类，但
  /// `find.byType` 按运行时类型精确匹配，所以两个都要数。
  int indicators() =>
      find.byType(CircularProgressIndicator).evaluate().length +
      find.byType(RefreshProgressIndicator).evaluate().length;

  Widget app(WAsyncPagedController<String> controller, {ValueNotifier<int>? reload}) {
    return MaterialApp(
      home: Scaffold(
        body: WAsyncPagedList<String>(
          controller: controller,
          reloadRequests: reload,
          autoLoadThreshold: null,
          itemBuilder: (context, item) => SizedBox(height: 40, child: Text(item)),
        ),
      ),
    );
  }

  /// 第一页返回空列表；[hold] 打开后第二页请求挂起，方便观察 loading 态。
  WAsyncPagedController<String> emptyController(Completer<void> gate, ValueGetter<bool> hold) {
    return WAsyncPagedController<String>((page, _) async {
      if (hold()) await gate.future;
      return const WAsyncPage<String>(items: <String>[], hasMore: false);
    });
  }

  testWidgets('空态 reloadRequests 只显示居中 loading，不叠下拉圈', (tester) async {
    final gate = Completer<void>();
    var hold = false;
    final controller = emptyController(gate, () => hold);
    addTearDown(controller.dispose);
    final reload = ValueNotifier<int>(0);
    addTearDown(reload.dispose);

    await controller.refresh();
    await tester.pumpWidget(app(controller, reload: reload));
    await tester.pumpAndSettle();
    expect(indicators(), 0, reason: '空态本身没有加载提示');

    hold = true;
    reload.value++;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(RefreshProgressIndicator), findsNothing, reason: '没有内容时不该再叠下拉圈');
    expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: '居中 loading 是唯一反馈');
    expect(indicators(), 1);

    gate.complete();
    await tester.pumpAndSettle();
    expect(indicators(), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('空态手动下拉：下拉头收尾后只剩居中 loading', (tester) async {
    final gate = Completer<void>();
    var hold = false;
    final controller = emptyController(gate, () => hold);
    addTearDown(controller.dispose);

    await controller.refresh();
    await tester.pumpWidget(app(controller));
    await tester.pumpAndSettle();

    hold = true;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 320));
    await tester.pump();
    // 下拉头分 snap / dismiss 两段回弹，要分帧 pump 才走完；此时刷新请求
    // 还挂着，圈只应剩居中那个。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(RefreshProgressIndicator), findsNothing, reason: '下拉头应在数据回来前收尾');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(indicators(), 1);

    gate.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('有内容时 reloadRequests 仍然复用下拉圈（不显示居中 loading）', (tester) async {
    final gate = Completer<void>();
    var hold = false;
    final controller = WAsyncPagedController<String>((page, _) async {
      if (hold) await gate.future;
      return const WAsyncPage<String>(items: <String>['a', 'b'], hasMore: false);
    });
    addTearDown(controller.dispose);
    final reload = ValueNotifier<int>(0);
    addTearDown(reload.dispose);

    await controller.refresh();
    await tester.pumpWidget(app(controller, reload: reload));
    await tester.pumpAndSettle();

    hold = true;
    reload.value++;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(RefreshProgressIndicator), findsOneWidget, reason: '有内容时下拉圈负责反馈');
    expect(find.byType(CircularProgressIndicator), findsNothing, reason: '有内容时保留列表，不显示居中 loading');
    expect(indicators(), 1);

    gate.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
