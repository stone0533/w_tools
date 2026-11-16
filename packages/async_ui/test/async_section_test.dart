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
}
