import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';

Widget _probe(Widget Function(BuildContext context, WAsyncThemeViews views) build) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => build(context, WAsyncThemeViews.of(context)),
      ),
    ),
  );
}

void main() {
  group('WAsyncThemeViews', () {
    testWidgets('默认：loading / empty / refreshing', (tester) async {
      await tester.pumpWidget(_probe((context, views) => views.loading(context)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpWidget(_probe((context, views) => views.empty(context)));
      expect(find.text('No data'), findsOneWidget);

      await tester.pumpWidget(_probe((context, views) => views.refreshing(context)));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    test('WAsyncStrings 按值相等', () {
      expect(
        const WAsyncStrings(empty: 'a'),
        const WAsyncStrings(empty: 'a'),
      );
      expect(
        const WAsyncStrings(empty: 'a'),
        isNot(const WAsyncStrings(empty: 'b')),
      );
    });

    testWidgets('默认 error：有 retry 显示按钮，无 retry 不显示', (tester) async {
      await tester.pumpWidget(
        _probe((context, views) => views.error(context, Exception('boom'), () {})),
      );
      expect(find.byType(WAsyncErrorView), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.pumpWidget(
        _probe((context, views) => views.error(context, Exception('boom'), null)),
      );
      expect(find.byType(WAsyncErrorView), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('无 retry 时仍使用主题文案', (tester) async {
      await tester.pumpWidget(
        WAsyncTheme(
          strings: const WAsyncStrings(errorTitle: '加载失败'),
          child: _probe(
            (context, views) => views.error(context, Exception('boom'), null),
          ),
        ),
      );
      expect(find.text('加载失败'), findsOneWidget);
    });

    testWidgets('无 retry 时 explicit builder 仍会收到 null', (tester) async {
      var calls = 0;
      VoidCallback? seen;

      await tester.pumpWidget(
        WAsyncTheme(
          errorBuilder: (context, error, retry) {
            calls++;
            return const Text('theme-error');
          },
          child: _probe(
            (context, views) => views.error(
              context,
              Exception('boom'),
              null,
              explicit: (context, error, retry) {
                calls++;
                seen = retry;
                return const Text('explicit-error');
              },
            ),
          ),
        ),
      );

      expect(find.text('explicit-error'), findsOneWidget);
      expect(find.text('theme-error'), findsNothing);
      expect(calls, 1);
      expect(seen, isNull);
    });

    testWidgets('无 retry 时 theme builder 仍会收到 null', (tester) async {
      var calls = 0;
      VoidCallback? seen;

      await tester.pumpWidget(
        WAsyncTheme(
          errorBuilder: (context, error, retry) {
            calls++;
            seen = retry;
            return const Text('theme-error');
          },
          child: _probe(
            (context, views) => views.error(context, Exception('boom'), null),
          ),
        ),
      );

      expect(find.text('theme-error'), findsOneWidget);
      expect(calls, 1);
      expect(seen, isNull);
    });

    testWidgets('explicit 优先于 theme', (tester) async {
      await tester.pumpWidget(
        WAsyncTheme(
          emptyBuilder: (_) => const Text('theme-empty'),
          child: _probe(
            (context, views) => views.empty(
              context,
              explicit: (_) => const Text('explicit-empty'),
            ),
          ),
        ),
      );

      expect(find.text('explicit-empty'), findsOneWidget);
      expect(find.text('theme-empty'), findsNothing);
    });

    testWidgets('theme 覆盖默认', (tester) async {
      await tester.pumpWidget(
        WAsyncTheme(
          emptyBuilder: (_) => const Text('theme-empty'),
          child: _probe((context, views) => views.empty(context)),
        ),
      );

      expect(find.text('theme-empty'), findsOneWidget);
      expect(find.text('No data'), findsNothing);
    });

    testWidgets('sliver 默认视图与主题', (tester) async {
      await tester.pumpWidget(
        _probe(
          (context, views) => CustomScrollView(
            slivers: [SliverFillRemaining(child: views.sliverEmpty(context))],
          ),
        ),
      );
      expect(find.text('No data'), findsOneWidget);

      await tester.pumpWidget(
        WAsyncTheme(
          sliverEmptyBuilder: (_) => const Text('theme-sliver-empty'),
          child: _probe(
            (context, views) => CustomScrollView(
              slivers: [SliverFillRemaining(child: views.sliverEmpty(context))],
            ),
          ),
        ),
      );
      expect(find.text('theme-sliver-empty'), findsOneWidget);
    });

    testWidgets('maybeRefreshingSliver 默认 null，theme 可提供 sliver', (tester) async {
      Widget page(BuildContext context, WAsyncThemeViews views) {
        return CustomScrollView(
          slivers: [
            if (views.maybeRefreshingSliver(context) case final sliver?) sliver,
            const SliverToBoxAdapter(child: Text('body')),
          ],
        );
      }

      await tester.pumpWidget(_probe(page));
      expect(find.text('body'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);

      await tester.pumpWidget(
        WAsyncTheme(
          refreshingSliverBuilder: (_) => const SliverToBoxAdapter(child: Text('theme-refreshing')),
          child: _probe(page),
        ),
      );
      expect(find.text('theme-refreshing'), findsOneWidget);
    });

    testWidgets('默认 loading / empty / error 带 liveRegion', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _probe((context, views) => views.loading(context)),
      );
      final loading = find.bySemanticsLabel('Loading');
      expect(loading, findsOneWidget);
      expect(
        tester.getSemantics(loading).flagsCollection.isLiveRegion,
        isTrue,
      );

      await tester.pumpWidget(
        _probe((context, views) => views.empty(context)),
      );
      final empty = find.bySemanticsLabel('No data');
      expect(empty, findsOneWidget);
      expect(
        tester.getSemantics(empty).flagsCollection.isLiveRegion,
        isTrue,
      );

      await tester.pumpWidget(
        _probe(
          (context, views) => views.error(context, Exception('boom'), null),
        ),
      );
      final error = find.bySemanticsLabel(RegExp('Something went wrong'));
      expect(error, findsOneWidget);
      expect(
        tester.getSemantics(error).flagsCollection.isLiveRegion,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('显式 builder 不自动带 liveRegion', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _probe(
          (context, views) => views.loading(context, explicit: (_) => const Text('custom')),
        ),
      );

      final custom = find.bySemanticsLabel('custom');
      expect(custom, findsOneWidget);
      expect(
        tester.getSemantics(custom).flagsCollection.isLiveRegion,
        isFalse,
      );
      handle.dispose();
    });

    test('WAsyncStrings 按值相等，包含 loading', () {
      expect(
        const WAsyncStrings(loading: 'a'),
        const WAsyncStrings(loading: 'a'),
      );
      expect(
        const WAsyncStrings(loading: 'a'),
        isNot(const WAsyncStrings(loading: 'b')),
      );
    });

    testWidgets('WAsyncStateBuilder 可复用主题默认视图', (tester) async {
      final controller = WAsyncController<List<int>>(
        () async => const <int>[],
        isEmpty: (value) => value.isEmpty,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        WAsyncTheme(
          emptyBuilder: (_) => const Text('theme-empty'),
          child: MaterialApp(
            home: Scaffold(
              body: WAsyncStateBuilder<List<int>>(
                state: controller.state,
                builder: (context, state) {
                  final views = WAsyncThemeViews.of(context);
                  return CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        child: state.when(
                          loading: () => views.loading(context),
                          empty: () => views.empty(context),
                          failed: (error) => views.error(context, error, controller.load),
                          ready: (items) => const Text('ready'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await controller.load();
      await tester.pump();

      expect(find.text('theme-empty'), findsOneWidget);
    });
  });
}
