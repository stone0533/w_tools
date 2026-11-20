import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';
import 'package:w_tools_async_ui/w_tools_async_ui.dart';

/// `reloadRequests` 的回归测试（async_ui 2.1.1 修的两个问题）：
/// 1. 一次信号只刷一次首页 —— 2.1.0 及以前会出现 1 秒兜底与 RefreshIndicator
///    回调各刷一次，pump 粒度决定能否复现（pump(300ms)+pump(1s) 必现）；
/// 2. 刷新在飞期间不发 loadMore —— 以前会先发一次旧页码的请求，再被 refresh 取消。
void main() {
  Widget app(
    WAsyncPagedController<int> controller,
    ValueNotifier<int> reload, {
    double? autoLoadThreshold,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: WAsyncPagedList<int>(
          controller: controller,
          reloadRequests: reload,
          autoLoadThreshold: autoLoadThreshold,
          itemBuilder: (context, item) => SizedBox(height: 40, child: Text('item $item')),
        ),
      ),
    );
  }

  testWidgets('一次 reloadRequests 递增只刷一次首页', (tester) async {
    final pages = <int>[];
    final controller = WAsyncPagedController<int>((page, _) async {
      pages.add(page);
      return WAsyncPage<int>(
        items: List<int>.generate(30, (i) => page * 100 + i),
        hasMore: page < 3,
      );
    });
    addTearDown(controller.dispose);
    final reload = ValueNotifier<int>(0);
    addTearDown(reload.dispose);

    await controller.refresh();
    await tester.pumpWidget(app(controller, reload, autoLoadThreshold: null));
    await tester.pumpAndSettle();

    pages.clear();
    reload.value++;
    // 这个粒度是 2.1.0 的必现写法：第二次 pump 跨过 1 秒兜底
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));

    expect(pages, <int>[1], reason: '只递增一次信号，不应发两次首页请求');
    expect(tester.takeException(), isNull);
  });

  testWidgets('刷新在飞期间不触发自动加载', (tester) async {
    final pages = <int>[];
    final firstPage = Completer<void>();
    var holdFirstPage = false;
    final controller = WAsyncPagedController<int>((page, _) async {
      pages.add(page);
      if (page == 1 && holdFirstPage) {
        await firstPage.future;
      }
      return WAsyncPage<int>(
        items: List<int>.generate(2, (i) => page * 100 + i),
        hasMore: true,
      );
    });
    addTearDown(controller.dispose);
    final reload = ValueNotifier<int>(0);
    addTearDown(reload.dispose);

    await controller.refresh();
    // 内容很短 + 开启自动加载，正常会连续 loadMore
    await tester.pumpWidget(app(controller, reload));
    await tester.pumpAndSettle();

    holdFirstPage = true;
    pages.clear();
    reload.value++;
    await tester.pump(const Duration(milliseconds: 300));

    expect(pages, <int>[1], reason: '刷新期间不应先发 loadMore 的旧页码请求');

    firstPage.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
