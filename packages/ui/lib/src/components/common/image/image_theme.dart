import 'package:flutter/widgets.dart';

/// 图片默认样式（占位符/错误占位）。
///
/// 作用域由 [WImageTheme] 提供；没有 theme 时回退到 [WImageGlobalConfig]。
@immutable
class WImageThemeData {
  const WImageThemeData({this.defaultPlaceholder, this.defaultErrorWidget});

  final Widget? defaultPlaceholder;
  final Widget? defaultErrorWidget;
}

/// 图片主题（InheritedWidget），替代无 context 的全局单例做局部覆盖。
class WImageTheme extends InheritedWidget {
  const WImageTheme({
    super.key,
    required this.data,
    required super.child,
  });

  final WImageThemeData data;

  static WImageThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WImageTheme>()?.data;

  static WImageThemeData of(BuildContext context) => maybeOf(context) ?? const WImageThemeData();

  @override
  bool updateShouldNotify(WImageTheme oldWidget) =>
      data.defaultPlaceholder != oldWidget.data.defaultPlaceholder ||
      data.defaultErrorWidget != oldWidget.data.defaultErrorWidget;
}

/// 图片全局配置类
///
/// 单例：默认占位符与缓存上限都是全局的。
/// 调用 [configure] 时会把缓存上限写入 Flutter 的 `ImageCache`
/// （`PaintingBinding`），对 asset / 网络 / base64 统一生效。
///
/// 注意：[configure] 依赖 `WidgetsBinding`，需在
/// `WidgetsFlutterBinding.ensureInitialized()` 之后调用。
class WImageGlobalConfig {
  /// 单例实例
  static final WImageGlobalConfig _instance = WImageGlobalConfig._();

  /// 工厂构造函数
  factory WImageGlobalConfig() => _instance;

  /// 私有构造函数
  WImageGlobalConfig._();

  /// 默认加载中占位符
  Widget? defaultPlaceholder;

  /// 默认错误占位符
  Widget? defaultErrorWidget;

  /// 最大缓存数量（默认与 Flutter `ImageCache` 一致）
  int maxCacheSize = 1000;

  /// 最大缓存内存（默认与 Flutter `ImageCache` 一致，单位字节）
  int maxCacheMemory = 100 * 1024 * 1024;

  /// 配置全局默认值
  void configure({
    Widget? defaultPlaceholder,
    Widget? defaultErrorWidget,
    int? maxCacheSize,
    int? maxCacheMemory,
  }) {
    this.defaultPlaceholder = defaultPlaceholder;
    this.defaultErrorWidget = defaultErrorWidget;
    if (maxCacheSize != null) this.maxCacheSize = maxCacheSize;
    if (maxCacheMemory != null) this.maxCacheMemory = maxCacheMemory;
    _applyCacheLimits();
  }

  /// 恢复默认占位符与缓存上限（测试/多实例隔离用）
  void reset() {
    defaultPlaceholder = null;
    defaultErrorWidget = null;
    maxCacheSize = 1000;
    maxCacheMemory = 100 * 1024 * 1024;
    _applyCacheLimits();
  }

  void _applyCacheLimits() {
    // 统一到 Flutter 的 ImageCache：asset / 网络解码后的位图共用同一预算
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSize = maxCacheSize;
    imageCache.maximumSizeBytes = maxCacheMemory;
  }
}
