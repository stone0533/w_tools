import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_api_example/main.dart';

void main() {
  testWidgets('公开请求成功并输出脱敏日志', (tester) async {
    await tester.pumpWidget(const ApiExampleApp());
    await tester.tap(find.text('GET /public'));
    await tester.pumpAndSettle();

    expect(find.textContaining('/public → 200'), findsOneWidget);
    expect(find.textContaining('*** Request ***'), findsWidgets);
  });

  testWidgets('401 会刷新 token 并重试成功', (tester) async {
    await tester.pumpWidget(const ApiExampleApp());
    await tester.tap(find.text('401 → 刷新 → 重试'));
    await tester.pumpAndSettle();

    expect(find.textContaining('/secure → 200'), findsOneWidget);
    expect(find.text('当前 token：fresh-token'), findsOneWidget);
  });
}
