import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_app/w_tools_app.dart';

/// 记录 onInit 执行情况、可声明依赖与耗时的测试插件
class _RecorderPlugin extends WAppPlugin {
  _RecorderPlugin(
    this.name, {
    required this.log,
    this.dependsOn = const [],
    this.delay = Duration.zero,
  });

  @override
  final String name;

  @override
  final List<String> dependsOn;

  final List<String> log;
  final Duration delay;

  @override
  Future<void> onInit() async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    log.add(name);
  }
}

/// 用于验证 `WAppPlugin` 可作 mixin 使用：既有基类能力，又是插件
class _BaseService {
  String get kind => 'base';
}

class _MixinPlugin extends _BaseService with WAppPlugin {
  @override
  String get name => 'mixed';

  @override
  Future<void> onInit() async {}
}

Future<void> initPlugins(List<WAppPlugin> plugins) async {
  final app = WApp()..title = 'test';
  app.addPlugins(plugins);
  await app.init();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // WApp.init() 会调用 SystemChrome（平台通道），测试里置为 no-op
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  });

  test('依赖的插件一定先完成 onInit（与注册顺序无关）', () async {
    final log = <String>[];
    await initPlugins([
      _RecorderPlugin('service', log: log, dependsOn: ['env']),
      _RecorderPlugin('env', log: log),
    ]);
    expect(log.indexOf('env'), lessThan(log.indexOf('service')));
  });

  test('同层插件并行执行', () async {
    final log = <String>[];
    final stopwatch = Stopwatch()..start();
    await initPlugins([
      _RecorderPlugin('a', log: log, delay: const Duration(milliseconds: 60)),
      _RecorderPlugin('b', log: log, delay: const Duration(milliseconds: 60)),
    ]);
    stopwatch.stop();
    expect(log.length, 2);
    // 并行：总耗时接近单个 60ms，串行则约 120ms
    expect(stopwatch.elapsedMilliseconds, lessThan(110));
  });

  test('多层依赖按层串行推进', () async {
    final log = <String>[];
    await initPlugins([
      _RecorderPlugin('c', log: log, dependsOn: ['b']),
      _RecorderPlugin('b', log: log, dependsOn: ['a']),
      _RecorderPlugin('a', log: log),
    ]);
    expect(log, ['a', 'b', 'c']);
  });

  test('依赖了未注册的插件时抛 StateError', () async {
    final log = <String>[];
    await expectLater(
      initPlugins([_RecorderPlugin('a', log: log, dependsOn: ['nope'])]),
      throwsA(isA<StateError>()),
    );
  });

  test('存在循环依赖时抛 StateError', () async {
    final log = <String>[];
    await expectLater(
      initPlugins([
        _RecorderPlugin('a', log: log, dependsOn: ['b']),
        _RecorderPlugin('b', log: log, dependsOn: ['a']),
      ]),
      throwsA(isA<StateError>()),
    );
  });

  test('插件 name 重复时抛 StateError', () async {
    final log = <String>[];
    await expectLater(
      initPlugins([
        _RecorderPlugin('a', log: log),
        _RecorderPlugin('a', log: log),
      ]),
      throwsA(isA<StateError>()),
    );
  });

  test('WAppPlugin 可作 mixin 使用（同时继承其他基类）', () async {
    final plugin = _MixinPlugin();
    expect(plugin.kind, 'base'); // 基类能力保留
    await initPlugins([plugin]); // 同时可作为插件注册
  });
}
