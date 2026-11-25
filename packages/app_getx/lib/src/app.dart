import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'package:w_tools_app/w_tools_app.dart';
import 'options.dart';
import 'routing/route_observer.dart';
import 'routing/route_stack.dart';
import 'startup_report.dart';

/// 应用初始化和运行工具类。
///
/// WApp 自身只依赖 GetX 与 `w_tools_app` 的插件契约：
/// - **字段版**（单处配置）：[appWrapper]、[builder]、[navigatorObservers]
/// - **插件版**（初始化 + `navigatorObservers`）：`WAppPlugin` / `dependsOn`
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
      _pluginRunner = WAppPluginRunner(
        options.plugins,
        _startupLogEnabledFor(options),
      );

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
  bool _languageListenerAttached = false;
  WAppStartupReport? _startupReport;

  /// 已注册插件（只读视图）。
  List<WAppPlugin> get plugins => _pluginRunner.plugins;

  /// 是否已完成 [init]。
  bool get isInitialized => _initialized;

  /// 最近一次启动的耗时与插件结果；`init` 前为 null（失败时也有）。
  WAppStartupReport? get startupReport => _startupReport;

  /// 启动期日志是否打开（[WAppOptions.startupLog]，null 时跟随 debug）。
  bool get _startupLogEnabled => _startupLogEnabledFor(options);

  /// 读取当前应用树里的 [WApp]；没有 scope 时返回 null。
  static WApp? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WAppScope>()?.app;

  /// 读取当前应用树里的 [WApp]；没有 scope 时抛 [FlutterError]。
  ///
  /// `WApp.run()` 会自动注入 [WAppScope]；页面里用本方法代替全局 `app` 变量。
  /// 测试里可以手动包一层 [WAppScope]。
  static WApp of(BuildContext context) {
    final app = maybeOf(context);
    if (app == null) {
      throw FlutterError(
        'WApp.of() 找不到 WAppScope。请在 WApp.start() 之后、应用树内使用；'
        '测试里可以手动包一层 WAppScope。',
      );
    }
    return app;
  }

  // ──── 生命周期 ────

  /// 初始化应用（幂等：重复调用只执行一次）。
  ///
  /// 并发调用会共享同一次初始化；[onLazyInit] / [customTasks] 以首次调用为准。
  /// 若插件初始化失败，[isInitialized] 保持 false；再次调用会从失败点继续
  /// （已经成功的插件不会重复执行），[customTasks] 会重新执行。
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

    final firstFrameWatch = Stopwatch()..start();
    final pluginsWatch = Stopwatch()..start();
    var customTasksDuration = Duration.zero;

    try {
      _setupSystemUI();
      await _setupOrientation();
      await _pluginRunner.init();
      pluginsWatch.stop();

      if (customTasks != null && customTasks.isNotEmpty) {
        final customWatch = Stopwatch()..start();
        try {
          await Future.wait(customTasks);
        } finally {
          customWatch.stop();
          customTasksDuration = customWatch.elapsed;
        }
      }

      _startupReport = WAppStartupReport(
        pluginRuns: _pluginRunner.runs,
        pluginsDuration: pluginsWatch.elapsed,
        customTasksDuration: customTasksDuration,
        initDuration: firstFrameWatch.elapsed,
      );
      _logStartup();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final firstFrame = firstFrameWatch.elapsed;
        _startupReport?.markFirstFrame(firstFrame);
        if (_startupLogEnabled) {
          debugPrint('[WApp] first frame ${firstFrame.inMilliseconds}ms');
        }
        unawaited(_pluginRunner.firstFrame());
        onLazyInit?.call();
      });

      _initialized = true;
    } catch (_) {
      pluginsWatch.stop();
      _startupReport = WAppStartupReport(
        pluginRuns: _pluginRunner.runs,
        pluginsDuration: pluginsWatch.elapsed,
        customTasksDuration: customTasksDuration,
        initDuration: firstFrameWatch.elapsed,
      );
      if (_startupLogEnabled) {
        debugPrint(
          '[WApp] startup failed in '
          '${firstFrameWatch.elapsed.inMilliseconds}ms',
        );
      }
      rethrow;
    }
  }

  /// 启动摘要（逐插件日志由 [WAppPluginRunner] 负责）。
  void _logStartup() {
    if (!_startupLogEnabled) return;
    final report = _startupReport;
    if (report == null) return;
    debugPrint(
      '[WApp] started in ${report.initDuration.inMilliseconds}ms '
      '（plugins ${report.pluginsDuration.inMilliseconds}ms, '
      'customTasks ${report.customTasksDuration.inMilliseconds}ms）',
    );
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
      );
    } catch (_) {
      _started = false;
      rethrow;
    }
  }

  WAppTheme get _appTheme => options.theme ?? const WAppTheme();

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
  }) {
    if (!_initialized) {
      throw StateError('run() 之前必须先 await init()，或直接使用 await start()');
    }
    if (_hasRun) {
      throw StateError('run() 只能调用一次；应用已经启动');
    }

    final root = buildRoot(
      initialRoute: initialRoute,
      getPages: getPages,
      builder: builder,
      navigatorObservers: navigatorObservers,
      defaultTransition: defaultTransition,
      theme: theme,
      translations: translations,
    );
    _hasRun = true;
    runApp(root);
  }

  /// 构建应用根 Widget（不调用 [runApp]，不要求先 [init]）。
  ///
  /// 与 [run] 使用同一套装配：`GetMaterialApp` → `appWrapper` →
  /// `WAppScope` / `WLanguageScope` → 系统栏兜底 `AnnotatedRegion`。
  /// 供 widget 测试或自定义根使用：
  ///
  /// ```dart
  /// await tester.pumpWidget(
  ///   WApp.options(options.copyWith(home: const HomeView())).buildRoot(),
  /// );
  /// ```
  ///
  /// 注意：它不执行插件初始化（需要时自行 `await app.init()`），也不标记
  /// 应用已启动；重复调用会重新构建根。
  Widget buildRoot({
    String? initialRoute,
    List<GetPage<dynamic>>? getPages,
    TransitionBuilder? builder,
    List<NavigatorObserver>? navigatorObservers,
    Transition? defaultTransition,
    ThemeData? theme,
    Translations? translations,
  }) {
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
    final appTheme = _appTheme;
    final effectiveTheme = theme ?? appTheme.light;
    final effectiveTranslations = translations ?? options.translations;
    final effectiveLocale = language.hasExplicitSelection ? language.currentLocale : null;
    final effectiveFallbackLocale = _fallbackLocale();
    final effectiveSupportedLocales = _supportedLocales(effectiveLocale);

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
      builder: builder ?? options.builder,
      navigatorObservers: allObservers,
      translations: effectiveTranslations,
      locale: effectiveLocale,
      fallbackLocale: effectiveFallbackLocale,
      supportedLocales: effectiveSupportedLocales,
      localizationsDelegates:
          options.localizationsDelegates ?? GlobalMaterialLocalizations.delegates,
      defaultTransition: effectiveDefaultTransition,
      theme: effectiveTheme,
      darkTheme: appTheme.dark,
      themeMode: appTheme.mode,
    );

    final wrapper = options.appWrapper;
    if (wrapper != null) {
      app = wrapper(app);
    }
    app = WAppScope(
      app: this,
      child: WLanguageScope(language: language, child: app),
    );

    // 全局系统栏兜底：页面自己的 WScaffold / WAppBar 标注仍优先；
    // 放在 appWrapper 之外，DevicePreview 这类 wrapper 也能覆盖。
    // 启动时那次 SystemChrome 调用保留，首帧之前不会闪回默认样式。
    final systemUiFallback = _appTheme.systemUiOverlayStyle;
    if (!kIsWeb && systemUiFallback != null) {
      app = AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemUiFallback,
        child: app,
      );
    }

    _attachLanguageListener();
    return app;
  }

  /// 挂语言监听（幂等）；[run] 与 [buildRoot] 共用，测试宿主也能切语言。
  void _attachLanguageListener() {
    if (_languageListenerAttached) return;
    _languageListenerAttached = true;
    language.languageListenable.addListener(() {
      // 只更新 GetMaterialApp 的 locale 并触发现有 GetBuilder 重建；
      // Get.updateLocale 会额外 performReassemble 整棵树，切语言成本过高。
      Get.locale = language.currentLocale;
      Get.rootController.update();
    });
  }

  Locale? _fallbackLocale() {
    final fallbackLanguage = options.localeConfig?.fallbackLanguage;
    if (fallbackLanguage == null) return null;
    return WLanguage.localeFromCode(fallbackLanguage);
  }

  List<Locale> _supportedLocales(Locale? effectiveLocale) {
    final configured = options.supportedLocales;
    final locales =
        configured ??
        options.localeConfig?.supportedLanguages.keys
            .map(WLanguage.localeFromCode)
            .toList(growable: false) ??
        const <Locale>[Locale('en', 'US')];

    if (effectiveLocale != null && !locales.contains(effectiveLocale)) {
      throw StateError(
        'supportedLocales 不包含当前语言 ${effectiveLocale.toString()}；'
        '请把它加入 WLocaleConfig.supportedLanguages 或 WAppOptions.supportedLocales',
      );
    }
    return locales;
  }
}

/// 把 [WApp] 注入子树；`WApp.run` 会自动放在应用最外层。
///
/// 页面里用 [WApp.of] 读取；测试里可以手动包一层：
///
/// ```dart
/// await tester.pumpWidget(WAppScope(app: app, child: const MyPage()));
/// ```
class WAppScope extends InheritedWidget {
  const WAppScope({super.key, required this.app, required super.child});

  /// 当前应用实例。
  final WApp app;

  @override
  bool updateShouldNotify(WAppScope oldWidget) => !identical(app, oldWidget.app);
}

/// 启动期日志开关的单一判定；构造函数与实例 getter 共用。
bool _startupLogEnabledFor(WAppOptions options) => options.startupLog ?? kDebugMode;
