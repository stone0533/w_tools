import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:w_tools_app_getx/w_tools_app_getx.dart';

WApp _app({WAppTheme? theme}) => WApp.options(
  WAppOptions(
    title: 'test',
    home: const SizedBox.shrink(),
    theme: theme,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;

  setUp(() async {
    Get.reset();
    Get.testMode = true;
    calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );

    // 先把 latestStyle 置成一个非默认值，避免 SystemChrome 的静态去重跳过调用。
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.red),
    );
    await Future<void>.delayed(Duration.zero);
    calls.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  List<MethodCall> styleCalls() =>
      calls.where((call) => call.method == 'SystemChrome.setSystemUIOverlayStyle').toList();

  test('默认不干预系统栏', () async {
    await _app().init();
    await Future<void>.delayed(Duration.zero);

    expect(styleCalls(), isEmpty);
    expect(SystemChrome.latestStyle?.statusBarColor, Colors.red);
  });

  test('自定义 SystemUiOverlayStyle 原样应用', () async {
    await _app(
      theme: const WAppTheme(systemUiOverlayStyle: SystemUiOverlayStyle.dark),
    ).init();
    await Future<void>.delayed(Duration.zero);

    expect(styleCalls(), hasLength(1));
    expect(SystemChrome.latestStyle, SystemUiOverlayStyle.dark);
  });

  testWidgets('systemUiOverlayStyle 作为根级兜底在首帧后生效', (tester) async {
    const fallback = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    );
    final app = _app(
      theme: const WAppTheme(systemUiOverlayStyle: fallback),
    );

    await tester.pumpWidget(app.buildRoot());
    await tester.pump();

    expect(styleCalls(), isNotEmpty);
    expect(SystemChrome.latestStyle, fallback);
  });

  testWidgets('浅色状态栏页面 pop 后回到全局兜底', (tester) async {
    const fallback = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    );
    const light = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );
    final app = _app(
      theme: const WAppTheme(systemUiOverlayStyle: fallback),
    );

    await tester.pumpWidget(app.buildRoot());
    await tester.pump();
    expect(SystemChrome.latestStyle, fallback);

    Get.to(
      () => const AnnotatedRegion<SystemUiOverlayStyle>(
        value: light,
        child: Scaffold(body: Text('detail')),
      ),
    );
    await tester.pumpAndSettle();
    expect(SystemChrome.latestStyle, light);

    Get.back();
    await tester.pumpAndSettle();
    expect(SystemChrome.latestStyle, fallback);
  });
}
