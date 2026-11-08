import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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

  test('未显式关闭时恢复默认透明状态栏', () async {
    await _app().init();
    await Future<void>.delayed(Duration.zero);

    final styleCalls = calls
        .where((call) => call.method == 'SystemChrome.setSystemUIOverlayStyle')
        .toList();
    expect(styleCalls, hasLength(1));

    final style = SystemChrome.latestStyle;
    expect(style, isNotNull);
    expect(style!.statusBarColor, Colors.transparent);
    expect(style.systemNavigationBarColor, Colors.black);
  });

  test('WAppTheme(systemUiOverlayStyle: null) 明确不干预', () async {
    await _app(theme: const WAppTheme(systemUiOverlayStyle: null)).init();
    await Future<void>.delayed(Duration.zero);

    final styleCalls = calls
        .where((call) => call.method == 'SystemChrome.setSystemUIOverlayStyle')
        .toList();
    expect(styleCalls, isEmpty);
    expect(SystemChrome.latestStyle?.statusBarColor, Colors.red);
  });

  test('自定义 SystemUiOverlayStyle 原样应用', () async {
    await _app(
      theme: const WAppTheme(systemUiOverlayStyle: SystemUiOverlayStyle.dark),
    ).init();
    await Future<void>.delayed(Duration.zero);

    final styleCalls = calls
        .where((call) => call.method == 'SystemChrome.setSystemUIOverlayStyle')
        .toList();
    expect(styleCalls, hasLength(1));
    expect(SystemChrome.latestStyle, SystemUiOverlayStyle.dark);
  });
}
