import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:w_tools_async/w_tools_async.dart';
import 'package:w_tools_async_ui/w_tools_async_ui.dart';

Widget _statusFooter(WAsyncPagedController<int> controller) {
  return CustomFooter(
    builder: (context, _) => ValueListenableBuilder<WAsyncPagedSnapshot<int>>(
      valueListenable: controller.snapshot,
      builder: (context, snapshot, _) => Text('footer ${snapshot.footerStatus.name}'),
    ),
  );
}

void main() {
  testWidgets('WAsyncPagedList 渲染分页数据', (tester) async {
    final controller = WAsyncPagedController<int>(
      (page, _) async => WAsyncPage<int>(
        items: page == 1 ? const <int>[1, 2] : const <int>[],
        hasMore: page == 1,
      ),
    );
    addTearDown(controller.dispose);
    await controller.refresh();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WAsyncPagedList<int>(
            controller: controller,
            itemBuilder: (context, item) => Text('item $item'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('item 1'), findsOneWidget);
    expect(find.text('item 2'), findsOneWidget);
  });

  testWidgets('WAsyncPagedList 转发自定义 header / footer', (tester) async {
    final controller = WAsyncPagedController<int>(
      (page, _) async => const WAsyncPage<int>(items: <int>[1], hasMore: true),
    );
    addTearDown(controller.dispose);
    await controller.refresh();

    final header = CustomHeader(
      builder: (context, _) => const Text('custom header'),
    );
    final footer = CustomFooter(
      builder: (context, _) => const Text('custom footer'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WAsyncPagedList<int>(
            controller: controller,
            itemBuilder: (context, item) => Text('item $item'),
            header: header,
            footer: footer,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final refresher = tester.widget<SmartRefresher>(find.byType(SmartRefresher));
    expect(refresher.header, same(header));
    expect(refresher.footer, same(footer));
  });

  testWidgets('app footer 可以监听 snapshot 并处理 noMore / failed', (tester) async {
    var pageTwoCalls = 0;
    final controller = WAsyncPagedController<int>((page, _) async {
      if (page == 1) return const WAsyncPage<int>(items: <int>[1], hasMore: true);
      pageTwoCalls++;
      if (pageTwoCalls == 1) throw StateError('load more failed');
      return const WAsyncPage<int>(items: <int>[2], hasMore: false);
    });
    addTearDown(controller.dispose);
    await controller.refresh();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WAsyncPagedList<int>(
            controller: controller,
            itemBuilder: (context, item) => Text('item $item'),
            footer: _statusFooter(controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('footer loadMore'), findsOneWidget);

    await controller.loadMore();
    await tester.pumpAndSettle();
    expect(find.text('footer failed'), findsOneWidget);
    expect(find.text('item 1'), findsOneWidget);

    await controller.loadMore();
    await tester.pumpAndSettle();
    expect(find.text('item 2'), findsOneWidget);
    expect(find.text('footer noMore'), findsOneWidget);
  });

  testWidgets('WAsyncPagedList 不自动 refresh', (tester) async {
    var calls = 0;
    final controller = WAsyncPagedController<int>((page, _) async {
      calls++;
      return const WAsyncPage<int>(items: <int>[1], hasMore: false);
    });
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WAsyncPagedList<int>(
            controller: controller,
            itemBuilder: (context, item) => Text('item $item'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(calls, 0);
  });

  testWidgets('refresh 失败显示错误，点击重试恢复', (tester) async {
    var calls = 0;
    final controller = WAsyncPagedController<int>((page, _) async {
      calls++;
      if (calls == 1) throw StateError('refresh failed');
      return const WAsyncPage<int>(items: <int>[1], hasMore: false);
    });
    addTearDown(controller.dispose);
    await controller.refresh();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WAsyncPagedList<int>(
            controller: controller,
            itemBuilder: (context, item) => Text('item $item'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('item 1'), findsOneWidget);
    expect(calls, 2);
  });
}
