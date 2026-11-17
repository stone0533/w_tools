import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';
import 'package:w_tools_async_ui/w_tools_async_ui.dart';

void main() {
  testWidgets('WAsyncSection 渲染 ready，失败后默认 onRetry 重新 load', (tester) async {
    var calls = 0;
    final controller = WAsyncController<String>((_) async {
      calls++;
      if (calls == 1) throw StateError('boom');
      return 'ok';
    });
    addTearDown(controller.dispose);

    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WAsyncSection<String>(
            controller: controller,
            builder: (context, data) => Text(data),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('ok'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('WAsyncSection 不自动 load', (tester) async {
    var calls = 0;
    final controller = WAsyncController<String>((_) async {
      calls++;
      return 'ok';
    });
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: WAsyncSection<String>(
          controller: controller,
          builder: (context, data) => Text(data),
        ),
      ),
    );
    await tester.pump();

    expect(calls, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('WAsyncSection emptyBuilder 覆盖空态', (tester) async {
    final controller = WAsyncController.list<String>((_) async => const <String>[]);
    addTearDown(controller.dispose);
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        home: WAsyncSection<List<String>>(
          controller: controller,
          emptyBuilder: (context) => const Text('custom empty'),
          builder: (context, data) => Text(data.join(',')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('custom empty'), findsOneWidget);
  });

  testWidgets('WAsyncSection 自定义 onRetry 覆盖 controller.load', (tester) async {
    var loadCalls = 0;
    var retryCalls = 0;
    final controller = WAsyncController<String>((_) async {
      loadCalls++;
      throw StateError('boom');
    });
    addTearDown(controller.dispose);
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        home: WAsyncSection<String>(
          controller: controller,
          onRetry: () => retryCalls++,
          builder: (context, data) => Text(data),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(retryCalls, 1);
    expect(loadCalls, 1);
  });

  testWidgets('WAsyncSection 转发 loading/error/errorBanner/refreshing builder', (tester) async {
    final loading = WAsyncController<String>((_) async => 'ok');
    addTearDown(loading.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: WAsyncSection<String>(
          controller: loading,
          loadingBuilder: (context) => const Text('custom loading'),
          builder: (context, data) => Text(data),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('custom loading'), findsOneWidget);

    final failed = WAsyncController<String>((_) async => throw StateError('boom'));
    addTearDown(failed.dispose);
    await failed.load();
    await tester.pumpWidget(
      MaterialApp(
        home: WAsyncSection<String>(
          controller: failed,
          errorBuilder: (context, error, retry) => const Text('custom error'),
          builder: (context, data) => Text(data),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('custom error'), findsOneWidget);

    final banner = WAsyncController<String>(
      (_) async => throw StateError('boom'),
      initial: const WAsyncState<String>.loading(previousData: 'old'),
    );
    addTearDown(banner.dispose);
    await banner.load();
    await tester.pumpWidget(
      MaterialApp(
        home: WAsyncSection<String>(
          controller: banner,
          errorBannerBuilder: (context, error, retry) => const Text('custom banner'),
          builder: (context, data) => Text(data),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('custom banner'), findsOneWidget);

    final refreshing = WAsyncController<String>(
      (_) async => 'ok',
      initial: const WAsyncState<String>.loading(previousData: 'old'),
    );
    addTearDown(refreshing.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: WAsyncSection<String>(
          controller: refreshing,
          refreshingBuilder: (context) => const Text('custom refreshing'),
          builder: (context, data) => Text(data),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('custom refreshing'), findsOneWidget);
  });
}
