import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_api/w_tools_api.dart';
import 'package:w_tools_api_example/main.dart';

void main() {
  testWidgets('公开请求成功并输出脱敏日志', (tester) async {
    await tester.pumpWidget(const ApiExampleApp());
    await tester.tap(find.text('GET /public'));
    await tester.pumpAndSettle();

    expect(find.textContaining('/public → 200'), findsOneWidget);
    expect(find.textContaining('*** Request ***'), findsWidgets);
    expect(find.textContaining('X-Demo-Client: api-example'), findsWidgets);
    expect(find.textContaining('set-cookie: ***'), findsWidgets);
    expect(find.textContaining('Authorization: ***'), findsWidgets);
    expect(find.textContaining('session=secret'), findsNothing);
  });

  testWidgets('500 请求会输出错误日志', (tester) async {
    await tester.pumpWidget(const ApiExampleApp());
    await tester.tap(find.text('GET /error（500）'));
    await tester.pumpAndSettle();

    expect(find.textContaining('/error → 失败'), findsOneWidget);
    expect(find.textContaining('服务器返回错误: 500'), findsOneWidget);
    expect(find.textContaining('observed: 500'), findsWidgets);
  });

  testWidgets('Repository 会写入本地缓存', (tester) async {
    await tester.pumpWidget(const ApiExampleApp());
    await tester.tap(find.text('Repository 缓存'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Repository:'), findsOneWidget);
    expect(find.textContaining('local cache:'), findsOneWidget);
  });

  testWidgets('401 会刷新 token 并重试成功', (tester) async {
    await tester.pumpWidget(const ApiExampleApp());
    await tester.tap(find.text('401 → 刷新 → 重试'));
    await tester.pumpAndSettle();

    expect(find.textContaining('/secure → 200'), findsOneWidget);
    expect(find.text('当前 token：fresh-token'), findsOneWidget);
  });

  testWidgets('公开请求不泄露 X-Demo-Secret', (tester) async {
    await tester.pumpWidget(const ApiExampleApp());
    await tester.tap(find.text('GET /public'));
    await tester.pumpAndSettle();

    expect(find.textContaining('X-Demo-Secret: demo-secret'), findsNothing);
    expect(find.textContaining('X-Demo-Secret: ***'), findsWidgets);
  });

  testWidgets('退出示例后恢复 WApiConfig.baseOptions', (tester) async {
    WApiConfig.baseOptions = BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 50),
    );

    await tester.pumpWidget(const ApiExampleApp());
    expect(
      WApiConfig.baseOptions.connectTimeout,
      const Duration(seconds: 5),
    );

    await tester.pumpWidget(const SizedBox());
    expect(
      WApiConfig.baseOptions.connectTimeout,
      const Duration(seconds: 10),
    );
    expect(
      WApiConfig.baseOptions.receiveTimeout,
      const Duration(seconds: 50),
    );
  });
}
