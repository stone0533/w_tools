import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_api/w_tools_api.dart';

void main() {
  group('WApiSettings', () {
    test('baseOptions 默认超时正确', () {
      expect(
        WApiSettings.baseOptions.connectTimeout,
        const Duration(milliseconds: 10000),
      );
      expect(
        WApiSettings.baseOptions.receiveTimeout,
        const Duration(milliseconds: 50000),
      );
    });

    test('logDebugHandler / logErrorHandler 默认为 null', () {
      WApiSettings.logDebugHandler = null;
      WApiSettings.logErrorHandler = null;
      expect(WApiSettings.logDebugHandler, isNull);
      expect(WApiSettings.logErrorHandler, isNull);
    });

    test('可以注入日志回调', () {
      List<String> logs = [];
      WApiSettings.logDebugHandler = (m) => logs.add('D:$m');
      WApiSettings.logErrorHandler = (m) => logs.add('E:$m');

      WApiSettings.logDebugHandler?.call('test');
      WApiSettings.logErrorHandler?.call('error');

      expect(logs, ['D:test', 'E:error']);
      // cleanup
      WApiSettings.logDebugHandler = null;
      WApiSettings.logErrorHandler = null;
    });
  });
}
