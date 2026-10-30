import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

Widget _scroll(WAsyncState<int> state, {VoidCallback? onRetry}) {
  return CustomScrollView(
    slivers: [
      WAsyncStateSliver<int>(
        state: state,
        onRetry: onRetry ?? () {},
        readySliverBuilder: (context, value) {
          return SliverToBoxAdapter(child: Text('ready-$value'));
        },
      ),
    ],
  );
}

void main() {
  testWidgets('ready 渲染 ready sliver', (tester) async {
    await tester.pumpWidget(
      _host(_scroll(const WAsyncState.ready(1))),
    );

    expect(find.text('ready-1'), findsOneWidget);
  });

  testWidgets('loading / empty / failed 使用 SliverFillRemaining', (tester) async {
    await tester.pumpWidget(
      _host(_scroll(const WAsyncState.loading())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(
      _host(_scroll(const WAsyncState.empty())),
    );
    expect(find.text('暂无数据'), findsOneWidget);

    await tester.pumpWidget(
      _host(_scroll(const WAsyncState.failed('boom'))),
    );
    expect(find.byType(WAsyncErrorView), findsOneWidget);
  });

  testWidgets('failed + 旧数据保留 ready 并附加 banner', (tester) async {
    await tester.pumpWidget(
      _host(_scroll(const WAsyncState.failed('boom', previousData: 1))),
    );

    expect(find.text('ready-1'), findsOneWidget);
    expect(find.byType(WAsyncErrorBanner), findsOneWidget);
  });

  testWidgets('refreshing 默认不附加额外进度', (tester) async {
    await tester.pumpWidget(
      _host(_scroll(const WAsyncState.loading(previousData: 1))),
    );

    expect(find.text('ready-1'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('可显式添加 refreshing sliver', (tester) async {
    const state = WAsyncState<int>.loading(previousData: 1);
    await tester.pumpWidget(
      _host(
        CustomScrollView(
          slivers: [
            WAsyncStateSliver<int>(
              state: state,
              onRetry: () {},
              readySliverBuilder: (context, value) {
                return SliverToBoxAdapter(child: Text('ready-$value'));
              },
              refreshingSliverBuilder: (context) {
                return const SliverToBoxAdapter(
                  child: Text('custom-refreshing'),
                );
              },
            ),
          ],
        ),
      ),
    );

    expect(find.text('ready-1'), findsOneWidget);
    expect(find.text('custom-refreshing'), findsOneWidget);
  });

  testWidgets('重试回调可用', (tester) async {
    var retries = 0;

    await tester.pumpWidget(
      _host(
        _scroll(
          const WAsyncState.failed('boom'),
          onRetry: () => retries++,
        ),
      ),
    );

    await tester.tap(find.text('重试'));
    expect(retries, 1);
  });
}
