import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

Widget _scroll(ValueListenable<WAsyncState<int>> state, {Future<void> Function()? onRetry}) {
  return CustomScrollView(
    slivers: [
      WAsyncStateSliver<int>(
        state: state,
        onRetry: onRetry,
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
      _host(_scroll(ValueNotifier(const WAsyncState.ready(1)))),
    );

    expect(find.text('ready-1'), findsOneWidget);
  });

  testWidgets('loading / empty / failed 使用 SliverFillRemaining', (tester) async {
    await tester.pumpWidget(
      _host(_scroll(ValueNotifier(const WAsyncState.loading()))),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(
      _host(_scroll(ValueNotifier(const WAsyncState.empty()))),
    );
    expect(find.text('No data'), findsOneWidget);

    await tester.pumpWidget(
      _host(_scroll(ValueNotifier(const WAsyncState.failed('boom')))),
    );
    expect(find.byType(WAsyncErrorView), findsOneWidget);
  });

  testWidgets('failed + 旧数据保留 ready 并附加 banner', (tester) async {
    await tester.pumpWidget(
      _host(_scroll(ValueNotifier(const WAsyncState.failed('boom', previousData: 1)))),
    );

    expect(find.text('ready-1'), findsOneWidget);
    expect(find.byType(WAsyncErrorBanner), findsOneWidget);
  });

  testWidgets('refreshing 默认不附加额外进度', (tester) async {
    await tester.pumpWidget(
      _host(_scroll(ValueNotifier(const WAsyncState.loading(previousData: 1)))),
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
              state: ValueNotifier(state),
              onRetry: () async {},
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

  testWidgets('Retry回调可用', (tester) async {
    var retries = 0;

    await tester.pumpWidget(
      _host(
        _scroll(
          ValueNotifier(const WAsyncState.failed('boom')),
          onRetry: () async {
            retries++;
          },
        ),
      ),
    );

    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('未传 onRetry 时不显示Retry按钮', (tester) async {
    await tester.pumpWidget(
      _host(_scroll(ValueNotifier(const WAsyncState.failed('boom')))),
    );

    expect(find.byType(WAsyncErrorView), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('未传 onRetry 时 failed + 旧数据的 banner 也不显示Retry按钮', (tester) async {
    await tester.pumpWidget(
      _host(_scroll(ValueNotifier(const WAsyncState.failed('boom', previousData: 1)))),
    );

    expect(find.byType(WAsyncErrorBanner), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('未传 onRetry 时自定义 error / banner builder 仍会收到 null', (tester) async {
    var errorBuilderCalls = 0;
    var bannerBuilderCalls = 0;
    VoidCallback? errorRetry;
    VoidCallback? bannerRetry;

    Widget build(WAsyncState<int> state) {
      return CustomScrollView(
        slivers: [
          WAsyncStateSliver<int>(
            state: ValueNotifier(state),
            readySliverBuilder: (context, value) => SliverToBoxAdapter(child: Text('ready-$value')),
            errorBuilder: (context, error, retry) {
              errorBuilderCalls++;
              errorRetry = retry;
              return const Text('custom-error');
            },
            errorBannerBuilder: (context, error, retry) {
              bannerBuilderCalls++;
              bannerRetry = retry;
              return const Text('custom-banner');
            },
          ),
        ],
      );
    }

    await tester.pumpWidget(_host(build(const WAsyncState.failed('boom'))));
    expect(find.text('custom-error'), findsOneWidget);
    expect(errorBuilderCalls, 1);
    expect(errorRetry, isNull);

    await tester.pumpWidget(
      _host(build(const WAsyncState.failed('boom', previousData: 1))),
    );
    expect(find.text('custom-banner'), findsOneWidget);
    expect(bannerBuilderCalls, 1);
    expect(bannerRetry, isNull);
  });

  testWidgets('传了 onRetry 时自定义 error builder 优先于默认视图', (tester) async {
    await tester.pumpWidget(
      _host(
        CustomScrollView(
          slivers: [
            WAsyncStateSliver<int>(
              state: ValueNotifier(const WAsyncState.failed('boom')),
              onRetry: () async {},
              readySliverBuilder: (context, value) =>
                  SliverToBoxAdapter(child: Text('ready-$value')),
              errorBuilder: (context, error, retry) => const Text('custom-error'),
            ),
          ],
        ),
      ),
    );

    expect(find.text('custom-error'), findsOneWidget);
    expect(find.byType(WAsyncErrorView), findsNothing);
  });

  testWidgets('retry 同步抛错可被 onRetryError 观测', (tester) async {
    Object? reported;

    await tester.pumpWidget(
      _host(
        CustomScrollView(
          slivers: [
            WAsyncStateSliver<int>(
              state: ValueNotifier(const WAsyncState.failed('boom')),
              onRetry: () => throw Exception('sync retry'),
              onRetryError: (error, _) => reported = error,
              readySliverBuilder: (context, value) =>
                  SliverToBoxAdapter(child: Text('ready-$value')),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(reported, isA<Exception>());
  });

  testWidgets('retry 失败且无 onRetryError 时走 FlutterError.reportError', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);

    await tester.pumpWidget(
      _host(
        CustomScrollView(
          slivers: [
            WAsyncStateSliver<int>(
              state: ValueNotifier(const WAsyncState.failed('boom')),
              onRetry: () async => throw Exception('retry failed'),
              readySliverBuilder: (context, value) =>
                  SliverToBoxAdapter(child: Text('ready-$value')),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(errors, isNotEmpty);
  });
}
