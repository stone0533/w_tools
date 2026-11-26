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

class _SoftCountingPlugin extends WAppPlugin {
  _SoftCountingPlugin(this.name);

  @override
  final String name;

  @override
  bool get critical => false;

  int initCount = 0;

  @override
  Future<void> onInit() async {
    initCount++;
    if (initCount == 1) throw StateError('soft boom');
  }
}

class _FlakyPlugin extends WAppPlugin {
  _FlakyPlugin(this.name);

  @override
  final String name;

  int attempts = 0;

  @override
  Future<void> onInit() async {
    attempts++;
    if (attempts == 1) throw StateError('boom');
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

  test('init 失败后可重试，已成功插件不重复执行', () async {
    final success = _CountingPlugin('a');
    final flaky = _FlakyPlugin('b');
    final app = _app(plugins: [success, flaky]);

    await expectLater(
      app.init(),
      throwsA(
        isA<WAppPluginInitException>()
            .having((e) => e.pluginName, 'pluginName', 'b')
            .having((e) => e.cause, 'cause', isA<StateError>()),
      ),
    );
    expect(success.initCount, 1);
    expect(flaky.attempts, 1);
    expect(app.isInitialized, isFalse);

    await app.init();
    expect(success.initCount, 1);
    expect(flaky.attempts, 2);
    expect(app.isInitialized, isTrue);
  });

  test('非关键插件失败后 init() 可重试：只重跑失败插件，报告只留最近一轮', () async {
    final success = _CountingPlugin('a');
    final soft = _SoftCountingPlugin('b');
    final app = _app(plugins: [success, soft]);

    await app.init();
    expect(app.isInitialized, isTrue, reason: '非关键失败不阻塞启动');
    expect(success.initCount, 1);
    expect(soft.initCount, 1);
    expect(app.startupReport!.failures.map((run) => run.name), ['b']);

    await app.init();
    expect(success.initCount, 1, reason: '已成功的插件不重复执行');
    expect(soft.initCount, 2, reason: '非关键失败插件在下次 init 重试');
    expect(app.startupReport!.failures, isEmpty, reason: '报告只反映最近一轮');

    await app.init();
    expect(soft.initCount, 2, reason: '全部成功后重复 init 不再执行');
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

  testWidgets('localeConfig.fallbackLanguage 映射为 GetX fallbackLocale', (tester) async {
    final app = WApp.options(
      WAppOptions(
        title: 'test',
        home: const SizedBox.shrink(),
        localeConfig: WLocaleConfig(
          supportedLanguages: const {'en_US': 'English', 'zh_CN': '简体中文'},
          initialLanguage: 'zh_CN',
          fallbackLanguage: 'en_US',
        ),
      ),
    );

    await app.start();
    await tester.pump();

    final materialApp = tester.widget<GetMaterialApp>(find.byType(GetMaterialApp));
    expect(materialApp.fallbackLocale, const Locale('en', 'US'));
  });

  test('supportedLocales 不包含当前语言时 run 抛 StateError', () async {
    final app = WApp.options(
      WAppOptions(
        title: 'test',
        home: const SizedBox.shrink(),
        localeConfig: WLocaleConfig(
          supportedLanguages: const {'zh_CN': '简体中文'},
        ),
        supportedLocales: const <Locale>[Locale('en', 'US')],
      ),
    );

    await app.init();
    expect(() => app.run(), throwsStateError);
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
