import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:w_tools_app_getx/w_tools_app_getx.dart';

class _RecorderPlugin extends WAppPlugin {
  _RecorderPlugin(
    this.name, {
    required this.log,
    this.dependsOn = const [],
  });

  @override
  final String name;

  @override
  final List<String> dependsOn;

  final List<String> log;

  @override
  Future<void> onInit() async {
    log.add(name);
  }
}

class _BaseService {
  String get kind => 'base';
}

class _MixinPlugin extends _BaseService with WAppPlugin {
  @override
  String get name => 'mixed';

  @override
  Future<void> onInit() async {}
}

WApp _app(List<WAppPlugin> plugins, {WAppOptions? options}) => WApp.options(
  options ??
      WAppOptions(
        title: 'test',
        home: const Text('home'),
        plugins: plugins,
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

  test('依赖的插件一定先完成 onInit（与注册顺序无关）', () async {
    final log = <String>[];
    await _app([
      _RecorderPlugin('service', log: log, dependsOn: ['env']),
      _RecorderPlugin('env', log: log),
    ]).init();

    expect(log.indexOf('env'), lessThan(log.indexOf('service')));
  });

  test('多层依赖按层推进', () async {
    final log = <String>[];
    await _app([
      _RecorderPlugin('c', log: log, dependsOn: ['b']),
      _RecorderPlugin('b', log: log, dependsOn: ['a']),
      _RecorderPlugin('a', log: log),
    ]).init();

    expect(log, ['a', 'b', 'c']);
  });

  test('依赖了未注册的插件时抛 StateError', () async {
    final log = <String>[];
    await expectLater(
      _app([
        _RecorderPlugin('a', log: log, dependsOn: ['nope']),
      ]).init(),
      throwsA(isA<StateError>()),
    );
  });

  test('存在循环依赖时抛 StateError', () async {
    final log = <String>[];
    await expectLater(
      _app([
        _RecorderPlugin('a', log: log, dependsOn: ['b']),
        _RecorderPlugin('b', log: log, dependsOn: ['a']),
      ]).init(),
      throwsA(isA<StateError>()),
    );
  });

  test('插件 name 重复时抛 StateError', () async {
    final log = <String>[];
    await expectLater(
      _app([
        _RecorderPlugin('a', log: log),
        _RecorderPlugin('a', log: log),
      ]).init(),
      throwsA(isA<StateError>()),
    );
  });

  test('WAppPlugin 可作 mixin 使用（同时继承其他基类）', () async {
    final plugin = _MixinPlugin();
    expect(plugin.kind, 'base');
    await _app([plugin]).init();
  });

  testWidgets('WApp 自动追加 WRouteObserver 且不重复追加', (tester) async {
    final stack = WRouteStack();
    final app = WApp.options(
      WAppOptions(
        title: 'test',
        home: const Text('home'),
        routeStack: stack,
        navigatorObservers: [WRouteObserver(stack: stack)],
      ),
    );

    await app.start();
    await tester.pumpAndSettle();

    // 初始路由只记录一次；如果 WApp 再追加一个 observer 会变成 2。
    expect(stack.routes, hasLength(1));
  });

  testWidgets('未传 WRouteObserver 时 WApp 仍自动追加', (tester) async {
    final app = _app([]);

    await app.start();
    await tester.pumpAndSettle();

    expect(app.routeStack.routes, isNotEmpty);
  });
}
