import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'plugins/app_plugin.dart';
import 'utils/router_observer.dart';

/// 应用初始化和运行工具类
///
/// WApp 自身只依赖 GetX；第三方能力通过两种方式注入：
/// - **字段版**（单处配置）：[appWrapper]、[builder]、[navigatorObservers]
/// - **插件版**（可复用/可组合）：[addPlugin] / [addPlugins] + [WAppPlugin]
class WApp {
  // ──── 配置 ────

  /// 应用标题
  String? title;

  /// 初始路由
  String? initialRoute;

  /// 路由页面列表
  List<GetPage<dynamic>>? getPages;

  /// 屏幕方向列表，默认仅支持竖屏
  List<DeviceOrientation> orientations = [DeviceOrientation.portraitUp];

  /// 系统栏（状态栏 / 导航栏）样式，仅 Android 且非 Web 生效
  ///
  /// 默认值为透明状态栏 + 黑色导航栏；置为 `null` 表示不干预，
  /// 交由调用方或页面自行控制。
  SystemUiOverlayStyle? systemUiOverlayStyle = const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  /// 应用构建器（自定义 builder，在插件 builderWrapper 链之后叠加；两者同机制，见 [WAppPlugin.builderWrapper]）
  TransitionBuilder? builder;

  /// 导航观察者列表（自定义 observers，与插件 observers 合并）
  List<NavigatorObserver>? navigatorObservers;

  /// 默认过渡动画
  Transition? defaultTransition;

  /// 应用主题
  ThemeData? theme;

  /// 翻译资源
  Translations? translations;

  /// 当前语言
  Locale? locale;

  /// 回退语言
  Locale? fallbackLocale;

  /// 应用外层包装器
  ///
  /// 在 GetMaterialApp 之外包裹整个 app Widget，适用于需要在其外再套一层的场景
  /// （如 ScreenUtilInit、MediaQuery 覆盖等）。
  ///
  /// 叠加顺序：**先执行本字段**，之后各插件的 `wrapApp` 由内向外逐层包裹 ——
  /// 即插件位于**更外层**（多个插件时后注册者最外）。
  /// 与 [WAppPlugin.wrapApp] 是同一机制的两种入口。
  Widget Function(Widget child)? appWrapper;

  // ──── 内部状态 ────

  /// 插件列表（用于第三方扩展）
  final List<WAppPlugin> _plugins = [];

  /// 是否已完成 [init]，用于 init 幂等与 [run] 前的时序校验
  bool _initialized = false;

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
  /// - [onLazyInit]：首帧渲染完成后的延迟初始化回调
  /// - [customTasks]：用户自定义初始化任务（与插件同层并行执行）
  Future<void> init({VoidCallback? onLazyInit, List<Future<void>>? customTasks}) async {
    // 幂等：与 start() 混用或重复调用时只执行一次，避免插件 onInit 被跑两次
    if (_initialized) return;

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
      final ready = pending
          .where((p) => p.dependsOn.every(done.contains))
          .toList(growable: false);
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

  /// 应用系统栏样式（仅 Android 且非 Web 生效）
  ///
  /// 读取 [systemUiOverlayStyle]，为 `null` 时不做任何设置。
  /// `SystemChrome.setSystemUIOverlayStyle` 为同步 API，故本方法无需 `async`。
  void _setupSystemUI() {
    final style = systemUiOverlayStyle;
    if (style == null) return;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      SystemChrome.setSystemUIOverlayStyle(style);
    }
  }

  /// 设置屏幕方向（读取 [orientations] 字段）
  Future<void> _setupOrientation() async {
    await SystemChrome.setPreferredOrientations(orientations);
  }

  /// 运行应用
  ///
  /// 传入的参数会**覆盖**对应字段；未传则使用字段当前值。
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
    if (title?.isEmpty ?? true) {
      throw StateError('title 不能为空');
    }

    // 入参与字段同名，故用 this.xxx 访问字段本身
    final effectiveInitialRoute = initialRoute ?? this.initialRoute;
    if (effectiveInitialRoute == null || effectiveInitialRoute.isEmpty) {
      throw StateError('initialRoute 不能为空');
    }

    final effectiveGetPages = getPages ?? this.getPages;
    if (effectiveGetPages == null || effectiveGetPages.isEmpty) {
      throw StateError('getPages 不能为空且不能为空列表');
    }

    final effectiveTitle = title ?? '';
    final effectiveDefaultTransition =
        defaultTransition ?? (this.defaultTransition ?? Transition.topLevel);
    final effectiveTheme = theme ?? this.theme;
    final effectiveTranslations = translations ?? this.translations;
    final effectiveLocale = locale ?? this.locale;
    final effectiveFallbackLocale = fallbackLocale ?? this.fallbackLocale;

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
      final customBuilder = builder ?? this.builder;
      if (customBuilder != null) {
        result = customBuilder(context, result);
      }
      return result;
    };

    // 合并所有 navigatorObservers
    final allObservers = <NavigatorObserver>[
      ...(navigatorObservers ?? this.navigatorObservers ?? []),
      ..._plugins.expand((p) => p.navigatorObservers ?? []),
      WRouteObserver(),
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
    app = appWrapper?.call(app) ?? app;
    for (final plugin in _plugins) {
      app = plugin.wrapApp(app);
    }

    runApp(app);
  }
}
