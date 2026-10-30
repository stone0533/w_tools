import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';

Widget _scroll(WAsyncState<int> state) {
  return CustomScrollView(
    slivers: [
      WAsyncStateSliver<int>(
        state: state,
        onRetry: () {},
        readySliverBuilder: (context, value) {
          return SliverToBoxAdapter(child: Text('ready-$value'));
        },
      ),
    ],
  );
}

void main() {
  testWidgets('loading / empty / error 使用 WAsyncSliverDefaults', (tester) async {
    await tester.pumpWidget(
      WAsyncSliverDefaults(
        loadingBuilder: (_) => const Text('default-loading'),
        emptyBuilder: (_) => const Text('default-empty'),
        errorBuilder: (context, error, retry) => const Text('default-error'),
        child: MaterialApp(
          home: Scaffold(body: _scroll(const WAsyncState.loading())),
        ),
      ),
    );
    expect(find.text('default-loading'), findsOneWidget);

    await tester.pumpWidget(
      WAsyncSliverDefaults(
        loadingBuilder: (_) => const Text('default-loading'),
        emptyBuilder: (_) => const Text('default-empty'),
        errorBuilder: (context, error, retry) => const Text('default-error'),
        child: MaterialApp(
          home: Scaffold(body: _scroll(const WAsyncState.empty())),
        ),
      ),
    );
    expect(find.text('default-empty'), findsOneWidget);

    await tester.pumpWidget(
      WAsyncSliverDefaults(
        loadingBuilder: (_) => const Text('default-loading'),
        emptyBuilder: (_) => const Text('default-empty'),
        errorBuilder: (context, error, retry) => const Text('default-error'),
        child: MaterialApp(
          home: Scaffold(body: _scroll(const WAsyncState.failed('boom'))),
        ),
      ),
    );
    expect(find.text('default-error'), findsOneWidget);
  });

  testWidgets('failed + 旧数据使用 WAsyncSliverDefaults.errorBannerBuilder', (tester) async {
    await tester.pumpWidget(
      WAsyncSliverDefaults(
        errorBannerBuilder: (context, error, retry) => const Text('default-banner'),
        child: MaterialApp(
          home: Scaffold(
            body: _scroll(const WAsyncState.failed('boom', previousData: 1)),
          ),
        ),
      ),
    );

    expect(find.text('ready-1'), findsOneWidget);
    expect(find.text('default-banner'), findsOneWidget);
  });

  testWidgets('refreshingSliverBuilder 可由 defaults 提供', (tester) async {
    await tester.pumpWidget(
      WAsyncSliverDefaults(
        refreshingSliverBuilder: (_) {
          return const SliverToBoxAdapter(
            child: Text('default-refreshing'),
          );
        },
        child: MaterialApp(
          home: Scaffold(
            body: _scroll(const WAsyncState.loading(previousData: 1)),
          ),
        ),
      ),
    );

    expect(find.text('ready-1'), findsOneWidget);
    expect(find.text('default-refreshing'), findsOneWidget);
  });

  testWidgets('显式 builder 优先于 WAsyncSliverDefaults', (tester) async {
    await tester.pumpWidget(
      WAsyncSliverDefaults(
        loadingBuilder: (_) => const Text('default-loading'),
        child: MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                WAsyncStateSliver<int>(
                  state: const WAsyncState.loading(),
                  onRetry: () {},
                  loadingBuilder: (_) => const Text('explicit-loading'),
                  readySliverBuilder: (context, value) {
                    return const SliverToBoxAdapter(child: Text('ready'));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('explicit-loading'), findsOneWidget);
    expect(find.text('default-loading'), findsNothing);
  });

  testWidgets('WAsyncViewDefaults 不会影响 WAsyncStateSliver', (tester) async {
    await tester.pumpWidget(
      WAsyncViewDefaults(
        errorBuilder: (context, error, retry) => const Text('view-default-error'),
        child: MaterialApp(
          home: Scaffold(body: _scroll(const WAsyncState.failed('boom'))),
        ),
      ),
    );

    expect(find.byType(WAsyncErrorView), findsOneWidget);
    expect(find.text('view-default-error'), findsNothing);
  });
}
