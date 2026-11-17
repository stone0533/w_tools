import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';
import 'package:w_tools_async_ui/w_tools_async_ui.dart';

void main() {
  testWidgets('WAsyncPagedList 渲染分页数据并显示 footer', (tester) async {
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
    expect(find.text('Pull up to load more'), findsOneWidget);
  });

  testWidgets('loadMore 到底后显示 noMore', (tester) async {
    final controller = WAsyncPagedController<int>(
      (page, _) async => WAsyncPage<int>(
        items: page == 1 ? const <int>[1] : const <int>[2],
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
    await controller.loadMore();
    await tester.pumpAndSettle();

    expect(find.text('No more data'), findsOneWidget);
  });

  testWidgets('loadMore 失败只显示 footer failed', (tester) async {
    final controller = WAsyncPagedController<int>((page, _) async {
      if (page == 1) return const WAsyncPage<int>(items: <int>[1], hasMore: true);
      throw StateError('load more failed');
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
    await controller.loadMore();
    await tester.pumpAndSettle();

    expect(find.text('Load failed · Retry'), findsOneWidget);
    expect(find.text('item 1'), findsOneWidget);
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
