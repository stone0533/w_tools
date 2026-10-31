import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:w_tools_app/w_tools_app.dart';

import 'pages/detail_page.dart';
import 'pages/home_page.dart';

/// 示例启动日志：便于观察插件依赖顺序。
final List<String> startupEvents = <String>[];

class EnvPlugin extends WAppPlugin {
  @override
  String get name => 'env';

  @override
  Future<void> onInit() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    startupEvents.add('env: loaded');
  }
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
  WAppConfig.supportedLanguages = {
    'zh_CN': '简体中文',
    'en_US': 'English',
  };

  return WApp()
    ..title = 'w_tools_app 示例'
    ..initialRoute = '/'
    ..theme = ThemeData(
      colorSchemeSeed: const Color(0xFF0EA5E9),
      useMaterial3: true,
    )
    ..getPages = [
      GetPage(name: '/', page: () => const HomePage()),
      GetPage(name: '/detail', page: () => const DetailPage()),
    ]
    ..addPlugins([FeaturePlugin(), EnvPlugin()]);
}

Future<void> main() async {
  await createApp().start();
}
