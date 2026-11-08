import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:w_tools_app/w_tools_app.dart' show WAppPlugin;
import 'language/locale_config.dart';
import 'routing/route_stack.dart';
import 'theme/app_theme.dart';

/// `WApp` 的不可变配置。
///
/// ```dart
/// final app = WApp.options(
///   WAppOptions(
///     title: 'Demo',
///     home: const HomePage(),
///   ),
/// );
/// await app.start();
/// ```
///
/// 必须提供 [home]，或同时提供 [initialRoute] 与 [getPages]；
/// 配置错误会在构造时立即抛出 `ArgumentError`。
@immutable
class WAppOptions {
  WAppOptions({
    required this.title,
    this.home,
    this.initialRoute,
    List<GetPage<dynamic>>? getPages,
    Map<String, WidgetBuilder>? routes,
    this.navigatorKey,
    this.theme,
    this.translations,
    this.locale,
    this.fallbackLocale,
    List<Locale>? supportedLocales,
    this.localizationsDelegates,
    this.builder,
    List<NavigatorObserver>? navigatorObservers,
    this.defaultTransition,
    List<DeviceOrientation>? orientations,
    this.shouldApplyOrientations = false,
    this.appWrapper,
    this.localeConfig,
    List<WAppPlugin>? plugins,
    this.routeStack,
    this.unknownRoute,
  }) : getPages = getPages == null ? null : List<GetPage<dynamic>>.unmodifiable(getPages),
       routes = routes == null ? null : Map<String, WidgetBuilder>.unmodifiable(routes),
       supportedLocales = supportedLocales == null
           ? null
           : List<Locale>.unmodifiable(supportedLocales),
       navigatorObservers = navigatorObservers == null
           ? null
           : List<NavigatorObserver>.unmodifiable(navigatorObservers),
       orientations = orientations == null
           ? const <DeviceOrientation>[DeviceOrientation.portraitUp]
           : List<DeviceOrientation>.unmodifiable(orientations),
       plugins = plugins == null ? const <WAppPlugin>[] : List<WAppPlugin>.unmodifiable(plugins) {
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', '不能为空');
    }
    if (home == null && (initialRoute == null || initialRoute!.trim().isEmpty)) {
      throw ArgumentError.value(
        initialRoute,
        'initialRoute',
        'home 为 null 时必须提供非空 initialRoute',
      );
    }
    if (home == null && (this.getPages == null || this.getPages!.isEmpty)) {
      throw ArgumentError.value(
        this.getPages,
        'getPages',
        'home 为 null 时必须提供非空 getPages',
      );
    }
  }

  final String title;
  final Widget? home;
  final String? initialRoute;
  final List<GetPage<dynamic>>? getPages;
  final Map<String, WidgetBuilder>? routes;
  final GlobalKey<NavigatorState>? navigatorKey;
  final WAppTheme? theme;
  final Translations? translations;
  final Locale? locale;
  final Locale? fallbackLocale;
  final List<Locale>? supportedLocales;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final TransitionBuilder? builder;
  final List<NavigatorObserver>? navigatorObservers;
  final Transition? defaultTransition;
  final List<DeviceOrientation> orientations;

  /// 是否在启动时应用 [orientations]；默认 false。
  final bool shouldApplyOrientations;
  final Widget Function(Widget child)? appWrapper;
  final WLocaleConfig? localeConfig;
  final List<WAppPlugin> plugins;
  final WRouteStack? routeStack;
  final GetPage<dynamic>? unknownRoute;

  static const Object _unset = Object();

  /// 创建副本；传 `null` 可清空可空字段。
  WAppOptions copyWith({
    String? title,
    Object? home = _unset,
    Object? initialRoute = _unset,
    Object? getPages = _unset,
    Object? routes = _unset,
    Object? navigatorKey = _unset,
    Object? theme = _unset,
    Object? translations = _unset,
    Object? locale = _unset,
    Object? fallbackLocale = _unset,
    Object? supportedLocales = _unset,
    Object? localizationsDelegates = _unset,
    Object? builder = _unset,
    Object? navigatorObservers = _unset,
    Object? defaultTransition = _unset,
    Object? orientations = _unset,
    bool? shouldApplyOrientations,
    Object? appWrapper = _unset,
    Object? localeConfig = _unset,
    Object? plugins = _unset,
    Object? routeStack = _unset,
    Object? unknownRoute = _unset,
  }) {
    T? pick<T>(Object? value, T? current) => identical(value, _unset) ? current : value as T?;

    return WAppOptions(
      title: title ?? this.title,
      home: pick<Widget>(home, this.home),
      initialRoute: pick<String>(initialRoute, this.initialRoute),
      getPages: pick<List<GetPage<dynamic>>>(getPages, this.getPages),
      routes: pick<Map<String, WidgetBuilder>>(routes, this.routes),
      navigatorKey: pick<GlobalKey<NavigatorState>>(navigatorKey, this.navigatorKey),
      theme: pick<WAppTheme>(theme, this.theme),
      translations: pick<Translations>(translations, this.translations),
      locale: pick<Locale>(locale, this.locale),
      fallbackLocale: pick<Locale>(fallbackLocale, this.fallbackLocale),
      supportedLocales: pick<List<Locale>>(supportedLocales, this.supportedLocales),
      localizationsDelegates: identical(localizationsDelegates, _unset)
          ? this.localizationsDelegates
          : localizationsDelegates as Iterable<LocalizationsDelegate<dynamic>>?,
      builder: pick<TransitionBuilder>(builder, this.builder),
      navigatorObservers: pick<List<NavigatorObserver>>(
        navigatorObservers,
        this.navigatorObservers,
      ),
      defaultTransition: pick<Transition>(defaultTransition, this.defaultTransition),
      orientations: pick<List<DeviceOrientation>>(orientations, this.orientations),
      shouldApplyOrientations: shouldApplyOrientations ?? this.shouldApplyOrientations,
      appWrapper: pick<Widget Function(Widget)>(appWrapper, this.appWrapper),
      localeConfig: pick<WLocaleConfig>(localeConfig, this.localeConfig),
      plugins: pick<List<WAppPlugin>>(plugins, this.plugins),
      routeStack: pick<WRouteStack>(routeStack, this.routeStack),
      unknownRoute: pick<GetPage<dynamic>>(unknownRoute, this.unknownRoute),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WAppOptions &&
        other.title == title &&
        other.home == home &&
        other.initialRoute == initialRoute &&
        listEquals(other.getPages, getPages) &&
        mapEquals(other.routes, routes) &&
        other.navigatorKey == navigatorKey &&
        other.theme == theme &&
        other.translations == translations &&
        other.locale == locale &&
        other.fallbackLocale == fallbackLocale &&
        listEquals(other.supportedLocales, supportedLocales) &&
        listEquals(
          other.localizationsDelegates?.toList(growable: false),
          localizationsDelegates?.toList(growable: false),
        ) &&
        other.builder == builder &&
        listEquals(other.navigatorObservers, navigatorObservers) &&
        other.defaultTransition == defaultTransition &&
        listEquals(other.orientations, orientations) &&
        other.shouldApplyOrientations == shouldApplyOrientations &&
        other.appWrapper == appWrapper &&
        other.localeConfig == localeConfig &&
        listEquals(other.plugins, plugins) &&
        other.routeStack == routeStack &&
        other.unknownRoute == unknownRoute;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    title,
    home,
    initialRoute,
    Object.hashAll(getPages ?? const <GetPage<dynamic>>[]),
    Object.hashAll(
      routes?.entries.map((e) => Object.hash(e.key, e.value)) ?? const <int>[],
    ),
    navigatorKey,
    theme,
    translations,
    locale,
    fallbackLocale,
    Object.hashAll(supportedLocales ?? const <Locale>[]),
    localizationsDelegates == null ? null : Object.hashAll(localizationsDelegates!.cast<Object>()),
    builder,
    Object.hashAll(navigatorObservers ?? const <NavigatorObserver>[]),
    defaultTransition,
    Object.hashAll(orientations),
    shouldApplyOrientations,
    appWrapper,
    localeConfig,
    Object.hashAll(plugins),
    routeStack,
    unknownRoute,
  ]);
}
