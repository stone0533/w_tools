import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';
import 'package:w_tools_async_ui/w_tools_async_ui.dart';

WAsyncPagedController<int> _controller({
  required Future<WAsyncPage<int>> Function(int page) load,
}) {
  return WAsyncPagedController<int>((page, _) => load(page));
}

Widget _app(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('WAsyncPagedList 渲染分页数据', (tester) async {
    final controller = _controller(
      load: (page) async => WAsyncPage<int>(
        items: page == 1 ? const <int>[1, 2] : const <int>[],
        hasMore: false,
      ),
    );
    addTearDown(controller.dispose);
    await controller.refresh();

    await tester.pumpWidget(
      _app(
        WAsyncPagedList<int>(
          controller: controller,
          itemBuilder: (context, item) => Text('item $item'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('item 1'), findsOneWidget);
    expect(find.text('item 2'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('WAsyncPagedList 支持 RefreshIndicator 样式', (tester) async {
    final controller = _controller(
      load: (page) async => const WAsyncPage<int>(items: <int>[1], hasMore: false),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        WAsyncPagedList<int>(
          controller: controller,
          itemBuilder: (context, item) => Text('item $item'),
          refreshIndicatorStyle: const WAsyncRefreshIndicatorStyle(
            color: Color(0xFF00A86B),
            backgroundColor: Colors.white,
            strokeWidth: 3,
            displacement: 24,
            edgeOffset: 8,
            triggerMode: RefreshIndicatorTriggerMode.anywhere,
          ),
        ),
      ),
    );

    final indicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    expect(indicator.color, const Color(0xFF00A86B));
    expect(indicator.backgroundColor, Colors.white);
    expect(indicator.strokeWidth, 3);
    expect(indicator.displacement, 24);
    expect(indicator.edgeOffset, 8);
    expect(indicator.triggerMode, RefreshIndicatorTriggerMode.anywhere);
  });

  testWidgets('WAsyncPagedList 不自动 refresh', (tester) async {
    var calls = 0;
    final controller = _controller(
      load: (page) async {
        calls++;
        return const WAsyncPage<int>(items: <int>[1], hasMore: false);
      },
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        WAsyncPagedList<int>(
          controller: controller,
          itemBuilder: (context, item) => Text('item $item'),
        ),
      ),
    );
    await tester.pump();

    expect(calls, 0);
  });

  testWidgets('WAsyncPagedList 下拉刷新', (tester) async {
    var calls = 0;
    final controller = _controller(
      load: (page) async {
        calls++;
        return const WAsyncPage<int>(items: <int>[1], hasMore: false);
      },
    );
    addTearDown(controller.dispose);
    await controller.refresh();

    await tester.pumpWidget(
      _app(
        WAsyncPagedList<int>(
          controller: controller,
          itemBuilder: (context, item) => Text('item $item'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('item 1'), findsOneWidget);
  });

  testWidgets('WAsyncPagedList reloadRequests 触发刷新', (tester) async {
    var calls = 0;
    final controller = _controller(
      load: (page) async {
        calls++;
        return const WAsyncPage<int>(items: <int>[1], hasMore: false);
      },
    );
    addTearDown(controller.dispose);
    final reloadRequests = ValueNotifier<int>(0);
    addTearDown(reloadRequests.dispose);

    await tester.pumpWidget(
      _app(
        WAsyncPagedList<int>(
          controller: controller,
          itemBuilder: (context, item) => Text('item $item'),
          reloadRequests: reloadRequests,
        ),
      ),
    );
    await tester.pump();

    reloadRequests.value++;
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(find.text('item 1'), findsOneWidget);
  });

  testWidgets('WAsyncPagedList reloadRequests 连续完成后可再次刷新', (tester) async {
    var calls = 0;
    final controller = _controller(
      load: (page) async {
        calls++;
        return const WAsyncPage<int>(items: <int>[1], hasMore: false);
      },
    );
    addTearDown(controller.dispose);
    final reloadRequests = ValueNotifier<int>(0);
    addTearDown(reloadRequests.dispose);

    await tester.pumpWidget(
      _app(
        WAsyncPagedList<int>(
          controller: controller,
          itemBuilder: (context, item) => Text('item $item'),
          reloadRequests: reloadRequests,
        ),
      ),
    );
    await tester.pump();

    reloadRequests.value++;
    await tester.pumpAndSettle();
    expect(calls, 1);

    reloadRequests.value++;
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('WAsyncPagedList 首屏不足一页时自动补加载', (tester) async {
    var calls = 0;
    final controller = _controller(
      load: (page) async {
        calls++;
        return WAsyncPage<int>(
          items: page == 1 ? const <int>[1] : const <int>[2],
          hasMore: page == 1,
        );
      },
    );
    addTearDown(controller.dispose);
    await controller.refresh();

    await tester.pumpWidget(
      _app(
        WAsyncPagedList<int>(
          controller: controller,
          itemBuilder: (context, item) => Text('item $item'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('item 2'), findsOneWidget);
  });

  testWidgets('WAsyncPagedList 滚动到底自动加载', (tester) async {
    var calls = 0;
    final controller = _controller(
      load: (page) async {
        calls++;
        return WAsyncPage<int>(
          items: page == 1 ? List<int>.generate(20, (index) => index + 1) : const <int>[21],
          hasMore: page == 1,
        );
      },
    );
    addTearDown(controller.dispose);
    await controller.refresh();

    await tester.pumpWidget(
      _app(
        WAsyncPagedList<int>(
          controller: controller,
          itemBuilder: (context, item) => Text('item $item'),
          autoLoadThreshold: 100,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('item 21'), findsOneWidget);
  });

  testWidgets('WAsyncPagedList 自动加载失败后不自动重试', (tester) async {
    var calls = 0;
    final controller = _controller(
      load: (page) async {
        calls++;
        if (page == 1) {
          return WAsyncPage<int>(
            items: List<int>.generate(20, (index) => index + 1),
            hasMore: true,
          );
        }
        throw StateError('load more failed');
      },
    );
    addTearDown(controller.dispose);
    await controller.refresh();

    await tester.pumpWidget(
      _app(
        WAsyncPagedList<int>(
          controller: controller,
          itemBuilder: (context, item) => Text('item $item'),
          autoLoadThreshold: 100,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(calls, 2);
  });

  testWidgets('WAsyncPagedList footer 失败可重试', (tester) async {
    var calls = 0;
    final controller = _controller(
      load: (page) async {
        calls++;
        if (page == 1) {
          return WAsyncPage<int>(
            items: List<int>.generate(20, (index) => index + 1),
            hasMore: true,
          );
        }
        if (calls == 2) throw StateError('load more failed');
        return const WAsyncPage<int>(items: <int>[21], hasMore: false);
      },
    );
    addTearDown(controller.dispose);
    await controller.refresh();

    await tester.pumpWidget(
      _app(
        WAsyncPagedList<int>(
          controller: controller,
          itemBuilder: (context, item) => Text('item $item'),
          autoLoadThreshold: 100,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(calls, 3);
    expect(find.text('item 21'), findsOneWidget);
    expect(find.text('No more'), findsOneWidget);
  });

  testWidgets('WAsyncPagedList noMore 文案走 WAsyncTheme.strings', (tester) async {
    final controller = _controller(
      load: (page) async => page == 1
          ? const WAsyncPage<int>(items: <int>[1], hasMore: true)
          : const WAsyncPage<int>(items: <int>[2], hasMore: false),
    );
    addTearDown(controller.dispose);
    await controller.refresh();
    await controller.loadMore();

    await tester.pumpWidget(
      WAsyncTheme(
        strings: const WAsyncStrings(noMore: '没有更多'),
        child: _app(
          WAsyncPagedList<int>(
            controller: controller,
            itemBuilder: (context, item) => Text('item $item'),
            autoLoadThreshold: null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('没有更多'), findsOneWidget);
    expect(find.text('No more'), findsNothing);
  });

  testWidgets('autoLoadThreshold:null 时默认 footer 提供手动加载', (tester) async {
    var calls = 0;
    final controller = _controller(
      load: (page) async {
        calls++;
        if (page == 1) {
          return const WAsyncPage<int>(items: <int>[1], hasMore: true);
        }
        return const WAsyncPage<int>(items: <int>[2], hasMore: false);
      },
    );
    addTearDown(controller.dispose);
    await controller.refresh();

    await tester.pumpWidget(
      _app(
        WAsyncPagedList<int>(
          controller: controller,
          itemBuilder: (context, item) => Text('item $item'),
          autoLoadThreshold: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Load more'), findsOneWidget);
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('item 2'), findsOneWidget);
  });

  testWidgets('默认 footer 的手动加载文案走 WAsyncTheme.strings', (tester) async {
    final controller = _controller(
      load: (page) async => WAsyncPage<int>(
        items: <int>[page],
        hasMore: page == 1,
      ),
    );
    addTearDown(controller.dispose);
    await controller.refresh();

    await tester.pumpWidget(
      WAsyncTheme(
        strings: const WAsyncStrings(loadMore: '加载更多'),
        child: _app(
          WAsyncPagedList<int>(
            controller: controller,
            itemBuilder: (context, item) => Text('item $item'),
            autoLoadThreshold: null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('加载更多'), findsOneWidget);
  });

  testWidgets('WAsyncPagedList 支持 headerSlivers / sliverPadding', (tester) async {
    final controller = _controller(
      load: (page) async => const WAsyncPage<int>(items: <int>[1], hasMore: false),
    );
    addTearDown(controller.dispose);
    await controller.refresh();

    await tester.pumpWidget(
      _app(
        WAsyncPagedList<int>(
          controller: controller,
          itemBuilder: (context, item) => Text('item $item'),
          headerSlivers: const [
            SliverToBoxAdapter(child: Text('header')),
          ],
          sliverPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('header'), findsOneWidget);
    expect(find.text('item 1'), findsOneWidget);
  });

  testWidgets('WAsyncPagedList 拒绝负数 autoLoadThreshold', (tester) async {
    final controller = _controller(
      load: (page) async => const WAsyncPage<int>(items: <int>[1], hasMore: false),
    );
    addTearDown(controller.dispose);

    expect(
      () => WAsyncPagedList<int>(
        controller: controller,
        itemBuilder: (context, item) => Text('item $item'),
        autoLoadThreshold: -1,
      ),
      throwsAssertionError,
    );
  });

  testWidgets('WAsyncPagedList 刷新完成后立即 reload 仍会发起新请求', (tester) async {
    final completers = <Completer<WAsyncPage<int>>>[];
    final controller = _controller(
      load: (page) {
        final completer = Completer<WAsyncPage<int>>();
        completers.add(completer);
        return completer.future;
      },
    );
    addTearDown(controller.dispose);
    final reloadRequests = ValueNotifier<int>(0);
    addTearDown(reloadRequests.dispose);

    await tester.pumpWidget(
      _app(
        WAsyncPagedList<int>(
          controller: controller,
          itemBuilder: (context, item) => Text('item $item'),
          reloadRequests: reloadRequests,
          autoLoadThreshold: null,
        ),
      ),
    );
    await tester.pump();

    reloadRequests.value++;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(completers, hasLength(1));

    completers.single.complete(
      const WAsyncPage<int>(items: <int>[1], hasMore: false),
    );
    await tester.pump();
    await tester.pump();

    reloadRequests.value++;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(completers, hasLength(2));
  });

  testWidgets('reloadRequests 后列表回到顶部', (tester) async {
    var filtered = false;
    final controller = WAsyncPagedController<int>((page, _) async {
      return WAsyncPage<int>(
        items: List<int>.generate(filtered ? 20 : 30, (index) => index),
        hasMore: false,
      );
    });
    addTearDown(controller.dispose);
    await controller.refresh();
    final reloadRequests = ValueNotifier<int>(0);
    addTearDown(reloadRequests.dispose);

    await tester.pumpWidget(
      _app(
        WAsyncPagedList<int>(
          controller: controller,
          itemBuilder: (context, item) => SizedBox(
            height: 40,
            child: Text('item $item'),
          ),
          reloadRequests: reloadRequests,
          autoLoadThreshold: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      greaterThan(0),
    );

    filtered = true;
    reloadRequests.value++;
    await tester.pumpAndSettle();

    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      0,
    );
  });

  testWidgets('刷新在飞时再次 reload 也会回到顶部', (tester) async {
    final gate = Completer<void>();
    var hold = false;
    final controller = WAsyncPagedController<int>((page, _) async {
      if (hold) await gate.future;
      return WAsyncPage<int>(
        items: List<int>.generate(30, (index) => index),
        hasMore: false,
      );
    });
    addTearDown(controller.dispose);
    await controller.refresh();
    final reloadRequests = ValueNotifier<int>(0);
    addTearDown(reloadRequests.dispose);

    await tester.pumpWidget(
      _app(
        WAsyncPagedList<int>(
          controller: controller,
          itemBuilder: (context, item) => SizedBox(
            height: 40,
            child: Text('item $item'),
          ),
          reloadRequests: reloadRequests,
          autoLoadThreshold: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    hold = true;
    reloadRequests.value++;
    await tester.pump();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
    await tester.pump();
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      greaterThan(0),
    );

    reloadRequests.value++;
    await tester.pump();
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      0,
    );

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('WAsyncPagedList footerBuilder 自定义 footer', (tester) async {
    final controller = _controller(
      load: (page) async => const WAsyncPage<int>(items: <int>[1], hasMore: true),
    );
    addTearDown(controller.dispose);
    await controller.refresh();

    await tester.pumpWidget(
      _app(
        WAsyncPagedList<int>(
          controller: controller,
          itemBuilder: (context, item) => Text('item $item'),
          autoLoadThreshold: null,
          footerBuilder: (context, snapshot) => Text('footer ${snapshot.footerStatus.name}'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('footer loadMore'), findsOneWidget);
  });

  testWidgets('WAsyncPagedList 错误态重试走 RefreshIndicator', (tester) async {
    var calls = 0;
    final controller = _controller(
      load: (page) async {
        calls++;
        if (calls == 1) throw StateError('boom');
        return const WAsyncPage<int>(items: <int>[1], hasMore: false);
      },
    );
    addTearDown(controller.dispose);
    await controller.refresh();

    await tester.pumpWidget(
      _app(
        WAsyncPagedList<int>(
          controller: controller,
          itemBuilder: (context, item) => Text('item $item'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('item 1'), findsOneWidget);
  });

  testWidgets('WAsyncPagedList reloadRequests 并发刷新只保留最新结果', (tester) async {
    final completers = <Completer<WAsyncPage<int>>>[];
    final controller = _controller(
      load: (page) {
        final completer = Completer<WAsyncPage<int>>();
        completers.add(completer);
        return completer.future;
      },
    );
    addTearDown(controller.dispose);
    final reloadRequests = ValueNotifier<int>(0);
    addTearDown(reloadRequests.dispose);

    await tester.pumpWidget(
      _app(
        WAsyncPagedList<int>(
          controller: controller,
          itemBuilder: (context, item) => Text('item $item'),
          reloadRequests: reloadRequests,
        ),
      ),
    );
    await tester.pump();

    reloadRequests.value++;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(completers, hasLength(1));

    reloadRequests.value++;
    await tester.pump();
    expect(completers, hasLength(2));

    completers[0].complete(const WAsyncPage<int>(items: <int>[0], hasMore: false));
    await tester.pump();
    completers[1].complete(const WAsyncPage<int>(items: <int>[1], hasMore: false));
    await tester.pumpAndSettle();

    expect(find.text('item 1'), findsOneWidget);
    expect(find.text('item 0'), findsNothing);
  });

  testWidgets('WAsyncPagedList reloadRequests dispose 后不再触发', (tester) async {
    var calls = 0;
    final controller = _controller(
      load: (page) async {
        calls++;
        return const WAsyncPage<int>(items: <int>[1], hasMore: false);
      },
    );
    addTearDown(controller.dispose);
    final reloadRequests = ValueNotifier<int>(0);
    addTearDown(reloadRequests.dispose);

    await tester.pumpWidget(
      _app(
        WAsyncPagedList<int>(
          controller: controller,
          itemBuilder: (context, item) => Text('item $item'),
          reloadRequests: reloadRequests,
        ),
      ),
    );
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    reloadRequests.value++;
    await tester.pump();

    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });
}
