import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('count-$count'),
        TextButton(
          onPressed: () => setState(() => count++),
          child: const Text('increment'),
        ),
      ],
    );
  }
}

void main() {
  testWidgets('retry 同步抛错也能被 onRetryError 观测', (tester) async {
    final state = ValueNotifier<WAsyncState<int>>(
      WAsyncState<int>.failed(Exception('load')),
    );
    addTearDown(state.dispose);
    Object? reported;

    await tester.pumpWidget(
      _host(
        WAsyncView<int>(
          state: state,
          onRetry: () => throw Exception('sync retry'),
          onRetryError: (error, _) => reported = error,
          readyBuilder: (_, value) => Text('$value'),
        ),
      ),
    );
    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(reported, isA<Exception>());
  });

  testWidgets('自定义 retry 失败可通过 onRetryError 观测', (tester) async {
    final state = ValueNotifier<WAsyncState<int>>(
      WAsyncState<int>.failed(Exception('load')),
    );
    addTearDown(state.dispose);
    Object? reported;

    await tester.pumpWidget(
      _host(
        WAsyncView<int>(
          state: state,
          onRetry: () async => throw Exception('retry failed'),
          onRetryError: (error, _) => reported = error,
          readyBuilder: (_, value) => Text('$value'),
        ),
      ),
    );
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(reported, isA<Exception>());
  });

  testWidgets('loading / ready / empty / failed', (tester) async {
    final state = ValueNotifier<WAsyncState<int>>(
      const WAsyncState.loading(),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _host(
        WAsyncView<int>(
          state: state,
          onRetry: () async {},
          readyBuilder: (context, value) => Text('value-$value'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    state.value = const WAsyncState.ready(1);
    await tester.pump();
    expect(find.text('value-1'), findsOneWidget);

    state.value = const WAsyncState.empty();
    await tester.pump();
    expect(find.text('No data'), findsOneWidget);

    state.value = const WAsyncState.failed('boom');
    await tester.pump();
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('ready → refreshing 保留 readyBuilder 子树状态', (tester) async {
    final state = ValueNotifier<WAsyncState<int>>(
      const WAsyncState.ready(1),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _host(
        WAsyncView<int>(
          state: state,
          onRetry: () async {},
          readyBuilder: (context, value) => const _Counter(),
        ),
      ),
    );

    await tester.tap(find.text('increment'));
    await tester.pump();
    expect(find.text('count-1'), findsOneWidget);

    state.value = const WAsyncState.loading(previousData: 1);
    await tester.pump();

    expect(find.text('count-1'), findsOneWidget);
  });

  testWidgets('ready 可滚动内容获得有界高度', (tester) async {
    final state = ValueNotifier<WAsyncState<int>>(
      const WAsyncState.ready(1),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _host(
        SizedBox(
          height: 240,
          child: WAsyncView<int>(
            state: state,
            onRetry: () async {},
            readyBuilder: (context, value) {
              return ListView(
                children: const [Text('row')],
              );
            },
          ),
        ),
      ),
    );

    expect(find.byType(ListView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('松约束下内容盒只包住内容，overlay 不撑满视口', (tester) async {
    final state = ValueNotifier<WAsyncState<int>>(
      const WAsyncState<int>.failed('boom', previousData: 1),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _host(
        SizedBox(
          height: 600,
          child: Column(
            children: [
              WAsyncView<int>(
                state: state,
                onRetry: () async {},
                readyBuilder: (context, value) => SizedBox(
                  height: 40,
                  child: Text('value-$value'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(WAsyncErrorBanner), findsOneWidget);
    expect(tester.getSize(find.byType(WAsyncView<int>)).height, lessThan(600));
  });

  testWidgets('failed + previousData 保留内容并展示错误条', (tester) async {
    final state = ValueNotifier<WAsyncState<int>>(
      const WAsyncState.failed('boom', previousData: 1),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _host(
        WAsyncView<int>(
          state: state,
          onRetry: () async {},
          readyBuilder: (context, value) => Text('value-$value'),
          errorBannerBuilder: (context, error, retry) => Text('error-$error'),
        ),
      ),
    );

    expect(find.text('value-1'), findsOneWidget);
    expect(find.text('error-boom'), findsOneWidget);
  });

  testWidgets('failed + previousData 默认使用紧凑错误条', (tester) async {
    final state = ValueNotifier<WAsyncState<int>>(
      const WAsyncState.failed('boom', previousData: 1),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _host(
        WAsyncView<int>(
          state: state,
          onRetry: () async {},
          readyBuilder: (context, value) => Text('value-$value'),
        ),
      ),
    );

    expect(find.byType(WAsyncErrorBanner), findsOneWidget);
    expect(find.text('value-1'), findsOneWidget);
  });

  testWidgets('WAsyncTheme 可覆盖错误视图', (tester) async {
    final state = ValueNotifier<WAsyncState<int>>(
      const WAsyncState.failed('boom'),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _host(
        WAsyncTheme(
          errorBuilder: (context, error, retry) => const Text('default-error'),
          child: WAsyncView<int>(
            state: state,
            onRetry: () async {},
            readyBuilder: (context, value) => Text('value-$value'),
          ),
        ),
      ),
    );

    expect(find.text('default-error'), findsOneWidget);
  });

  testWidgets('显式 errorBannerBuilder 优先于 Defaults', (tester) async {
    final state = ValueNotifier<WAsyncState<int>>(
      const WAsyncState.failed('boom', previousData: 1),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _host(
        WAsyncTheme(
          errorBannerBuilder: (context, error, retry) => const Text('default-banner'),
          child: WAsyncView<int>(
            state: state,
            onRetry: () async {},
            readyBuilder: (context, value) => Text('value-$value'),
            errorBannerBuilder: (context, error, retry) => const Text('explicit-banner'),
          ),
        ),
      ),
    );

    expect(find.text('explicit-banner'), findsOneWidget);
    expect(find.text('default-banner'), findsNothing);
  });

  testWidgets('WAsyncErrorBanner 可独立使用', (tester) async {
    var retries = 0;

    await tester.pumpWidget(
      _host(
        WAsyncErrorBanner(
          error: 'boom',
          onRetry: () => retries++,
        ),
      ),
    );

    expect(find.textContaining('Something went wrong'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('WAsyncErrorBanner 无 onRetry 时不显示按钮', (tester) async {
    await tester.pumpWidget(
      _host(
        const WAsyncErrorBanner(error: 'boom'),
      ),
    );

    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('WAsyncErrorBanner 默认文案使用 ASCII 冒号', (tester) async {
    await tester.pumpWidget(
      _host(
        const WAsyncErrorBanner(error: 'boom'),
      ),
    );

    expect(find.text('Something went wrong: boom'), findsOneWidget);
  });

  testWidgets('自定义 refreshingBuilder 生效', (tester) async {
    final state = ValueNotifier<WAsyncState<int>>(
      const WAsyncState.loading(previousData: 1),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _host(
        WAsyncView<int>(
          state: state,
          onRetry: () async {},
          readyBuilder: (context, value) => Text('value-$value'),
          refreshingBuilder: (context) => const Text('custom-refreshing'),
        ),
      ),
    );

    expect(find.text('value-1'), findsOneWidget);
    expect(find.text('custom-refreshing'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('WAsyncView 在 Row 的无界宽度下不崩溃', (tester) async {
    final state = ValueNotifier<WAsyncState<int>>(
      const WAsyncState.loading(previousData: 1),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _host(
        Row(
          children: [
            WAsyncView<int>(
              state: state,
              onRetry: () async {},
              readyBuilder: (context, value) => Text('value-$value'),
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('WAsyncTheme 可放在 MaterialApp 外层', (tester) async {
    final state = ValueNotifier<WAsyncState<int>>(
      const WAsyncState.failed('boom'),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      WAsyncTheme(
        errorBuilder: (context, error, retry) => const Text('root-default-error'),
        child: MaterialApp(
          home: Scaffold(
            body: WAsyncView<int>(
              state: state,
              onRetry: () async {},
              readyBuilder: (context, value) => Text('value-$value'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('root-default-error'), findsOneWidget);
  });

  testWidgets('WAsyncTheme.refreshingBuilder 生效', (tester) async {
    final state = ValueNotifier<WAsyncState<int>>(
      const WAsyncState.loading(previousData: 1),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _host(
        WAsyncTheme(
          refreshingBuilder: (context) => const Text('default-refreshing'),
          child: WAsyncView<int>(
            state: state,
            onRetry: () async {},
            readyBuilder: (context, value) => Text('value-$value'),
          ),
        ),
      ),
    );

    expect(find.text('default-refreshing'), findsOneWidget);
  });

  testWidgets('WAsyncTheme.errorBannerBuilder 覆盖刷新错误条', (tester) async {
    final state = ValueNotifier<WAsyncState<int>>(
      const WAsyncState.failed('boom', previousData: 1),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _host(
        WAsyncTheme(
          errorBannerBuilder: (context, error, retry) => const Text('banner-error'),
          child: WAsyncView<int>(
            state: state,
            onRetry: () async {},
            readyBuilder: (context, value) => Text('value-$value'),
          ),
        ),
      ),
    );

    expect(find.text('value-1'), findsOneWidget);
    expect(find.text('banner-error'), findsOneWidget);
  });

  testWidgets('refreshing 保留内容并显示进度条', (tester) async {
    final state = ValueNotifier<WAsyncState<int>>(
      const WAsyncState.loading(previousData: 1),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _host(
        WAsyncView<int>(
          state: state,
          onRetry: () async {},
          readyBuilder: (context, value) => Text('value-$value'),
        ),
      ),
    );

    expect(find.text('value-1'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('WAsyncStateBuilder 透传状态变化', (tester) async {
    final state = ValueNotifier<WAsyncState<int>>(
      const WAsyncState.loading(),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _host(
        WAsyncStateBuilder<int>(
          state: state,
          builder: (context, value) => Text('status-${value.status.name}'),
        ),
      ),
    );

    expect(find.text('status-loading'), findsOneWidget);

    state.value = const WAsyncState.ready(1);
    await tester.pump();
    expect(find.text('status-ready'), findsOneWidget);

    state.value = const WAsyncState.empty();
    await tester.pump();
    expect(find.text('status-empty'), findsOneWidget);

    state.value = const WAsyncState.failed('boom');
    await tester.pump();
    expect(find.text('status-failed'), findsOneWidget);
  });

  testWidgets('默认错误视图Retry回调可用', (tester) async {
    var retries = 0;
    final state = ValueNotifier<WAsyncState<int>>(
      const WAsyncState.failed('boom'),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _host(
        WAsyncView<int>(
          state: state,
          onRetry: () async => retries++,
          readyBuilder: (context, value) => Text('value-$value'),
        ),
      ),
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(retries, 1);
  });

  testWidgets('未传 onRetry 时 errorBuilder 仍会收到 null', (tester) async {
    final state = ValueNotifier<WAsyncState<int>>(
      const WAsyncState.failed('boom'),
    );
    addTearDown(state.dispose);
    var calls = 0;
    VoidCallback? seen;

    await tester.pumpWidget(
      _host(
        WAsyncView<int>(
          state: state,
          readyBuilder: (context, value) => Text('value-$value'),
          errorBuilder: (context, error, retry) {
            calls++;
            seen = retry;
            return const Text('custom-error');
          },
        ),
      ),
    );

    expect(find.text('Retry'), findsNothing);
    expect(find.text('custom-error'), findsOneWidget);
    expect(calls, 1);
    expect(seen, isNull);
  });

  testWidgets('显式 errorBuilder 优先于默认错误视图', (tester) async {
    final state = ValueNotifier<WAsyncState<int>>(
      const WAsyncState.failed('boom'),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _host(
        WAsyncView<int>(
          state: state,
          onRetry: () async {},
          readyBuilder: (context, value) => Text('value-$value'),
          errorBuilder: (context, error, retry) => const Text('custom-error'),
        ),
      ),
    );

    expect(find.text('custom-error'), findsOneWidget);
    expect(find.byType(WAsyncErrorView), findsNothing);
  });

  testWidgets('onRetryError 自身抛错不影响 UI', (tester) async {
    final state = ValueNotifier<WAsyncState<int>>(
      const WAsyncState.failed('boom'),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _host(
        WAsyncView<int>(
          state: state,
          onRetry: () async => throw Exception('retry failed'),
          onRetryError: (_, _) => throw StateError('handler boom'),
          readyBuilder: (context, value) => Text('value-$value'),
        ),
      ),
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('retry 失败且无 onRetryError 时走 FlutterError.reportError', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);

    final state = ValueNotifier<WAsyncState<int>>(
      const WAsyncState.failed('boom'),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _host(
        WAsyncView<int>(
          state: state,
          onRetry: () async => throw Exception('retry failed'),
          readyBuilder: (context, value) => Text('value-$value'),
        ),
      ),
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(errors, isNotEmpty);
  });
}
