import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:w_tools_app_getx/w_tools_app_getx.dart';

class _CountingPlugin extends WAppPlugin {
  _CountingPlugin(this.name);

  @override
  final String name;

  int initCount = 0;

  @override
  Future<void> onInit() async => initCount++;
}

class _BlockingPlugin extends WAppPlugin {
  _BlockingPlugin(this.name);

  @override
  final String name;

  final ready = Completer<void>();
  int initCount = 0;

  @override
  Future<void> onInit() async {
    initCount++;
    await ready.future;
  }
}

WApp _app({
  List<WAppPlugin> plugins = const [],
  WAppOptions? options,
}) {
  return WApp.options(
    options ??
        WAppOptions(
          title: 'test',
          home: const SizedBox.shrink(),
          plugins: plugins,
        ),
  );
}

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

  test('init() 幂等：重复调用只执行一次插件 onInit', () async {
    final plugin = _CountingPlugin('p');
    final app = _app(plugins: [plugin]);

    await app.init();
    await app.init();

    expect(plugin.initCount, 1);
  });

  test('并发 init() 共享同一次初始化', () async {
    final plugin = _BlockingPlugin('p');
    final app = _app(plugins: [plugin]);

    final first = app.init();
    final second = app.init();
    await Future<void>.delayed(Duration.zero);
    expect(plugin.initCount, 1);

    plugin.ready.complete();
    await Future.wait([first, second]);

    expect(plugin.initCount, 1);
    expect(app.isInitialized, isTrue);
  });

  test('未 init 就 run() 抛 StateError', () {
    final app = _app();

    expect(
      () => app.run(),
      throwsA(isA<StateError>()),
    );
  });

  testWidgets('start() 只能调用一次', (tester) async {
    final app = _app();

    await app.start();
    await tester.pump();
    expect(app.start(), throwsA(isA<StateError>()));
  });

  testWidgets('run() 只能调用一次', (tester) async {
    final app = _app();
    await app.init();

    app.run();
    await tester.pump();
    expect(() => app.run(), throwsA(isA<StateError>()));
  });

  test('init 之后修改插件列表抛 StateError', () async {
    final app = _app();
    await app.init();

    expect(() => app.addPlugin(_CountingPlugin('p')), throwsA(isA<StateError>()));
    expect(() => app.addPlugins([_CountingPlugin('p')]), throwsA(isA<StateError>()));
    expect(() => app.removePlugin('p'), throwsA(isA<StateError>()));
    expect(() => app.clearPlugins(), throwsA(isA<StateError>()));
  });

  test('customTasks 在 init 内并行执行', () async {
    final app = _app();
    final first = Completer<void>();
    final second = Completer<void>();
    var firstDone = false;
    var secondDone = false;

    final init = app.init(
      customTasks: [
        first.future.then((_) => firstDone = true),
        second.future.then((_) => secondDone = true),
      ],
    );
    await Future<void>.delayed(Duration.zero);

    expect(firstDone, isFalse);
    expect(secondDone, isFalse);

    first.complete();
    await Future<void>.delayed(Duration.zero);
    expect(firstDone, isTrue);
    expect(secondDone, isFalse);

    second.complete();
    await init;
    expect(secondDone, isTrue);
  });

  testWidgets('onLazyInit 在首帧后执行', (tester) async {
    final app = _app();
    var lazyCalled = false;

    await app.start(onLazyInit: () => lazyCalled = true);
    await tester.pump();
    expect(lazyCalled, isTrue);
  });

  testWidgets('changeLanguage 使用局部刷新，不触发全树 reassemble', (tester) async {
    final probeKey = GlobalKey<_ReassembleProbeState>();
    final app = WApp.options(
      WAppOptions(
        title: 'test',
        home: _ReassembleProbe(key: probeKey),
        localeConfig: WLocaleConfig(
          supportedLanguages: const {'en_US': 'English', 'zh_CN': '简体中文'},
          initialLanguage: 'en_US',
        ),
      ),
    );

    await app.start();
    await tester.pumpAndSettle();
    expect(probeKey.currentState!.locale.languageCode, 'en');
    expect(probeKey.currentState!.reassembleCount, 0);

    app.language.changeLanguage('zh_CN');
    await tester.pumpAndSettle();

    expect(probeKey.currentState!.locale.languageCode, 'zh');
    expect(
      probeKey.currentState!.reassembleCount,
      0,
      reason: '切语言不应触发全树 reassemble',
    );
  });

  testWidgets('WLocaleConfig 驱动 Flutter Localizations', (tester) async {
    late Locale resolved;
    final app = WApp.options(
      WAppOptions(
        title: 'test',
        home: Builder(
          builder: (context) {
            resolved = Localizations.localeOf(context);
            return const SizedBox.shrink();
          },
        ),
        localeConfig: WLocaleConfig(
          supportedLanguages: const {'en_US': 'English', 'zh_CN': '简体中文'},
          initialLanguage: 'zh_CN',
        ),
      ),
    );

    await app.start();
    await tester.pumpAndSettle();

    expect(resolved.languageCode, 'zh');
    expect(resolved.countryCode, 'CN');
  });

  test('WApp 的语言与路由栈是实例状态', () {
    final stack = WRouteStack();
    final app = WApp.options(
      WAppOptions(
        title: 'test',
        home: const SizedBox.shrink(),
        routeStack: stack,
        localeConfig: WLocaleConfig(
          supportedLanguages: const {'en_US': 'English', 'zh_CN': '简体中文'},
          initialLanguage: 'zh_CN',
        ),
      ),
    );

    expect(app.routeStack, same(stack));
    expect(app.language.currentLanguage, 'zh_CN');
    expect(app.language.supportedLanguages.containsKey('zh_CN'), isTrue);
  });

  test('第二个 WApp 不共享语言 / 路由栈', () {
    final first = _app(
      options: WAppOptions(
        title: 'first',
        home: const SizedBox.shrink(),
        localeConfig: WLocaleConfig(
          supportedLanguages: const {'en_US': 'English', 'zh_CN': '简体中文'},
        ),
      ),
    );
    final second = _app();

    expect(first.language.changeLanguage('zh_CN'), isTrue);
    first.routeStack.addRoute(_FakeRoute('/x'));

    expect(second.language.currentLanguage, 'en_US');
    expect(second.routeStack.routes, isEmpty);
  });
}

class _FakeRoute extends Route<void> {
  _FakeRoute(this._name);

  final String _name;

  @override
  RouteSettings get settings => RouteSettings(name: _name);
}

class _ReassembleProbe extends StatefulWidget {
  const _ReassembleProbe({super.key});

  @override
  State<_ReassembleProbe> createState() => _ReassembleProbeState();
}

class _ReassembleProbeState extends State<_ReassembleProbe> {
  int reassembleCount = 0;
  late Locale locale;

  @override
  void reassemble() {
    reassembleCount++;
    super.reassemble();
  }

  @override
  Widget build(BuildContext context) {
    locale = Localizations.localeOf(context);
    return const SizedBox.shrink();
  }
}
