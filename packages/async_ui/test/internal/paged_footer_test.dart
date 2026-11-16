import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';
import 'package:w_tools_async_ui/src/paged_footer.dart';

void main() {
  Future<void> pumpStatus(WidgetTester tester, WAsyncPagedFooterStatus status) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WAsyncPagedFooter(
            status: status,
            onRetry: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('footer 渲染五种状态', (tester) async {
    await pumpStatus(tester, WAsyncPagedFooterStatus.hidden);
    expect(find.byType(SizedBox), findsWidgets);

    await pumpStatus(tester, WAsyncPagedFooterStatus.loading);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Loading...'), findsOneWidget);

    await pumpStatus(tester, WAsyncPagedFooterStatus.failed);
    expect(find.text('Load failed · Retry'), findsOneWidget);

    await pumpStatus(tester, WAsyncPagedFooterStatus.noMore);
    expect(find.text('No more data'), findsOneWidget);

    await pumpStatus(tester, WAsyncPagedFooterStatus.loadMore);
    expect(find.text('Pull up to load more'), findsOneWidget);
  });

  testWidgets('footer failed 可点击重试', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WAsyncPagedFooter(
            status: WAsyncPagedFooterStatus.failed,
            onRetry: () => retried = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Load failed · Retry'));
    expect(retried, isTrue);
  });
}
