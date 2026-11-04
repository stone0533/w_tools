import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_app/w_tools_app.dart';

class _NoopPlugin extends WAppPlugin {
  @override
  String get name => 'noop';
}

void main() {
  tearDown(() {
    WAppConfig.supportedLanguages = {'en_US': 'English'};
    WAppConfig.currentLanguage = 'en_US';
  });

  group('WAppOptions', () {
    test('copyWith 保留未指定字段，传 null 可清空', () {
      const options = WAppOptions(
        title: 'Demo',
        initialRoute: '/home',
        theme: null,
        locale: Locale('zh'),
      );

      final copy = options.copyWith(title: 'Next');
      expect(copy.title, 'Next');
      expect(copy.initialRoute, '/home');
      expect(copy.locale, const Locale('zh'));

      final cleared = options.copyWith(initialRoute: null, locale: null);
      expect(cleared.initialRoute, isNull);
      expect(cleared.locale, isNull);
    });

    test('orientations 默认不应用，显式开启才生效', () {
      const options = WAppOptions(title: 'Demo');
      expect(options.applyOrientations, isFalse);
      expect(options.orientations, const [DeviceOrientation.portraitUp]);
      final explicit = options.copyWith(
        orientations: const [DeviceOrientation.landscapeLeft],
        applyOrientations: true,
      );
      expect(explicit.orientations, const [DeviceOrientation.landscapeLeft]);
      expect(explicit.applyOrientations, isTrue);
    });

    test('WApp.options 注册 options 里的插件', () {
      final app = WApp.options(
        WAppOptions(title: 'Demo', plugins: [_NoopPlugin()]),
      );
      expect(app.plugins.map((p) => p.name), contains('noop'));
    });

    test('init 应用 WLocaleConfig，当前语言不支持时回退到默认语言', () async {
      WAppConfig.currentLanguage = 'fr_FR';
      final app = WApp.options(
        const WAppOptions(
          title: 'Demo',
          localeConfig: WLocaleConfig(
            supportedLanguages: {'zh_CN': '简体中文', 'en_US': 'English'},
            defaultLanguage: 'zh_CN',
          ),
        ),
      );

      await app.init();

      expect(WAppConfig.supportedLanguages.containsKey('zh_CN'), isTrue);
      expect(WAppConfig.currentLanguage, 'zh_CN');
    });
  });

  test('syncFromConfig 把 WAppConfig 回写到 languageStream', () {
    WAppConfig.currentLanguage = 'en_US';
    WLanguage().syncFromConfig();
    expect(WLanguage().languageStream.value, 'en_US');

    WAppConfig.currentLanguage = 'zh_CN';
    WLanguage().syncFromConfig();
    expect(WLanguage().languageStream.value, 'zh_CN');
  });

  group('WRouteStack', () {
    test('add / remove / clear', () {
      final stack = WRouteStack();
      final route = MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/a'),
        builder: (_) => const SizedBox.shrink(),
      );

      stack.addRoute(route);
      expect(stack.routes, [route]);
      stack.removeRoute(route);
      expect(stack.routes, isEmpty);

      stack.addRoute(route);
      stack.clearRoutes();
      expect(stack.routes, isEmpty);
    });

    test('WRouteObserver 写入指定实例，不污染默认栈', () {
      final stack = WRouteStack();
      final observer = WRouteObserver(stack: stack);
      final route = MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/b'),
        builder: (_) => const SizedBox.shrink(),
      );

      observer.didPush(route, null);
      expect(stack.routes, contains(route));
      expect(WRouteStack.defaultStack.routes, isNot(contains(route)));
    });
  });
}
