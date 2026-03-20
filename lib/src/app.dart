import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../w.dart';

/// 应用初始化和运行工具类
class WApp {
  /// 设计稿宽度
  late double _designWidth;

  /// 应用标题
  String? _title;

  /// 初始路由
  String? _initialRoute;

  /// 路由页面列表
  List<GetPage<dynamic>>? _getPages;

  /// 屏幕方向列表，默认仅支持竖屏
  late List<DeviceOrientation> _orientations;

  /// 环境变量文件名
  String? _envFileName;

  /// 是否关闭日志
  bool? _turnOffLog;

  /// 应用构建器
  TransitionBuilder? _builder;

  /// 导航观察者列表
  List<NavigatorObserver>? _navigatorObservers;

  /// 默认过渡动画
  Transition? _defaultTransition;

  /// 应用主题
  ThemeData? _theme;

  /// 翻译资源
  Translations? _translations;

  /// 当前语言
  Locale? _locale;

  /// fallback语言
  Locale? _fallbackLocale;

  /// 创建应用实例
  WApp() {
    _designWidth = 375;
    _orientations = [DeviceOrientation.portraitUp];
  }

  /// 设置屏幕方向
  set orientations(List<DeviceOrientation> value) {
    _orientations = value;
  }

  /// 设置环境变量文件名
  set envFileName(String value) {
    _envFileName = value;
  }

  /// 设置是否关闭日志
  set turnOffLog(bool value) {
    _turnOffLog = value;
  }

  /// 设置设计稿宽度
  set designWidth(double value) {
    _designWidth = value;
  }

  /// 设置应用标题
  set title(String value) {
    _title = value;
  }

  /// 设置初始路由
  set initialRoute(String value) {
    _initialRoute = value;
  }

  /// 设置路由页面列表
  set getPages(List<GetPage<dynamic>> value) {
    _getPages = value;
  }

  /// 设置应用构建器
  set builder(TransitionBuilder value) {
    _builder = value;
  }

  /// 设置导航观察者列表
  set navigatorObservers(List<NavigatorObserver> value) {
    _navigatorObservers = value;
  }

  /// 设置默认过渡动画
  set defaultTransition(Transition value) {
    _defaultTransition = value;
  }

  /// 设置应用主题
  set theme(ThemeData value) {
    _theme = value;
  }

  /// 设置翻译资源
  set translations(Translations value) {
    _translations = value;
  }

  /// 设置当前语言
  set locale(Locale value) {
    _locale = value;
  }

  /// 设置fallback语言
  set fallbackLocale(Locale value) {
    _fallbackLocale = value;
  }

  set dropdownIcon(Widget value) {
    WConfig.instance.dropdownIcon = value;
  }

  set radioUnselectedIcon(Widget value) {
    WConfig.instance.radioUnselectedIcon = value;
  }

  set radioSelectedIcon(Widget value) {
    WConfig.instance.radioSelectedIcon = value;
  }

  set checkboxUnselectedIcon(Widget value) {
    WConfig.instance.checkboxUnselectedIcon = value;
  }

  set checkboxSelectedIcon(Widget value) {
    WConfig.instance.checkboxSelectedIcon = value;
  }

  /// 初始化应用
  ///
  /// @param onLazyInit 延迟初始化回调函数
  /// @param customTasks 自定义初始化任务
  /// @return Future<void>
  Future<void> init({VoidCallback? onLazyInit, List<Future<void>>? customTasks}) async {
    // 优先初始化核心组件
    WidgetsFlutterBinding.ensureInitialized();

    // 构建初始化任务列表
    // 核心任务：必须先执行的任务
    final coreTasks = <Future<void>>[
      // 设置系统UI
      _setupSystemUI(),
      // 设置屏幕方向
      _setupOrientation(_orientations),
    ];

    // 执行核心任务
    await Future.wait(coreTasks);

    // 构建非核心任务列表
    final nonCoreTasks = <Future<void>>[];

    // 添加自定义任务
    if (customTasks != null && customTasks.isNotEmpty) {
      nonCoreTasks.addAll(customTasks);
    }

    // 添加加载环境变量的任务
    nonCoreTasks.add(_loadEnvFile(_envFileName));

    // 执行非核心任务
    if (nonCoreTasks.isNotEmpty) {
      await Future.wait(nonCoreTasks);
    }

    // 配置日志
    if (_turnOffLog == true) {
      WLogger.turnOff();
    }

    // 延迟初始化非关键组件
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (onLazyInit != null) {
        onLazyInit();
      }
    });
  }

  /// 设置系统UI
  ///
  /// @return Future<void>
  Future<void> _setupSystemUI() async {
    if (Platform.isAndroid) {
      // 设置android状态栏为透明色
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, // 状态栏颜色设置为透明
          statusBarBrightness: Brightness.dark, // 状态栏字体颜色设置为深色
          systemNavigationBarColor: Colors.black, // 底部导航栏颜色设置为黑色
          systemNavigationBarIconBrightness: Brightness.light, // 底部导航栏图标颜色设置为浅色
        ),
      );
    }
  }

  /// 设置屏幕方向
  ///
  /// @param orientations 屏幕方向列表
  /// @return Future<void>
  Future<void> _setupOrientation(List<DeviceOrientation> orientations) async {
    await SystemChrome.setPreferredOrientations(orientations);
  }

  /// 加载环境变量文件
  ///
  /// @param envFileName 环境变量文件名
  /// @return Future<void>
  Future<void> _loadEnvFile(String? envFileName) async {
    if (envFileName?.isNotEmpty == true) {
      await dotenv.load(fileName: envFileName!);
    }
  }

  /// 运行应用
  ///
  /// @param initialRoute 初始路由
  /// @param getPages 路由页面列表
  /// @param builder 应用构建器
  /// @param navigatorObservers 导航观察者列表
  /// @param defaultTransition 默认过渡动画
  /// @param theme 应用主题
  /// @param translations 翻译资源
  /// @param locale 当前语言
  /// @param fallbackLocale fallback语言
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
    // 检查必要参数
    if (_designWidth <= 0) {
      throw Exception('designWidth 必须大于 0');
    }

    if (_title?.isEmpty ?? true) {
      throw Exception('title 不能为空');
    }

    final effectiveInitialRoute = initialRoute ?? _initialRoute;
    if (effectiveInitialRoute == null || effectiveInitialRoute.isEmpty) {
      throw Exception('initialRoute 不能为空');
    }

    final effectiveGetPages = getPages ?? _getPages;
    if (effectiveGetPages == null || effectiveGetPages.isEmpty) {
      throw Exception('getPages 不能为空且不能为空列表');
    }

    final effectiveWidth = _designWidth;
    final effectiveTitle = _title ?? '';
    final effectiveBuilder = builder ?? (_builder ?? BotToastInit());
    final effectiveNavigatorObservers =
        navigatorObservers ?? (_navigatorObservers ?? [BotToastNavigatorObserver()]);
    final effectiveDefaultTransition =
        defaultTransition ?? (_defaultTransition ?? Transition.topLevel);
    final effectiveTheme = theme ?? _theme;
    final effectiveTranslations = translations ?? _translations;
    final effectiveLocale = locale ?? _locale;
    final effectiveFallbackLocale = fallbackLocale ?? _fallbackLocale;

    runApp(
      ScreenUtilInit(
        designSize: Size(effectiveWidth, 0),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) {
          return GetMaterialApp(
            title: effectiveTitle,
            initialRoute: effectiveInitialRoute,
            getPages: effectiveGetPages,
            debugShowCheckedModeBanner: false,
            builder: effectiveBuilder,
            navigatorObservers: [...effectiveNavigatorObservers, GetXRouterObserver()],
            translations: effectiveTranslations,
            locale: effectiveLocale,
            fallbackLocale: effectiveFallbackLocale,
            defaultTransition: effectiveDefaultTransition,
            theme: effectiveTheme,
            // 优化路由生成
            onGenerateRoute: (settings) {
              final page = effectiveGetPages.firstWhere(
                (page) => page.name == settings.name,
                orElse: () => effectiveGetPages.first,
              );
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => page.page(),
              );
            },
          );
        },
      ),
    );
  }
}
