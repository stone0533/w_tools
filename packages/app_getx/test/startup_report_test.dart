import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:w_tools_app_getx/w_tools_app_getx.dart';

class _Plugin extends WAppPlugin {
  _Plugin(
    this.name, {
    this.failInit = false,
    this.failFirstFrame = false,
    this.log,
  });

  @override
  final String name;

  final bool failInit;
  final bool failFirstFrame;
  final List<String>? log;

  @override
  Future<void> onInit() async {
    if (failInit) throw StateError('init $name');
    log?.add('init:$name');
  }

  @override
  Future<void> onFirstFrame() async {
    log?.add('first:$name');
    if (failFirstFrame) throw StateError('first $name');
  }
}

class _RetryPlugin extends WAppPlugin {
  _RetryPlugin(this.name);

  @override
  final String name;

  bool fail = true;

  @override
  Future<void> onInit() async {
    if (fail) throw StateError('init failed');
  }
}

WApp _app({
  List<WAppPlugin> plugins = const [],
  bool? startupLog,
}) => WApp.options(
  WAppOptions(
    title: 'test',
    home: const SizedBox.shrink(),
    plugins: plugins,
    startupLog: startupLog,
  ),
);

List<String> _captureDebugPrint() {
  final logs = <String>[];
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) => logs.add(message ?? '');
  addTearDown(() => debugPrint = original);
  return logs;
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

  test('init 后 startupReport 记录插件顺序与耗时', () async {
    final app = _app(
      plugins: [_Plugin('b'), _Plugin('a')],
      startupLog: false,
    );

    await app.init();

    final report = app.startupReport!;
    expect(report.pluginRuns.map((run) => run.name), ['b', 'a']);
    expect(report.pluginRuns.every((run) => run.ok), isTrue);
    expect(report.hasFirstFrame, isFalse);
  });

  testWidgets('首帧后记录 firstFrameDuration 并调用插件 onFirstFrame', (tester) async {
    final log = <String>[];
    final app = _app(
      plugins: [
        _Plugin('a', log: log),
        _Plugin('b', log: log),
      ],
    );

    await app.start();
    await tester.pump();
    await tester.pump();

    expect(app.startupReport!.hasFirstFrame, isTrue);
    expect(app.startupReport!.firstFrameDuration, isNotNull);
    expect(log, containsAll(<String>['init:a', 'init:b', 'first:a', 'first:b']));
  });

  testWidgets('首帧钩子抛错不影响 start，也不影响其它插件', (tester) async {
    final log = <String>[];
    final app = _app(
      plugins: [
        _Plugin('a', failFirstFrame: true, log: log),
        _Plugin('b', log: log),
      ],
    );

    await app.start();
    await tester.pump();
    await tester.pump();

    expect(app.isInitialized, isTrue);
    expect(log, contains('first:b'));
  });

  test('关键插件失败：startupReport 仍可用且带失败插件名', () async {
    final app = _app(plugins: [_Plugin('ok'), _Plugin('bad', failInit: true)], startupLog: false);

    await expectLater(app.init(), throwsA(isA<WAppPluginInitException>()));

    final report = app.startupReport!;
    expect(report.failures.map((run) => run.name), ['bad']);
    expect(report.pluginRuns.first.name, 'ok');
  });

  testWidgets('startupLog 打开时输出逐插件 / 摘要 / 首帧日志', (tester) async {
    final original = debugPrint;
    final logs = <String>[];
    debugPrint = (String? message, {int? wrapWidth}) => logs.add(message ?? '');
    final app = _app(plugins: [_Plugin('a')], startupLog: true);

    try {
      await app.start();
      await tester.pump();
      await tester.pump();
    } finally {
      // widget test 的 debug 变量不变量检查在 tearDown 之前，必须就地还原。
      debugPrint = original;
    }

    expect(logs.any((line) => line.contains('plugin a') && line.contains('ok')), isTrue);
    expect(logs.any((line) => line.contains('started in')), isTrue);
    expect(logs.any((line) => line.contains('first frame')), isTrue);
  });

  test('startupLog: false 时不输出启动日志', () async {
    final logs = _captureDebugPrint();
    final app = _app(startupLog: false);

    await app.init();

    expect(logs, isEmpty);
  });

  testWidgets('start 失败后可重试，第二次成功', (tester) async {
    final plugin = _RetryPlugin('retry');
    final app = _app(plugins: [plugin], startupLog: false);

    await expectLater(app.start(), throwsA(isA<WAppPluginInitException>()));
    expect(app.startupReport!.failures.map((run) => run.name), contains('retry'));

    plugin.fail = false;
    await app.start();
    await tester.pump();
    await tester.pump();

    expect(app.isInitialized, isTrue);
    expect(app.startupReport!.pluginRuns.where((run) => run.ok), isNotEmpty);
  });

  test('启动报告是只读视图', () async {
    final app = _app(startupLog: false);
    await app.init();
    expect(() => app.startupReport!.pluginRuns.clear(), throwsUnsupportedError);
  });
}
