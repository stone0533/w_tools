import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_app_getx/w_tools_app_getx.dart';

void main() {
  // 故意不调用 TestWidgetsFlutterBinding.ensureInitialized()：
  // 纯单测里 buildRoot 要给可执行的修复提示，而不是 Framework 的断言文本。
  test('buildRoot 在没有 WidgetsBinding 时抛带修复提示的 StateError', () {
    final app = WApp.options(
      WAppOptions(
        title: 'test',
        home: const SizedBox.shrink(),
        startupLog: false,
      ),
    );

    expect(
      () => app.buildRoot(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('TestWidgetsFlutterBinding.ensureInitialized()'),
        ),
      ),
    );
  });
}
