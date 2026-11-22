import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';

Widget _box(WAsyncState<int> state, {WidgetBuilder? loadingBuilder}) {
  return WAsyncView<int>(
    state: ValueNotifier(state),
    loadingBuilder: loadingBuilder,
    readyBuilder: (context, value) => Text('ready-$value'),
    onRetry: () {},
  );
}

Widget _scroll(WAsyncState<int> state) {
  return CustomScrollView(
    slivers: [
      WAsyncStateSliver<int>(
        state: ValueNotifier(state),
        onRetry: () {},
        readySliverBuilder: (context, value) => SliverToBoxAdapter(child: Text('ready-$value')),
      ),
    ],
  );
}

void main() {
  testWidgets('WAsyncTheme 的 loadingBuilder 同时覆盖普通视图与 sliver', (tester) async {
    await tester.pumpWidget(
      WAsyncTheme(
        loadingBuilder: (_) => const Text('theme-loading'),
        child: MaterialApp(
          home: Scaffold(body: _box(const WAsyncState.loading())),
        ),
      ),
    );
    expect(find.text('theme-loading'), findsOneWidget);

    await tester.pumpWidget(
      WAsyncTheme(
        loadingBuilder: (_) => const Text('theme-loading'),
        child: MaterialApp(
          home: Scaffold(body: _scroll(const WAsyncState.loading())),
        ),
      ),
    );
    expect(find.text('theme-loading'), findsOneWidget);
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

  testWidgets('WAsyncTheme 的 errorBuilder 覆盖 sliver 的默认错误视图', (tester) async {
    await tester.pumpWidget(
      WAsyncTheme(
        errorBuilder: (context, error, retry) => const Text('theme-error'),
        child: MaterialApp(
          home: Scaffold(body: _scroll(const WAsyncState<int>.failed('boom'))),
        ),
      ),
    );
    expect(find.text('theme-error'), findsOneWidget);
  });

  test('WAsyncStrings 相等性与 hashCode 都包含 noMore / loadMore', () {
    const a = WAsyncStrings(noMore: 'A');
    const b = WAsyncStrings(noMore: 'B');
    const c = WAsyncStrings(loadMore: 'A');
    const d = WAsyncStrings(loadMore: 'B');

    expect(a == b, isFalse);
    expect(a.hashCode, isNot(b.hashCode));
    expect(c == d, isFalse);
    expect(c.hashCode, isNot(d.hashCode));
  });

  testWidgets('只改 noMore 也会通知 WAsyncTheme 依赖重建', (tester) async {
    Widget build(String noMore) {
      return WAsyncTheme(
        strings: WAsyncStrings(noMore: noMore),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final strings = WAsyncTheme.maybeOf(context)!.strings;
              return Text(strings.noMore);
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(build('A'));
    expect(find.text('A'), findsOneWidget);

    await tester.pumpWidget(build('B'));
    expect(find.text('B'), findsOneWidget);
    expect(find.text('A'), findsNothing);
  });

  testWidgets('切换 strings 会通知依赖的 WAsyncView 重建', (tester) async {
    final state = ValueNotifier<WAsyncState<int>>(const WAsyncState<int>.empty());
    addTearDown(state.dispose);

    Widget build(String empty) {
      return WAsyncTheme(
        strings: WAsyncStrings(empty: empty),
        child: MaterialApp(
          home: Scaffold(
            body: WAsyncView<int>(
              state: state,
              readyBuilder: (context, value) => Text('$value'),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(build('A'));
    expect(find.text('A'), findsOneWidget);

    await tester.pumpWidget(build('B'));
    expect(find.text('B'), findsOneWidget);
    expect(find.text('A'), findsNothing);
  });
}
