import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools/w_tools.dart';

void main() {
  testWidgets('WAsyncView 从 loading 到 ready', (tester) async {
    final controller = WAsyncController<List<String>>(() async => ['Ada']);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WAsyncView<List<String>>(
            state: controller.state,
            onRetry: controller.load,
            readyBuilder: (context, data) => Text(data.join(',')),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await controller.load();
    await tester.pumpAndSettle();

    expect(find.text('Ada'), findsOneWidget);
  });

  testWidgets('WAsyncView 失败后可以重试', (tester) async {
    var attempt = 0;
    final controller = WAsyncController<String>(() async {
      attempt++;
      if (attempt == 1) throw StateError('first');
      return 'ok';
    });
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WAsyncView<String>(
            state: controller.state,
            onRetry: controller.load,
            readyBuilder: (context, data) => Text(data),
          ),
        ),
      ),
    );

    await controller.load();
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsWidgets);

    await tester.tap(find.text('Retry').first);
    await tester.pumpAndSettle();
    expect(find.text('ok'), findsOneWidget);
  });
}
