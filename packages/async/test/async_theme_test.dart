import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';

Widget _box(WAsyncState<int> state, {WidgetBuilder? loadingBuilder}) {
  return WAsyncView<int>(
    state: ValueNotifier(state),
    loadingBuilder: loadingBuilder,
    readyBuilder: (context, value) => Text('ready-$value'),
    onRetry: () async {},
  );
}

Widget _scroll(WAsyncState<int> state) {
  return CustomScrollView(
    slivers: [
      WAsyncStateSliver<int>(
        state: ValueNotifier(state),
        onRetry: () async {},
        readySliverBuilder: (context, value) => SliverToBoxAdapter(child: Text('ready-$value')),
      ),
    ],
  );
}

void main() {
  testWidgets('WAsyncTheme 同时覆盖普通视图与 sliver 视图', (tester) async {
    await tester.pumpWidget(
      WAsyncTheme(
        loadingBuilder: (_) => const Text('theme-box-loading'),
        sliverLoadingBuilder: (_) => const Text('theme-sliver-loading'),
        child: MaterialApp(
          home: Scaffold(body: _box(const WAsyncState.loading())),
        ),
      ),
    );
    expect(find.text('theme-box-loading'), findsOneWidget);

    await tester.pumpWidget(
      WAsyncTheme(
        loadingBuilder: (_) => const Text('theme-box-loading'),
        sliverLoadingBuilder: (_) => const Text('theme-sliver-loading'),
        child: MaterialApp(
          home: Scaffold(body: _scroll(const WAsyncState.loading())),
        ),
      ),
    );
    expect(find.text('theme-sliver-loading'), findsOneWidget);
  });

  testWidgets('显式 builder 优先于 WAsyncTheme', (tester) async {
    await tester.pumpWidget(
      WAsyncTheme(
        loadingBuilder: (_) => const Text('theme-loading'),
        child: MaterialApp(
          home: Scaffold(
            body: _box(
              const WAsyncState.loading(),
              loadingBuilder: (_) => const Text('explicit-loading'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('explicit-loading'), findsOneWidget);
    expect(find.text('theme-loading'), findsNothing);
  });

  testWidgets('WAsyncTheme 的 sliver error 覆盖 WAsyncErrorView 默认', (tester) async {
    await tester.pumpWidget(
      WAsyncTheme(
        sliverErrorBuilder: (context, error, retry) => const Text('theme-sliver-error'),
        child: MaterialApp(
          home: Scaffold(body: _scroll(const WAsyncState<int>.failed('boom'))),
        ),
      ),
    );
    expect(find.text('theme-sliver-error'), findsOneWidget);
  });
}
