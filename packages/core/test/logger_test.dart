import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_core/w_tools_core.dart';

void main() {
  group('WLogger', () {
    test('turnOff 不抛异常', () {
      WLogger.turnOff();
    });

    test('t/d/i/w/e/f 不抛异常', () {
      WLogger.t('test tag');
      WLogger.d('debug message');
      WLogger.i('info message');
      WLogger.w('warning message');
      WLogger.e('error message');
      WLogger.f('fatal message');
    });

    test('setLevel 可直接使用 core 导出的 Level', () {
      WLogger.setLevel(Level.debug);
      expect(() => WLogger.d('debug after setLevel'), returnsNormally);
      WLogger.setLevel(Level.trace);
    });
  });
}
