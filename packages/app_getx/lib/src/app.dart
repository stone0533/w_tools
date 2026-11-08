import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'package:w_tools_app/w_tools_app.dart';
import 'options.dart';
import 'routing/route_observer.dart';
import 'routing/route_stack.dart';

/// 应用初始化和运行工具类。
///
/// WApp 自身只依赖 GetX 与 `w_tools_app` 的插件契约：
/// - **字段版**（单处配置）：[appWrapper]、[builder]、[navigatorObservers]
/// - **插件版**（可复用/可组合）：[addPlugin] / [addPlugins] + [WAppPlugin]
///
/// 语言与路由栈是实例状态（[language] / [routeStack]），不再使用全局单例。
///
/// ```dart
/// Future<void> main() async {
///   final app = WApp.options(
///     WAppOptions(
///       title: 'Demo',
///       home: const HomePage(),
///     ),
///   );
///   await app.start();
/// }
/// ```
class WApp {
  WApp.options(this.options)
    : language = WLanguage.fromConfig(options.localeConfig),
      routeStack = options.routeStack ?? WRouteStack(),
      _pluginRunner = WAppPluginRunner(options.plugins);

  /// 不可变配置。
  final WAppOptions options;

  /// 本应用的语言状态。
  final WLanguage language;

  /// 本应用的路由栈（[WRouteObserver] 会写入它）。
  final WRouteStack routeStack;

  final WAppPluginRunner _pluginRunner;

  bool _initialized = false;
  Future<void>? _initFuture;
  bool _started = false;
  bool _hasRun = false;

  /// 已注册插件（只读视图）。
  List<WAppPlugin> get plugins => _pluginRunner.plugins;

  /// 是否已完成 [init]。
  bool get isInitialized => _initialized;

  // ──── 插件管理 ────

  /// 注册单个插件（须在 [init] 之前调用）。
  void addPlugin(WAppPlugin plugin) => _pluginRunner.addPlugin(plugin);

  /// 批量注册插件（须在 [init] 之前调用）。
  void addPlugins(Iterable<WAppPlugin> plugins) => _pluginRunner.addPlugins(plugins);

  /// 按名称移除插件（须在 [init] 之前调用）。
  void removePlugin(String name) => _pluginRunner.removePlugin(name);

  /// 清空所有插件（须在 [init] 之前调用）。
  void clearPlugins() => _pluginRunner.clearPlugins();

  // ──── 生命周期 ────

  /// 初始化应用（幂等：重复调用只执行一次）。
  ///
  /// 并发调用会共享同一次初始化；[onLazyInit] / [customTasks] 以首次调用为准。
  /// 若初始化失败，[isInitialized] 保持 false；再次调用会重新执行插件 `onInit`。
  Future<void> init({VoidCallback? onLazyInit, List<Future<void>>? customTasks}) {
    if (_initialized) return Future<void>.value();

    final pending = _initFuture;
    if (pending != null) return pending;

    late final Future<void> future;
    future = _doInit(onLazyInit: onLazyInit, customTasks: customTasks).whenComplete(() {
      if (identical(_initFuture, future)) {
        _initFuture = null;
      }
    });
    _initFuture = future;
    return future;
  }

  Future<void> _doInit({
    VoidCallback? onLazyInit,
    List<Future<void>>? customTasks,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    _setupSystemUI();
    await _setupOrientation();
    await _pluginRunner.init();

    if (customTasks != null && customTasks.isNotEmpty) {
      await Future.wait(customTasks);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onLazyInit?.call();
    });

    _initialized = true;
  }

  /// 一站式启动：等价于 `await init(...)` + `run(...)`。
  ///
  /// 只应调用一次；重复调用抛 `StateError`。
  Future<void> start({
    VoidCallback? onLazyInit,
    List<Future<void>>? customTasks,
    String? initialRoute,
    List<GetPage<dynamic>>? getPages,
    TransitionBuilder? builder,
    List<NavigatorObserver>? navigatorObservers,
    Transition? defaultTransition,
    ThemeData? theme,
    Translations? translations,
    Locale? locale,
    Locale? fallbackLocale,
  }) async {
    if (_started) {
      throw StateError('start() 只能调用一次；应用已经启动');
    }
    _started = true;
    try {
      await init(onLazyInit: onLazyInit, customTasks: customTasks);
      run(
        initialRoute: initialRoute,
        getPages: getPages,
        builder: builder,
        navigatorObservers: navigatorObservers,
        defaultTransition: defaultTransition,
        theme: theme,
        translations: translations,
        locale: locale,
        fallbackLocale: fallbackLocale,
      );
    } catch (_) {
      _started = false;
      rethrow;
    }
  }

  void _setupSystemUI() {
    final style = options.theme?.systemUiOverlayStyle;
    if (style == null || kIsWeb) return;
    SystemChrome.setSystemUIOverlayStyle(style);
  }

  Future<void> _setupOrientation() async {
    if (!options.shouldApplyOrientations) return;
    await SystemChrome.setPreferredOrientations(options.orientations);
  }

  /// 运行应用。
  ///
  /// 必须先 [init]；只能调用一次。参数会覆盖对应 `WAppOptions` 字段。
  void run({
    String? initialRoute,
    List<GetPage<dynamic>>? getPages,
    TransitionBuilder? builder,
    List<NavigatorObserver>? navigatorObservers,
    Transition? defaultTransition,
    ThemeData? theme,
    Translations? translations,
    Locale? locale,
    Locale? fallbackLocale,
  }) {
    if (!_initialized) {
      throw StateError('run() 之前必须先 await init()，或直接使用 await start()');
    }
    if (_hasRun) {
      throw StateError('run() 只能调用一次；应用已经启动');
    }

    final title = options.title;
    if (title.trim().isEmpty) {
      throw StateError('title 不能为空');
    }

    final effectiveHome = options.home;
    final effectiveInitialRoute = initialRoute ?? options.initialRoute;
    final effectiveGetPages = getPages ?? options.getPages;

    if (effectiveHome == null &&
        (effectiveInitialRoute == null || effectiveInitialRoute.trim().isEmpty)) {
      throw StateError('home 为 null 时 initialRoute 不能为空');
    }
    if (effectiveHome == null && (effectiveGetPages == null || effectiveGetPages.isEmpty)) {
      throw StateError('home 为 null 时 getPages 不能为空且不能为空列表');
    }

    final effectiveDefaultTransition =
        defaultTransition ?? options.defaultTransition ?? Transition.topLevel;
    final appTheme = options.theme;
    final effectiveTheme = theme ?? appTheme?.light;
    final effectiveTranslations = translations ?? options.translations;
    final effectiveLocale =
        locale ?? options.locale ?? (language.hasExplicitSelection ? language.currentLocale : null);
    final effectiveFallbackLocale = fallbackLocale ?? options.fallbackLocale;

    final effectiveSupportedLocales =
        options.supportedLocales ??
        options.localeConfig?.supportedLanguages.keys
            .map(WLanguage.localeFromCode)
            .toList(growable: false);

    // 插件 builderWrapper × N → 用户自定义 builder（后者更靠外）。
    Widget builderChain(BuildContext context, Widget? child) {
      Widget result = child ?? const SizedBox.shrink();
      for (final plugin in _pluginRunner.plugins) {
        final wrapper = plugin.builderWrapper;
        if (wrapper != null) {
          result = wrapper(context, result);
        }
      }
      final customBuilder = builder ?? options.builder;
      if (customBuilder != null) {
        result = customBuilder(context, result);
      }
      return result;
    }

    final allObservers = <NavigatorObserver>[
      ...(navigatorObservers ?? options.navigatorObservers ?? const []),
      ..._pluginRunner.plugins.expand(
        (plugin) => plugin.navigatorObservers ?? const <NavigatorObserver>[],
      ),
    ];
    final hasOwnRouteObserver = allObservers.whereType<WRouteObserver>().any(
      (observer) => observer.stack == routeStack,
    );
    if (!hasOwnRouteObserver) {
      allObservers.add(WRouteObserver(stack: routeStack));
    }

    Widget app = GetMaterialApp(
      title: title,
      home: effectiveHome,
      initialRoute: effectiveInitialRoute,
      getPages: effectiveGetPages,
      routes: options.routes ?? const <String, WidgetBuilder>{},
      navigatorKey: options.navigatorKey,
      unknownRoute: options.unknownRoute,
      debugShowCheckedModeBanner: false,
      builder: builderChain,
      navigatorObservers: allObservers,
      translations: effectiveTranslations,
      locale: effectiveLocale,
      fallbackLocale: effectiveFallbackLocale,
      supportedLocales: effectiveSupportedLocales ?? const <Locale>[Locale('en', 'US')],
      localizationsDelegates:
          options.localizationsDelegates ?? GlobalMaterialLocalizations.delegates,
      defaultTransition: effectiveDefaultTransition,
      theme: effectiveTheme,
      darkTheme: appTheme?.dark,
      themeMode: appTheme?.mode ?? ThemeMode.system,
    );

    final wrapper = options.appWrapper;
    app = wrapper?.call(app) ?? app;
    for (final plugin in _pluginRunner.plugins) {
      app = plugin.wrapApp(app);
    }

    _hasRun = true;
    runApp(app);
    language.bindLocaleUpdater((locale) {
      // 只更新 GetMaterialApp 的 locale 并触发现有 GetBuilder 重建；
      // Get.updateLocale 会额外 performReassemble 整棵树，切语言成本过高。
      Get.locale = locale;
      Get.rootController.update();
    });
  }
}
