import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_api_example/main.dart';

void main() {
  testWidgets('公开请求成功并输出脱敏日志', (tester) async {
    await tester.pumpWidget(const ApiExampleApp());
    await tester.tap(find.text('GET /public'));
    await tester.pumpAndSettle();

    expect(find.textContaining('/public → 200'), findsOneWidget);
    expect(find.textContaining('*** Request ***'), findsWidgets);
    expect(find.textContaining('set-cookie: ***'), findsWidgets);
    expect(find.textContaining('session=secret'), findsNothing);
  });

  testWidgets('500 请求会输出错误日志', (tester) async {
    await tester.pumpWidget(const ApiExampleApp());
    await tester.tap(find.text('GET /error（500）'));
    await tester.pumpAndSettle();

    expect(find.textContaining('/error → 失败'), findsOneWidget);
    expect(find.textContaining('服务器返回错误: 500'), findsOneWidget);
  });

  testWidgets('401 会刷新 token 并重试成功', (tester) async {
    await tester.pumpWidget(const ApiExampleApp());
    await tester.tap(find.text('401 → 刷新 → 重试'));
    await tester.pumpAndSettle();

    expect(find.textContaining('/secure → 200'), findsOneWidget);
    expect(find.text('当前 token：fresh-token'), findsOneWidget);
  });
}
