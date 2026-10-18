import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:w_tools_app/w_tools_app.dart';

class _CountingPlugin extends WAppPlugin {
  _CountingPlugin(this.name);

  @override
  final String name;

  int initCount = 0;

  @override
  Future<void> onInit() async => initCount++;
}

List<GetPage<dynamic>> _pages() => [
      GetPage(name: '/', page: () => const SizedBox.shrink()),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // WApp.init() 会调用 SystemChrome（平台通道），测试里置为 no-op
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  });

  test('init() 幂等：重复调用只执行一次插件 onInit', () async {
    final plugin = _CountingPlugin('p');
    final app = WApp()
      ..title = 'test'
      ..addPlugins([plugin]);

    await app.init();
    await app.init();

    expect(plugin.initCount, 1);
  });

  test('未 init 就 run() 抛 StateError（避免遗漏 init）', () {
    final app = WApp()..title = 'test';

    expect(
      () => app.run(initialRoute: '/', getPages: _pages()),
      throwsA(isA<StateError>()),
    );
  });

  // runApp 只能在 testWidgets 的测试上下文里调用，故此处用 testWidgets
  testWidgets('start() 等价于 init() + run()：插件被初始化且不再抛错', (tester) async {
    final plugin = _CountingPlugin('p');
    final app = WApp()
      ..title = 'test'
      ..addPlugins([plugin]);

    await app.start(initialRoute: '/', getPages: _pages());

    expect(plugin.initCount, 1);
  });
}
