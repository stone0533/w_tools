import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:w_tools_app_getx/w_tools_app_getx.dart';

WApp _app({
  Widget? home,
  Widget Function(Widget child)? appWrapper,
  WLocaleConfig? localeConfig,
}) => WApp.options(
  WAppOptions(
    title: 'test',
    home: home ?? const SizedBox.shrink(),
    appWrapper: appWrapper,
    localeConfig: localeConfig,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    Get.testMode = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  testWidgets('页面与 appWrapper 都能通过 WApp.of / WLanguageScope.of 读取实例', (
    tester,
  ) async {
    late WApp pageApp;
    late WApp wrapperApp;
    late WLanguage pageLanguage;

    final app = _app(
      appWrapper: (child) => Builder(
        builder: (context) {
          wrapperApp = WApp.of(context);
          return child;
        },
      ),
      home: Builder(
        builder: (context) {
          pageApp = WApp.of(context);
          pageLanguage = WLanguageScope.of(context);
          return const SizedBox.shrink();
        },
      ),
    );

    await app.start();
    await tester.pumpAndSettle();

    expect(pageApp, same(app));
    expect(wrapperApp, same(app));
    expect(pageLanguage, same(app.language));
  });

  testWidgets('WAppScope 可用于隔离测试', (tester) async {
    final app = _app();
    late WApp seen;

    await tester.pumpWidget(
      WAppScope(
        app: app,
        child: Builder(
          builder: (context) {
            seen = WApp.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(seen, same(app));
  });

  testWidgets('没有 scope 时 maybeOf 返回 null、of 抛 FlutterError', (tester) async {
    late BuildContext context;

    await tester.pumpWidget(
      Builder(
        builder: (ctx) {
          context = ctx;
          return const SizedBox.shrink();
        },
      ),
    );

    expect(WApp.maybeOf(context), isNull);
    expect(() => WApp.of(context), throwsFlutterError);
  });
}
