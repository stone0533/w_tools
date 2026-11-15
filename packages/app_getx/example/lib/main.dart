// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:w_tools_app_getx/w_tools_app_getx.dart';

import 'pages/detail_page.dart';
import 'pages/home_page.dart';

/// 示例启动日志：便于观察插件依赖顺序。
final List<String> startupEvents = <String>[];

/// 路由事件：演示插件 navigatorObservers。
final ValueNotifier<List<String>> routeEvents = ValueNotifier<List<String>>(<String>[]);

class _DemoRouteObserver extends NavigatorObserver {
  void _add(String event) {
    routeEvents.value = [...routeEvents.value, event];
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _add('push ${route.settings.name ?? '(unnamed)'}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _add('pop ${route.settings.name ?? '(unnamed)'}');
  }
}

class EnvPlugin extends WAppPlugin {
  @override
  String get name => 'env';

  @override
  Future<void> onInit() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    startupEvents.add('env: loaded');
  }
}

class RouteObserverPlugin extends WAppPlugin {
  @override
  String get name => 'route-observer';

  @override
  List<NavigatorObserver>? get navigatorObservers => [_DemoRouteObserver()];
}

class FeaturePlugin extends WAppPlugin {
  @override
  String get name => 'feature';

  @override
  List<String> get dependsOn => const ['env'];

  @override
  Future<void> onInit() async {
    startupEvents.add('feature: ready');
  }
}

WApp createApp() {
  return WApp.options(
    WAppOptions(
      title: 'w_tools_app 示例',
      initialRoute: '/',
      theme: WAppTheme(
        light: ThemeData(
          colorSchemeSeed: const Color(0xFF0EA5E9),
          useMaterial3: true,
        ),
      ),
      appWrapper: (child) => RepaintBoundary(child: child),
      // 需要 Theme / MediaQuery 的全局中间件放在 builder 里。
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(secondary: Colors.amber),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      getPages: [
        GetPage(name: '/', page: () => const HomePage()),
        GetPage(name: '/detail', page: () => const DetailPage()),
      ],
      plugins: [
        RouteObserverPlugin(),
        FeaturePlugin(),
        EnvPlugin(),
      ],
      localeConfig: WLocaleConfig(
        supportedLanguages: const {'zh_CN': '简体中文', 'en_US': 'English'},
        initialLanguage: 'zh_CN',
        fallbackLanguage: 'en_US',
      ),
    ),
  );
}

Future<void> main() async {
  final instance = createApp();
  await instance.start(
    customTasks: [
      Future<void>.delayed(
        const Duration(milliseconds: 120),
        () => startupEvents.add('custom task: done'),
      ),
    ],
    onLazyInit: () => startupEvents.add('first frame: lazy init'),
  );
}
