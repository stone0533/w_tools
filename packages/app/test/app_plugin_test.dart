import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_app/w_tools_app.dart';

class _Plugin extends WAppPlugin {
  @override
  String get name => 'test';
}

void main() {
  test('WAppPlugin 默认钩子无副作用', () async {
    final plugin = _Plugin();
    expect(plugin.dependsOn, isEmpty);
    expect(plugin.navigatorObservers, isNull);
    await plugin.onInit();
    expect(plugin.wrapApp(const SizedBox.shrink()), isA<SizedBox>());
  });
}
