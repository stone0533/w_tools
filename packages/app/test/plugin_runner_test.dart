import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_app/w_tools_app.dart';

class _RecorderPlugin extends WAppPlugin {
  _RecorderPlugin(this.name, {required this.log, this.dependsOn = const []});

  @override
  final String name;

  @override
  final List<String> dependsOn;

  final List<String> log;

  @override
  Future<void> onInit() async => log.add(name);
}

class _GatePlugin extends WAppPlugin {
  _GatePlugin(this.name, this.started, this.gate);

  @override
  final String name;

  final List<String> started;
  final Completer<void> gate;

  @override
  Future<void> onInit() async {
    started.add(name);
    await gate.future;
  }
}

void main() {
  test('依赖的插件一定先完成 onInit（与注册顺序无关）', () async {
    final log = <String>[];
    final runner = WAppPluginRunner([
      _RecorderPlugin('service', log: log, dependsOn: ['env']),
      _RecorderPlugin('env', log: log),
    ]);

    await runner.init();
    expect(log.indexOf('env'), lessThan(log.indexOf('service')));
  });

  test('同层插件并行执行', () async {
    final started = <String>[];
    final gate = Completer<void>();
    final runner = WAppPluginRunner([
      _GatePlugin('a', started, gate),
      _GatePlugin('b', started, gate),
    ]);

    final init = runner.init();
    await Future<void>.delayed(Duration.zero);
    expect(started, containsAll(<String>['a', 'b']));

    gate.complete();
    await init;
  });

  test('多层依赖按层串行推进', () async {
    final log = <String>[];
    final runner = WAppPluginRunner([
      _RecorderPlugin('c', log: log, dependsOn: ['b']),
      _RecorderPlugin('b', log: log, dependsOn: ['a']),
      _RecorderPlugin('a', log: log),
    ]);

    await runner.init();
    expect(log, ['a', 'b', 'c']);
  });

  test('依赖未注册、循环依赖、name 重复都抛 StateError', () async {
    await expectLater(
      WAppPluginRunner([
        _RecorderPlugin('a', log: <String>[], dependsOn: ['nope']),
      ]).init(),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      WAppPluginRunner([
        _RecorderPlugin('a', log: <String>[], dependsOn: ['b']),
        _RecorderPlugin('b', log: <String>[], dependsOn: ['a']),
      ]).init(),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      WAppPluginRunner([
        _RecorderPlugin('a', log: <String>[]),
        _RecorderPlugin('a', log: <String>[]),
      ]).init(),
      throwsA(isA<StateError>()),
    );
  });

  test('init 之后不可增删插件', () async {
    final runner = WAppPluginRunner();
    await runner.init();

    expect(() => runner.addPlugin(_RecorderPlugin('p', log: <String>[])), throwsStateError);
    expect(() => runner.clearPlugins(), throwsStateError);
  });

  test('plugins 是只读视图', () {
    final runner = WAppPluginRunner([_RecorderPlugin('p', log: <String>[])]);
    expect(() => runner.plugins.clear(), throwsUnsupportedError);
  });
}
