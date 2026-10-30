import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
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
    expect(find.text('暂无数据'), findsOneWidget);

    state.value = const WAsyncState.failed('boom');
    await tester.pump();
    expect(find.text('重试'), findsOneWidget);
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
          errorBuilder: (context, error, retry) => Text('error-$error'),
        ),
      ),
    );

    expect(find.text('value-1'), findsOneWidget);
    expect(find.text('error-boom'), findsOneWidget);
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

  testWidgets('默认错误视图重试回调可用', (tester) async {
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

    await tester.tap(find.text('重试'));
    await tester.pump();

    expect(retries, 1);
  });
}
