import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';
import 'package:w_tools_async_ui/w_tools_async_ui.dart';

void main() {
  testWidgets('WAsyncPagedSliver 在 CustomScrollView 中渲染数据', (tester) async {
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
          body: CustomScrollView(
            slivers: [
              WAsyncPagedSliver<int>(
                controller: controller,
                itemBuilder: (context, item) => Text('item $item'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('item 1'), findsOneWidget);
    expect(find.text('item 2'), findsOneWidget);
    // WAsyncPagedSliver 不再包含 footer；footer 由调用方的滚动壳负责。
    expect(find.text('Pull up to load more'), findsNothing);
  });

  testWidgets('WAsyncPagedSliver 空态使用 emptyBuilder', (tester) async {
    final controller = WAsyncPagedController<int>(
      (page, _) async => const WAsyncPage<int>(items: <int>[], hasMore: false),
    );
    addTearDown(controller.dispose);
    await controller.refresh();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              WAsyncPagedSliver<int>(
                controller: controller,
                emptyBuilder: (context) => const Text('custom empty'),
                itemBuilder: (context, item) => Text('item $item'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('custom empty'), findsOneWidget);
  });

  testWidgets('WAsyncPagedSliver 支持 readySliverBuilder', (tester) async {
    final controller = WAsyncPagedController<int>(
      (page, _) async => const WAsyncPage<int>(items: <int>[1], hasMore: false),
    );
    addTearDown(controller.dispose);
    await controller.refresh();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              WAsyncPagedSliver<int>.custom(
                controller: controller,
                readySliverBuilder: (context, items) => SliverToBoxAdapter(
                  child: Text('custom ready ${items.length}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('custom ready 1'), findsOneWidget);
  });

  testWidgets('WAsyncPagedSliver 自定义 onRetry 覆盖 controller.refresh', (tester) async {
    var loadCalls = 0;
    var retryCalls = 0;
    final controller = WAsyncPagedController<int>((page, _) async {
      loadCalls++;
      throw StateError('boom');
    });
    addTearDown(controller.dispose);
    await controller.refresh();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              WAsyncPagedSliver<int>(
                controller: controller,
                itemBuilder: (context, item) => Text('item $item'),
                onRetry: () => retryCalls++,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(retryCalls, 1);
    expect(loadCalls, 1);
  });
}
