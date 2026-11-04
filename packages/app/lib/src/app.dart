import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'options.dart';
import 'plugins/app_plugin.dart';
import 'utils/app_config.dart';
import 'utils/language.dart';
import 'utils/route.dart';
import 'utils/router_observer.dart';

/// 应用初始化和运行工具类
///
/// WApp 自身只依赖 GetX；第三方能力通过两种方式注入：
/// - **字段版**（单处配置）：[appWrapper]、[builder]、[navigatorObservers]
/// - **插件版**（可复用/可组合）：[addPlugin] / [addPlugins] + [WAppPlugin]
///
/// ```dart
/// void main() {
///   WApp.options(
///     WAppOptions(
///       title: 'Demo',
///       initialRoute: '/',
///       getPages: [GetPage(name: '/', page: () => const HomePage())],
///     ),
///   ).start();
/// }
/// ```
class WApp {
  /// 用不可变 [WAppOptions] 配置
  WApp.options(this.options) {
    _plugins.addAll(options.plugins);
  }

  /// 不可变配置
  final WAppOptions options;

  // ──── 内部状态 ────

  /// 插件列表（用于第三方扩展）
  final List<WAppPlugin> _plugins = [];

  /// 本应用的路由栈（`WRouteObserver` 会写入它）
  ///
  /// 默认共享 [WRouteStack.defaultStack]（与旧静态 `WRoute` 一致）；
  /// 需要隔离时可在 `start()` 前替换成新实例。
  WRouteStack routeStack = WRouteStack.defaultStack;

  /// 是否已完成 [init]，用于 init 幂等与 [run] 前的时序校验
  bool _initialized = false;

  /// 进行中的初始化任务：并发调用共享同一次初始化
  Future<void>? _initFuture;

  /// 已注册插件（只读快照）
  List<WAppPlugin> get plugins => List.unmodifiable(_plugins);

  /// 是否已完成 [init]
  bool get isInitialized => _initialized;

  // ──── 插件管理 ────

  /// 注册单个插件（须在 [init] 之前调用；init 之后新增的插件不会执行 `onInit`）
  void addPlugin(WAppPlugin plugin) {
    _plugins.add(plugin);
  }

  /// 批量注册插件（须在 [init] 之前调用）
  void addPlugins(Iterable<WAppPlugin> plugins) {
    _plugins.addAll(plugins);
  }

  /// 按名称移除插件
  void removePlugin(String name) {
    _plugins.removeWhere((p) => p.name == name);
  }

  /// 清空所有插件
  void clearPlugins() {
    _plugins.clear();
  }

  // ──── 生命周期 ────

  /// 初始化应用（幂等：重复调用只执行一次）
  ///
  /// 并发调用会共享同一次初始化；[onLazyInit] / [customTasks] 以首次调用为准。
  /// 若初始化失败，[isInitialized] 保持 false；再次调用会重新执行插件 `onInit`。
  ///
  /// - [onLazyInit]：首帧渲染完成后的延迟初始化回调
  /// - [customTasks]：用户自定义初始化任务（与插件同层并行执行）
  Future<void> init({VoidCallback? onLazyInit, List<Future<void>>? customTasks}) {
    // 已完成：保持幂等
    if (_initialized) return Future<void>.value();

    // 语言配置：只写支持列表与默认值，运行期真源仍是 WLanguage
    final localeConfig = options.localeConfig;
    if (localeConfig != null) {
      WAppConfig.supportedLanguages = localeConfig.supportedLanguages;
      final defaultLanguage = localeConfig.defaultLanguage;
      if (defaultLanguage != null &&
          !localeConfig.supportedLanguages.containsKey(WAppConfig.currentLanguage)) {
        WAppConfig.currentLanguage = defaultLanguage;
      }
      // 让 languageStream 与真源保持一致（订阅者可能早于 init）
      WLanguage().syncFromConfig();
    }

    // 已有初始化在跑：共享同一个 Future，避免插件 onInit 被执行两次
    final pending = _initFuture;
    if (pending != null) return pending;

    late final Future<void> future;
    future =
        _doInit(
          onLazyInit: onLazyInit,
          customTasks: customTasks,
        ).whenComplete(() {
          if (identical(_initFuture, future)) {
            _initFuture = null;
          }
        });
    _initFuture = future;
    return future;
  }

  /// 实际执行初始化；只由 [init] 调用一次
  Future<void> _doInit({
    VoidCallback? onLazyInit,
    List<Future<void>>? customTasks,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. 系统设置（状态栏、屏幕方向）
    _setupSystemUI(); // 同步设置，无需 await
    await _setupOrientation(); // 需等待平台应用方向

    // 2. 插件初始化（按 dependsOn 分层：同层并行、跨层串行）
    await _initPlugins();

    // 3. 用户自定义任务
    if (customTasks != null && customTasks.isNotEmpty) {
      await Future.wait(customTasks);
    }

    // 4. 延迟初始化回调
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onLazyInit?.call();
    });

    _initialized = true;
  }

  /// 一站式启动：等价于 `await init(...)` + `run(...)`
  ///
  /// 推荐入口 —— 避免调用方遗漏 [init] 导致 .env 未加载、业务服务未就绪、
  /// 原生闪屏未保留等难以定位的时序问题。
  ///
  /// 只应调用一次；重复调用会再次执行 [run]（再次 `runApp`）。
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
  }

  /// 按 [WAppPlugin.dependsOn] 分层执行插件 [WAppPlugin.onInit]。
  ///
  /// 同一层的插件互不依赖，并行执行；下一层等待上一层全部完成。
  ///
  /// 插件 name 重复、依赖了未注册的插件、或存在循环依赖时抛出 [StateError]。
  Future<void> _initPlugins() async {
    if (_plugins.isEmpty) return;

    final names = _plugins.map((p) => p.name).toSet();
    if (names.length != _plugins.length) {
      throw StateError('插件 name 必须唯一');
    }

    // 依赖名校验：未注册的依赖永远无法满足，提前报错更易定位
    for (final plugin in _plugins) {
      for (final dependency in plugin.dependsOn) {
        if (!names.contains(dependency)) {
          throw StateError('插件 "${plugin.name}" 依赖了未注册的插件 "$dependency"');
        }
      }
    }

    final done = <String>{};
    final pending = <WAppPlugin>[..._plugins];

    while (pending.isNotEmpty) {
      final ready = pending.where((p) => p.dependsOn.every(done.contains)).toList(growable: false);
      if (ready.isEmpty) {
        throw StateError(
          '插件存在循环依赖：${pending.map((p) => p.name).join(", ")}',
        );
      }
      await Future.wait(ready.map((p) => p.onInit()));
      done.addAll(ready.map((p) => p.name));
      pending.removeWhere(ready.contains);
    }
  }

  /// 应用系统栏样式（非 Web；iOS 使用 statusBarBrightness，Android 用其余字段）
  ///
  /// 读取 [WAppOptions.systemUiOverlayStyle]，为 `null` 时不做任何设置。
  void _setupSystemUI() {
    // 显式传 null 表示不干预
    final style = options.systemUiOverlayStyle;
    if (style == null || kIsWeb) return;
    SystemChrome.setSystemUIOverlayStyle(style);
  }

  /// 设置屏幕方向（读取 [orientations] 字段）
  Future<void> _setupOrientation() async {
    await SystemChrome.setPreferredOrientations(options.orientations);
  }

  /// 运行应用
  ///
  /// 传入的参数会**覆盖**对应字段；未传则使用字段当前值。
  /// 通常由 [start] 调用一次；重复调用会再次 `runApp`，不会做防重保护。
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
    // 时序校验：插件初始化（.env、业务服务、原生闪屏等）在 init() 里完成，
    // 遗漏会导致难以定位的运行时问题，因此这里显式失败而不是静默继续。
    if (!_initialized) {
      throw StateError('run() 之前必须先 await init()，或直接使用 await start()');
    }

    // 参数校验
    final titleValue = options.title;
    if (titleValue.isEmpty) {
      throw StateError('title 不能为空');
    }

    final effectiveInitialRoute = initialRoute ?? options.initialRoute;
    if (effectiveInitialRoute == null || effectiveInitialRoute.isEmpty) {
      throw StateError('initialRoute 不能为空');
    }

    final effectiveGetPages = getPages ?? options.getPages;
    if (effectiveGetPages == null || effectiveGetPages.isEmpty) {
      throw StateError('getPages 不能为空且不能为空列表');
    }

    final effectiveTitle = titleValue;
    final effectiveDefaultTransition =
        defaultTransition ?? options.defaultTransition ?? Transition.topLevel;
    final effectiveTheme = theme ?? options.theme;
    final effectiveTranslations = translations ?? options.translations;
    // 配置了 WLocaleConfig 时，首帧语言必须跟随它，而不是系统语言
    final effectiveLocale =
        locale ??
        options.locale ??
        (options.localeConfig != null ? WLanguage().currentLocale : null);
    final effectiveFallbackLocale = fallbackLocale ?? options.fallbackLocale;

    // 构建 builder 链：插件 builderWrapper × N → 用户自定义 builder（后者更靠外）
    // ignore: prefer_function_declarations_over_variables
    final TransitionBuilder builderChain = (context, child) {
      Widget result = child ?? const SizedBox.shrink();
      for (final plugin in _plugins) {
        final b = plugin.builderWrapper;
        if (b != null) {
          result = b(context, result);
        }
      }
      final customBuilder = builder ?? options.builder;
      if (customBuilder != null) {
        result = customBuilder(context, result);
      }
      return result;
    };

    // 合并所有 navigatorObservers
    final allObservers = <NavigatorObserver>[
      ...(navigatorObservers ?? options.navigatorObservers ?? []),
      ..._plugins.expand((p) => p.navigatorObservers ?? []),
      WRouteObserver(stack: routeStack),
    ];

    // 构建 GetMaterialApp
    Widget app = GetMaterialApp(
      title: effectiveTitle,
      initialRoute: effectiveInitialRoute,
      getPages: effectiveGetPages,
      debugShowCheckedModeBanner: false,
      builder: builderChain,
      navigatorObservers: allObservers,
      translations: effectiveTranslations,
      locale: effectiveLocale,
      fallbackLocale: effectiveFallbackLocale,
      defaultTransition: effectiveDefaultTransition,
      theme: effectiveTheme,
    );

    // 由内向外逐层包裹：先 appWrapper，再由各插件的 wrapApp 在外层叠加
    final wrapper = options.appWrapper;
    app = wrapper?.call(app) ?? app;
    for (final plugin in _plugins) {
      app = plugin.wrapApp(app);
    }

    runApp(app);
  }
}
