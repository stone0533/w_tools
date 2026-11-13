import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_api_example/main.dart';

void main() {
  testWidgets('分页按钮展示 items 与 hasMore', (tester) async {
    await tester.pumpWidget(const ApiExampleApp());

    await tester.tap(find.text('分页'));
    await tester.pumpAndSettle();

    expect(find.textContaining('page → 2 条'), findsOneWidget);
    expect(find.textContaining('hasMore: true'), findsOneWidget);
    expect(find.textContaining('Ada, Grace'), findsOneWidget);
  });

  testWidgets('上传按钮成功', (tester) async {
    await tester.pumpWidget(const ApiExampleApp());

    await tester.tap(find.text('上传'));
    await tester.pumpAndSettle();

    expect(find.text('上传成功'), findsOneWidget);
  });

  testWidgets('500 重试按钮最终成功', (tester) async {
    await tester.pumpWidget(const ApiExampleApp());

    await tester.tap(find.text('500 重试'));
    await tester.pumpAndSettle();

    expect(find.textContaining('/flaky → 200'), findsOneWidget);
    expect(find.textContaining('attempt: 2'), findsOneWidget);
  });
}
