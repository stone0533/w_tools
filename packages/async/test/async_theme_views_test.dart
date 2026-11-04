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

    testWidgets('无 retry 时不调用 explicit / theme builder', (tester) async {
      var calls = 0;

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
                return const Text('explicit-error');
              },
            ),
          ),
        ),
      );

      expect(find.text('theme-error'), findsNothing);
      expect(find.text('explicit-error'), findsNothing);
      expect(calls, 0);
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
