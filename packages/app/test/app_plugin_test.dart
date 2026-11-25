import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_app/w_tools_app.dart';

class _Plugin extends WAppPlugin {
  @override
  String get name => 'test';
}

class _DepPlugin extends _Plugin {
  @override
  String get name => 'service';

  @override
  List<String> get dependsOn => const ['env'];
}

class _ObserverPlugin extends _Plugin {
  @override
  String get name => 'observer';

  @override
  List<NavigatorObserver>? get navigatorObservers => <NavigatorObserver>[_NoopObserver()];
}

class _NoopObserver extends NavigatorObserver {}

void main() {
  test('WAppPlugin 默认钩子无副作用', () async {
    final plugin = _Plugin();
    expect(plugin.dependsOn, isEmpty);
    expect(plugin.navigatorObservers, isNull);
    expect(plugin.timeout, isNull);
    expect(plugin.critical, isTrue);
    await plugin.onInit();
    await plugin.onFirstFrame();
  });

  test('dependsOn 默认为空，可覆写顺序', () {
    expect(_Plugin().dependsOn, isEmpty);
    expect(_DepPlugin().dependsOn, const ['env']);
  });

  test('navigatorObservers 可覆写', () {
    expect(_ObserverPlugin().navigatorObservers, hasLength(1));
  });
}
