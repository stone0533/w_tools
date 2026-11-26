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
      _themeMode = ValueNotifier<ThemeMode>(options.theme?.mode ?? ThemeMode.system),
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
  final ValueNotifier<ThemeMode> _themeMode;
  late final _SystemLocaleObserver _systemLocaleObserver = _SystemLocaleObserver(this);

  bool _initialized = false;
  Future<void>? _initFuture;
  bool _started = false;
  bool _hasRun = false;
  bool _languageListenerAttached = false;
  VoidCallback? _languageListener;
  bool _systemLocaleObserverAttached = false;
  bool _disposed = false;

  /// 最近一轮 init 是否留下了失败的插件（非关键插件的补偿重试入口）。
  bool _hasPluginFailures = false;
  WAppStartupReport? _startupReport;

  /// 已注册插件（只读视图）。
  List<WAppPlugin> get plugins => _pluginRunner.plugins;

  /// 是否已完成 [init]。
  bool get isInitialized => _initialized;

  /// 最近一次启动的耗时与插件结果；`init` 前为 null（失败时也有）。
  WAppStartupReport? get startupReport => _startupReport;

  /// 当前主题模式（运行时可切）；初值来自 `WAppTheme.mode`。
  ///
  /// 用 `ValueListenableBuilder` 监听即可做“深色模式”开关；不持久化，
  /// 持久化归消费方（恢复时在新应用实例上先 `setThemeMode(saved)`）。
  ValueListenable<ThemeMode> get themeMode => _themeMode;

  /// 运行时切换主题模式（只更新 MaterialApp 的 `themeMode`，不重建路由）。
  void setThemeMode(ThemeMode mode) {
    _ensureAlive('setThemeMode()');
    _themeMode.value = mode;
  }

  /// 释放应用级监听（语言、系统语言、主题模式）与语言实例；幂等。
  ///
  /// 只在测试 teardown / 重建应用时调用；dispose 后 [init] / [run] /
  /// [buildRoot] / [setThemeMode] 抛 [StateError]，[language] 也不可再用。
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    final listener = _languageListener;
    if (listener != null) {
      language.languageListenable.removeListener(listener);
    }
    _languageListener = null;
    _languageListenerAttached = false;

    if (_systemLocaleObserverAttached) {
      WidgetsBinding.instance.removeObserver(_systemLocaleObserver);
      _systemLocaleObserverAttached = false;
    }

    _themeMode.dispose();
    language.dispose();
  }

  void _ensureAlive(String method) {
    if (_disposed) {
      throw StateError('$method 不能再调用：WApp 已 dispose');
    }
  }

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

  /// 初始化应用（幂等：全部成功时重复调用不做任何事）。
  ///
  /// 并发调用会共享同一次初始化；[onLazyInit] / [customTasks] 以本次调用为准。
  /// 若关键插件失败，[isInitialized] 保持 false；再次调用会从失败点继续
  /// （已经成功的插件不会重复执行），[customTasks] 会重新执行。
  /// 非关键插件失败时启动照常完成，再次调用只会重试失败的插件。
  Future<void> init({VoidCallback? onLazyInit, List<Future<void>>? customTasks}) {
    _ensureAlive('init()');
    if (_initialized && !_hasPluginFailures) return Future<void>.value();

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
    _ensureSystemLocaleObserver();
    _syncSystemLocale();

    final firstFrameWatch = Stopwatch()..start();
    final pluginsWatch = Stopwatch()..start();
    final runsBefore = _pluginRunner.runs.length;
    var customTasksDuration = Duration.zero;

    /// 本轮插件执行记录：报告只描述最近一次 init，重试不累积历史失败。
    List<WAppPluginRun> runsThisInit() =>
        _pluginRunner.runs.skip(runsBefore).toList(growable: false);

    try {
      _setupSystemUI();
      await _setupOrientation();
      await _pluginRunner.init();
      final runs = runsThisInit();
      _hasPluginFailures = runs.any((run) => !run.ok);
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
        pluginRuns: runs,
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
        _detachGetxLocaleObserver();
        onLazyInit?.call();
      });

      _initialized = true;
    } catch (_) {
      pluginsWatch.stop();
      _startupReport = WAppStartupReport(
        pluginRuns: runsThisInit(),
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
    _ensureAlive('run()');
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
  /// 应用已启动；重复调用会重新构建根。它需要已初始化的 `WidgetsBinding`
  /// （widget 测试天然满足；纯 `test()` 里先 `TestWidgetsFlutterBinding.ensureInitialized()`）。
  Widget buildRoot({
    String? initialRoute,
    List<GetPage<dynamic>>? getPages,
    TransitionBuilder? builder,
    List<NavigatorObserver>? navigatorObservers,
    Transition? defaultTransition,
    ThemeData? theme,
    Translations? translations,
  }) {
    _ensureAlive('buildRoot()');
    final binding = _maybeBinding;
    if (binding == null) {
      throw StateError(
        'buildRoot() 需要已初始化的 WidgetsBinding：widget 测试请先调用 '
        'TestWidgetsFlutterBinding.ensureInitialized()（或直接用 testWidgets），'
        '生产环境请用 WApp.start()。',
      );
    }
    _ensureSystemLocaleObserver(binding);
    _syncSystemLocale(null, binding);

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
    final effectiveLocale = language.hasExplicitSelection || language.isFollowingSystem
        ? language.currentLocale
        : null;
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

    Widget materialApp(ThemeMode mode) => GetMaterialApp(
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
      themeMode: mode,
    );

    // 主题模式是 MaterialApp 的入参：只重建到 GetMaterialApp 为止，
    // 不重建 appWrapper / scope，也不会重置 Navigator。
    Widget app = ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (context, mode, _) => materialApp(mode),
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

    binding.addPostFrameCallback((_) => _detachGetxLocaleObserver());
    _attachLanguageListener();
    return app;
  }

  /// 挂语言监听（幂等）；[run] 与 [buildRoot] 共用，测试宿主也能切语言。
  void _attachLanguageListener() {
    if (_languageListenerAttached) return;
    _languageListenerAttached = true;
    _languageListener = _onLanguageChanged;
    language.languageListenable.addListener(_languageListener!);
  }

  void _onLanguageChanged() {
    // 只更新 GetMaterialApp 的 locale 并触发现有 GetBuilder 重建；
    // Get.updateLocale 会额外 performReassemble 整棵树，切语言成本过高。
    Get.locale = language.currentLocale;
    Get.rootController.update();
  }

  /// 跟随系统时把系统语言写回 `WLanguage`。
  ///
  /// [locales] 为 null 时读当前系统列表；[binding] 供 `buildRoot()` 在拿不到
  /// 全局 binding 时报错前复用。
  void _syncSystemLocale([List<Locale>? locales, WidgetsBinding? binding]) {
    if (_disposed || !language.isFollowingSystem) return;
    final supported = _languageLocales();
    if (supported.isEmpty) return;
    final systemLocales =
        locales ?? (binding ?? WidgetsBinding.instance).platformDispatcher.locales;
    if (systemLocales.isEmpty) return;

    final resolved = basicLocaleListResolution(systemLocales, supported);
    // basicLocaleListResolution 在没有命中时会退回支持列表的第一个；
    // 有 fallbackLanguage 时用它，避免“系统是日语却显示中文”。
    final matched = systemLocales.any(
      (locale) => locale.languageCode == resolved.languageCode,
    );
    final code = matched
        ? _codeForLocale(resolved)
        : options.localeConfig?.fallbackLanguage ?? _codeForLocale(resolved);
    if (code == null || code == language.currentLanguage) return;
    language.changeLanguage(code, userSelected: false);
  }

  /// 跟随系统解析用的 Locale 列表：以 `WLocaleConfig.supportedLanguages` 为准。
  ///
  /// `WAppOptions.supportedLocales` 只覆盖 Flutter 的本地化列表，不参与解析：
  /// 它的写法（`en` / `en_US`）可能与语言码不一致，拿它解析会映射不回语言码，
  /// 表现为「系统语言变了但 `WLanguage` 不动」。
  List<Locale> _languageLocales() {
    final languages = options.localeConfig?.supportedLanguages;
    if (languages != null && languages.isNotEmpty) {
      return languages.keys.map(WLanguage.localeFromCode).toList(growable: false);
    }
    return _localeList();
  }

  /// 把解析出的 [Locale] 映射回 `supportedLanguages` 的语言码。
  ///
  /// 先按完整 Locale 匹配，再按语言码兜底（`Locale('zh')` 能映射到 `zh_CN`）。
  String? _codeForLocale(Locale locale) {
    final codes = language.supportedLanguages.keys;
    for (final code in codes) {
      if (WLanguage.localeFromCode(code) == locale) return code;
    }
    for (final code in codes) {
      if (WLanguage.localeFromCode(code).languageCode == locale.languageCode) {
        return code;
      }
    }
    return null;
  }

  void _ensureSystemLocaleObserver([WidgetsBinding? binding]) {
    if (_systemLocaleObserverAttached) return;
    (binding ?? WidgetsBinding.instance).addObserver(_systemLocaleObserver);
    _systemLocaleObserverAttached = true;
  }

  /// 摘掉 GetX 自带的系统语言观察者。
  ///
  /// `GetMaterialController.didChangeLocales` 会把 `Get.locale` 直接改成
  /// `Get.deviceLocale`（只看首选 locale，不按 `supportedLocales` 解析），并整树
  /// reassemble；这既绕过 `WLanguage` 这个唯一真源，也会覆盖用户的显式选择。
  /// 语言策略由 WApp 负责，所以首帧后把它移除；`Get.locale` 仍由
  /// `_onLanguageChanged` 维护，`GetMaterialApp` 的 `locale: Get.locale ?? locale`
  /// 会跟着变。
  void _detachGetxLocaleObserver() {
    WidgetsBinding.instance.removeObserver(Get.rootController);
  }

  Locale? _fallbackLocale() {
    final fallbackLanguage = options.localeConfig?.fallbackLanguage;
    if (fallbackLanguage == null) return null;
    return WLanguage.localeFromCode(fallbackLanguage);
  }

  List<Locale> _localeList() {
    final configured = options.supportedLocales;
    if (configured != null) return configured;
    final languages = options.localeConfig?.supportedLanguages;
    if (languages != null) {
      return languages.keys.map(WLanguage.localeFromCode).toList(growable: false);
    }
    return const <Locale>[Locale('en', 'US')];
  }

  List<Locale> _supportedLocales(Locale? effectiveLocale) {
    final locales = _localeList();
    if (effectiveLocale != null && !locales.contains(effectiveLocale)) {
      throw StateError(
        'supportedLocales 不包含当前语言 ${effectiveLocale.toString()}；'
        '请把它加入 WLocaleConfig.supportedLanguages，或让 WAppOptions.supportedLocales '
        '与语言码形态一致（例如 en_US 对应 Locale("en", "US")）',
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

extension on WApp {
  /// 当前 `WidgetsBinding`；未初始化时返回 null（纯 `test()` 里调用 `buildRoot()`）。
  WidgetsBinding? get _maybeBinding {
    try {
      return WidgetsBinding.instance;
    } on Object {
      return null;
    }
  }
}

/// 把系统语言变化转给 [WApp]。
///
/// 用私有类承接而不是让 `WApp` 自己实现 `WidgetsBindingObserver`：
/// 后者会把 `didChangeAppLifecycleState` 等方法变成 `WApp` 的公开面，
/// 而 API 快照的预算门禁看不到包外父类型的成员。
class _SystemLocaleObserver extends WidgetsBindingObserver {
  _SystemLocaleObserver(this._app);

  final WApp _app;

  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);
    _app._syncSystemLocale(locales);
  }
}
