import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:w_tools_app_getx/w_tools_app_getx.dart';

const _supported = <String, String>{'zh_CN': '简体中文', 'en_US': 'English'};

WApp _app({WLocaleConfig? localeConfig}) => WApp.options(
  WAppOptions(
    title: 'test',
    home: const SizedBox.shrink(),
    localeConfig: localeConfig,
    startupLog: false,
  ),
);

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

  void setSystemLocales(WidgetTester tester, List<Locale> locales) {
    tester.binding.platformDispatcher.localesTestValue = locales;
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
  }

  testWidgets('followSystem：启动与系统变化都同步到语言状态', (tester) async {
    setSystemLocales(tester, const [Locale('zh', 'CN')]);

    final app = _app(
      localeConfig: WLocaleConfig(
        supportedLanguages: _supported,
        followSystem: true,
      ),
    );
    await app.init();
    await tester.pumpWidget(app.buildRoot());
    await tester.pump();

    expect(app.language.currentLanguage, 'zh_CN');
    expect(app.language.isFollowingSystem, isTrue);
    expect(app.language.hasExplicitSelection, isFalse);
    expect(Get.locale, const Locale('zh', 'CN'));
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('zh', 'CN'),
    );

    setSystemLocales(tester, const [Locale('en', 'US')]);
    await tester.pump();

    expect(app.language.currentLanguage, 'en_US');
    expect(Get.locale, const Locale('en', 'US'));
  });

  testWidgets('用户显式切语言后不再跟随系统', (tester) async {
    setSystemLocales(tester, const [Locale('zh', 'CN')]);

    final app = _app(
      localeConfig: WLocaleConfig(
        supportedLanguages: _supported,
        followSystem: true,
      ),
    );
    await app.init();
    await tester.pumpWidget(app.buildRoot());
    await tester.pump();

    app.language.changeLanguage('en_US');
    await tester.pump();
    expect(app.language.isFollowingSystem, isFalse);

    setSystemLocales(tester, const [Locale('zh', 'CN')]);
    await tester.pump();

    expect(app.language.currentLanguage, 'en_US', reason: '用户选择优先');
  });

  testWidgets('系统语言不在支持列表时退回 fallbackLanguage', (tester) async {
    setSystemLocales(tester, const [Locale('ja', 'JP')]);

    final app = _app(
      localeConfig: WLocaleConfig(
        supportedLanguages: _supported,
        fallbackLanguage: 'en_US',
        followSystem: true,
      ),
    );
    await app.init();
    await tester.pumpWidget(app.buildRoot());
    await tester.pump();

    expect(app.language.currentLanguage, 'en_US');
    expect(app.language.isFollowingSystem, isTrue);
  });

  testWidgets('followSystem: false 时启动语言来自 initialLanguage', (tester) async {
    setSystemLocales(tester, const [Locale('zh', 'CN')]);

    final app = _app(
      localeConfig: WLocaleConfig(
        supportedLanguages: _supported,
        initialLanguage: 'en_US',
      ),
    );
    await app.init();
    await tester.pumpWidget(app.buildRoot());
    await tester.pump();

    expect(app.language.currentLanguage, 'en_US');
    expect(app.language.isFollowingSystem, isFalse);
    expect(app.language.hasExplicitSelection, isTrue);
  });

  testWidgets('supportedLocales 只做 Flutter 列表：形态一致时不影响跟随', (tester) async {
    setSystemLocales(tester, const [Locale('zh', 'CN')]);

    final app = _app(
      localeConfig: WLocaleConfig(
        supportedLanguages: _supported,
        followSystem: true,
      ),
    );
    await app.init();
    await tester.pumpWidget(
      WApp.options(
        app.options.copyWith(
          supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
        ),
      ).buildRoot(),
    );
    await tester.pump();

    expect(app.language.currentLanguage, 'zh_CN');
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('zh', 'CN'),
    );
  });

  test('supportedLocales 与语言码形态不一致：语言仍跟随系统，buildRoot 报可执行的错', () async {
    final app = WApp.options(
      WAppOptions(
        title: 'test',
        home: const SizedBox.shrink(),
        localeConfig: WLocaleConfig(
          supportedLanguages: _supported,
          followSystem: true,
        ),
        supportedLocales: const [Locale('en')],
        startupLog: false,
      ),
    );

    // 解析以 localeConfig 为准（P3 硬化）：不会因为 supportedLocales 的写法而不同步。
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    TestWidgetsFlutterBinding.instance.platformDispatcher.localesTestValue = const [
      Locale('en', 'US'),
    ];
    addTearDown(
      TestWidgetsFlutterBinding.instance.platformDispatcher.clearLocalesTestValue,
    );

    await app.init();
    expect(app.language.currentLanguage, 'en_US');

    expect(
      () => app.buildRoot(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('形态一致'),
        ),
      ),
    );
  });
}
