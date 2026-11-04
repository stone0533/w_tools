import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:w_tools_app/w_tools_app.dart';

/// 语言配置（支持列表 + 默认语言）。
///
/// 运行期“当前语言”仍以 `WLanguage.currentLanguage` 为唯一真源；
/// 本类只描述应用支持哪些语言、以及首次启动的默认值。
@immutable
class WLocaleConfig {
  const WLocaleConfig({required this.supportedLanguages, this.defaultLanguage});

  /// 支持的语言（语言码 -> 显示名）
  final Map<String, String> supportedLanguages;

  /// 当前语言不在支持列表时回退到的默认语言；为 null 时不做回退
  final String? defaultLanguage;
}

/// `WApp` 的不可变配置。
///
/// ```dart
/// WApp.options(
///   WAppOptions(
///     title: 'Demo',
///     initialRoute: '/',
///     getPages: [GetPage(name: '/', page: () => const HomePage())],
///   ),
/// ).start();
/// ```
///
/// 优先级：`start()` / 显式参数 > **本对象** > 已弃用字段 > 默认值。
@immutable
class WAppOptions {
  const WAppOptions({
    required this.title,
    this.initialRoute,
    this.getPages,
    this.theme,
    this.translations,
    this.locale,
    this.fallbackLocale,
    this.builder,
    this.navigatorObservers,
    this.defaultTransition,
    this.systemUiOverlayStyle = const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    this.orientations = const [DeviceOrientation.portraitUp],
    this.applyOrientations = false,
    this.appWrapper,
    this.localeConfig,
    this.plugins = const [],
  });

  final String title;
  final String? initialRoute;
  final List<GetPage<dynamic>>? getPages;
  final ThemeData? theme;
  final Translations? translations;
  final Locale? locale;
  final Locale? fallbackLocale;
  final TransitionBuilder? builder;
  final List<NavigatorObserver>? navigatorObservers;
  final Transition? defaultTransition;
  final SystemUiOverlayStyle? systemUiOverlayStyle;
  final List<DeviceOrientation> orientations;

  /// 是否在启动时设置 [orientations]；默认 false，避免通用启动器篡改宿主方向。
  final bool applyOrientations;
  final Widget Function(Widget child)? appWrapper;
  final WLocaleConfig? localeConfig;
  final List<WAppPlugin> plugins;

  static const Object _unset = Object();

  /// 创建副本；传 `null` 可清空可空字段
  WAppOptions copyWith({
    String? title,
    Object? initialRoute = _unset,
    Object? getPages = _unset,
    Object? theme = _unset,
    Object? translations = _unset,
    Object? locale = _unset,
    Object? fallbackLocale = _unset,
    Object? builder = _unset,
    Object? navigatorObservers = _unset,
    Object? defaultTransition = _unset,
    Object? systemUiOverlayStyle = _unset,
    List<DeviceOrientation>? orientations,
    bool? applyOrientations,
    Object? appWrapper = _unset,
    Object? localeConfig = _unset,
    List<WAppPlugin>? plugins,
  }) {
    return WAppOptions(
      title: title ?? this.title,
      initialRoute: identical(initialRoute, _unset) ? this.initialRoute : initialRoute as String?,
      getPages: identical(getPages, _unset) ? this.getPages : getPages as List<GetPage<dynamic>>?,
      theme: identical(theme, _unset) ? this.theme : theme as ThemeData?,
      translations: identical(translations, _unset)
          ? this.translations
          : translations as Translations?,
      locale: identical(locale, _unset) ? this.locale : locale as Locale?,
      fallbackLocale: identical(fallbackLocale, _unset)
          ? this.fallbackLocale
          : fallbackLocale as Locale?,
      builder: identical(builder, _unset) ? this.builder : builder as TransitionBuilder?,
      navigatorObservers: identical(navigatorObservers, _unset)
          ? this.navigatorObservers
          : navigatorObservers as List<NavigatorObserver>?,
      defaultTransition: identical(defaultTransition, _unset)
          ? this.defaultTransition
          : defaultTransition as Transition?,
      systemUiOverlayStyle: identical(systemUiOverlayStyle, _unset)
          ? this.systemUiOverlayStyle
          : systemUiOverlayStyle as SystemUiOverlayStyle?,
      orientations: orientations ?? this.orientations,
      applyOrientations: applyOrientations ?? this.applyOrientations,
      appWrapper: identical(appWrapper, _unset)
          ? this.appWrapper
          : appWrapper as Widget Function(Widget child)?,
      localeConfig: identical(localeConfig, _unset)
          ? this.localeConfig
          : localeConfig as WLocaleConfig?,
      plugins: plugins ?? this.plugins,
    );
  }
}
