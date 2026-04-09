import 'dart:async';
import 'dart:collection';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

/// 队列管理类
class ToastQueueManager {
  static final Queue<Map<String, dynamic>> _queue = Queue();
  static bool _isProcessing = false;
  static const int _maxQueueLength = 10;

  /// 添加提示到队列
  static void add(Map<String, dynamic> toastData) {
    if (_queue.length >= _maxQueueLength) {
      _queue.removeFirst(); // 移除最旧的提示
    }
    _queue.add(toastData);
    if (!_isProcessing) {
      _processQueue();
    }
  }

  /// 处理队列
  static Future<void> _processQueue() async {
    _isProcessing = true;
    while (_queue.isNotEmpty) {
      final toastData = _queue.removeFirst();

      // 显示提示并等待其关闭
      final completer = Completer<void>();
      WToast.showCustomDialog(
        toastBuilder: (cancelFunc) => toastData['widget'] as Widget,
        align: toastData['align'] as Alignment?,
        duration: toastData['duration'] as Duration?,
        backgroundColor: toastData['backgroundColor'] as Color?,
        animationDuration: toastData['animationDuration'] as Duration?,
        onClose: () => completer.complete(),
      );

      // 等待提示关闭
      await completer.future;
    }
    _isProcessing = false;
  }

  /// 从队列中移除指定提示
  static void remove(String id) {
    _queue.removeWhere((item) => item['id'] == id);
  }

  /// 清空队列
  static void clear() {
    _queue.clear();
  }

  /// 获取队列长度
  static int get length => _queue.length;
}

/// 缓存管理类
class ToastWidgetCache {
  static final Map<String, Widget> _cache = {};
  static const int _maxCacheSize = 50;

  /// 获取缓存的 Widget
  static Widget get(String key, Widget Function() builder) {
    _cleanCache();
    if (!_cache.containsKey(key)) {
      _cache[key] = builder();
    }
    return _cache[key]!;
  }

  /// 清理缓存
  static void _cleanCache() {
    if (_cache.length > _maxCacheSize) {
      // 移除一半的缓存项
      final keysToRemove = _cache.keys.take(_cache.length ~/ 2).toList();
      for (final key in keysToRemove) {
        _cache.remove(key);
      }
    }
  }

  /// 清空缓存
  static void clear() {
    _cache.clear();
  }

  /// 获取缓存大小
  static int get size => _cache.length;
}

/// WToast 主题类，用于统一管理提示样式
class WToastTheme {
  final Color successColor;
  final Color errorColor;
  final Color warningColor;
  final Color messageColor;
  final TextStyle textStyle;
  final TextStyle messageTextStyle;
  final double borderRadius;
  final double padding;

  const WToastTheme({
    this.successColor = Colors.green,
    this.errorColor = Colors.red,
    this.warningColor = Colors.orange,
    this.messageColor = Colors.black38,
    this.textStyle = const TextStyle(color: Colors.black87),
    this.messageTextStyle = const TextStyle(color: Colors.white),
    this.borderRadius = 8.0,
    this.padding = 16.0,
  });

  /// 预设主题
  static const light = WToastTheme();
  static const dark = WToastTheme(
    successColor: Colors.greenAccent,
    errorColor: Colors.redAccent,
    warningColor: Colors.orangeAccent,
    messageColor: Colors.black54,
    textStyle: TextStyle(color: Colors.white),
    messageTextStyle: TextStyle(color: Colors.white),
  );
}

/// WToast 工具类，用于显示自定义对话框
///
/// 使用示例：
/// ```dart
/// // 显示成功提示
/// WToast.showSuccess('提交成功');
///
/// // 显示错误提示
/// WToast.showError('网络错误');
///
/// // 显示警告提示
/// WToast.showWarning('请检查输入');
///
/// // 显示加载提示
/// final cancel = WToast.showLoading();
/// // 关闭加载提示
/// WToast.hideLoading();
/// ```
class WToast {
  /// 显示自定义对话框（直接使用 BotToast 原生方法）
  ///
  /// @param toastBuilder 构建对话框内容的回调函数
  /// @param align 对话框对齐方式，默认居中
  /// @param onClose 对话框关闭时的回调函数
  /// @param duration 对话框显示时长
  /// @param backgroundColor 对话框背景颜色，默认半透明黑色
  /// @param animationDuration 动画时长，默认 200 毫秒
  /// @param onError 错误回调函数
  /// @return CancelFunc 用于取消对话框的函数
  static CancelFunc showCustomDialog({
    required Widget Function(CancelFunc cancelFunc) toastBuilder,
    Alignment? align,
    void Function()? onClose,
    Duration? duration,
    Color? backgroundColor,
    Duration? animationDuration = const Duration(milliseconds: 200),
    void Function(dynamic error)? onError,
  }) {
    try {
      return BotToast.showCustomLoading(
        toastBuilder: toastBuilder,
        align: align ?? Alignment.center,
        onClose: () {
          Future.delayed(const Duration(milliseconds: 1), () {
            onClose?.call();
          });
        },
        backgroundColor: backgroundColor ?? Colors.black38,
        duration: duration,
        animationDuration: animationDuration,
      );
    } catch (e) {
      // 避免在生产代码中使用 print
      // 可以替换为日志框架
      // ignore: avoid_print
      print('Error showing toast: $e');
      onError?.call(e);
      // 返回一个空的取消函数
      return () {};
    }
  }

  /// 清空所有提示队列
  static void clearQueue() {
    ToastQueueManager.clear();
  }

  /// 清空所有缓存
  static void clearCache() {
    ToastWidgetCache.clear();
  }
}

/// WToast 配置类，用于管理 WToast 的配置
///
/// 使用示例：
/// ```dart
/// // 创建配置实例并使用
/// final config = WToastConfig()
///   ..theme = WToastTheme.dark;
/// config.showSuccess('操作成功');
///
/// // 使用自定义构建器
/// final customConfig = WToastConfig()
///   ..successBuilder = (message, cancelFunc) => Container(
///         padding: EdgeInsets.all(16),
///         decoration: BoxDecoration(
///           color: Colors.blue,
///           borderRadius: BorderRadius.circular(8),
///         ),
///         child: Text(message, style: TextStyle(color: Colors.white)),
///       );
/// customConfig.showSuccess('自定义成功提示');
///
/// // 配置加载提示
/// final loadingConfig = WToastConfig()
///   ..loadingBuilder = (message, cancelFunc, dismissible) => GestureDetector(
///         onTap: dismissible ? cancelFunc : null,
///         child: Container(
///           padding: EdgeInsets.all(16),
///           decoration: BoxDecoration(
///             color: Colors.white,
///             borderRadius: BorderRadius.circular(8),
///           ),
///           child: Column(
///             mainAxisSize: MainAxisSize.min,
///             children: [
///               CircularProgressIndicator(),
///               Text(message),
///             ],
///           ),
///         ),
///       );
/// ```
class WToastConfig {
  /// 对话框显示时长
  Duration? duration = const Duration(milliseconds: 800);

  /// 对话框背景颜色
  Color? backgroundColor = Colors.black38;

  /// 对话框对齐方式
  Alignment? align = Alignment.center;

  /// 动画时长
  Duration? animationDuration = const Duration(milliseconds: 200);

  /// 主题
  WToastTheme theme = WToastTheme.light;

  /// 构建对话框内容的回调函数
  Widget Function(CancelFunc cancelFunc)? toastBuilder;

  /// 对话框关闭时的回调函数
  void Function()? onClose;

  /// 自定义成功提示 Widget 构建回调
  Widget Function(Object? message, CancelFunc cancelFunc)? successBuilder;

  /// 自定义错误提示 Widget 构建回调
  Widget Function(Object? message, CancelFunc cancelFunc)? errorBuilder;

  /// 自定义警告提示 Widget 构建回调
  Widget Function(Object? message, CancelFunc cancelFunc)? warningBuilder;

  /// 自定义加载提示 Widget 构建回调
  ///
  /// @param message 加载提示内容
  /// @param cancelFunc 取消函数，可用于手动关闭加载提示
  /// @param dismissible 是否可点击关闭
  Widget Function(Object? message, CancelFunc cancelFunc, bool dismissible)? loadingBuilder;

  // 加载状态
  CancelFunc? _loadingCancelFunc;

  /// 私有构造函数
  WToastConfig();

  /// 显示成功提示
  ///
  /// @param message 成功消息内容
  /// @param duration 显示时长，默认 2 秒
  /// @param align 对齐方式，默认居中
  /// @return CancelFunc 用于取消对话框的函数
  CancelFunc showSuccess(
    Object? message, {
    Duration? duration,
    Alignment? align,
  }) {
    // 优先使用配置中的值，如果配置中没有，则使用参数默认值
    final effectiveDuration = duration ?? this.duration ?? const Duration(seconds: 2);
    final effectiveAlign = align ?? this.align ?? Alignment.center;

    if (successBuilder != null) {
      // 使用自定义成功构建器
      return WToast.showCustomDialog(
        toastBuilder: (cancelFunc) => successBuilder!(message, cancelFunc),
        align: effectiveAlign,
        duration: effectiveDuration,
        animationDuration: animationDuration,
      );
    } else {
      throw ArgumentError('successBuilder 不能为空，请先设置 successBuilder');
    }
  }

  /// 显示错误提示
  ///
  /// @param message 错误消息内容
  /// @param duration 显示时长，默认 2 秒
  /// @param align 对齐方式，默认居中
  /// @return CancelFunc 用于取消对话框的函数
  CancelFunc showError(
    Object? message, {
    Duration? duration,
    Alignment? align,
  }) {
    // 优先使用配置中的值，如果配置中没有，则使用参数默认值
    final effectiveDuration = duration ?? this.duration ?? const Duration(seconds: 2);
    final effectiveAlign = align ?? this.align ?? Alignment.center;

    if (errorBuilder != null) {
      // 使用自定义错误构建器
      return WToast.showCustomDialog(
        toastBuilder: (cancelFunc) => errorBuilder!(message, cancelFunc),
        align: effectiveAlign,
        duration: effectiveDuration,
        animationDuration: animationDuration,
      );
    } else {
      throw ArgumentError('errorBuilder 不能为空，请先设置 errorBuilder');
    }
  }

  /// 显示警告提示
  ///
  /// @param message 警告消息内容
  /// @param duration 显示时长，默认 2 秒
  /// @param align 对齐方式，默认居中
  /// @return CancelFunc 用于取消对话框的函数
  CancelFunc showWarning(
    Object? message, {
    Duration? duration,
    Alignment? align,
  }) {
    // 优先使用配置中的值，如果配置中没有，则使用参数默认值
    final effectiveDuration = duration ?? this.duration ?? const Duration(seconds: 2);
    final effectiveAlign = align ?? this.align ?? Alignment.center;

    if (warningBuilder != null) {
      // 使用自定义警告构建器
      return WToast.showCustomDialog(
        toastBuilder: (cancelFunc) => warningBuilder!(message, cancelFunc),
        align: effectiveAlign,
        duration: effectiveDuration,
        animationDuration: animationDuration,
      );
    } else {
      throw ArgumentError('warningBuilder 不能为空，请先设置 warningBuilder');
    }
  }

  /// 显示加载提示
  ///
  /// @param message 加载提示内容
  /// @param dismissible 是否可点击关闭，默认 false
  /// @return CancelFunc 用于取消对话框的函数
  CancelFunc showLoading({
    Object? message,
    bool dismissible = false,
  }) {
    if (loadingBuilder != null) {
      // 使用自定义加载构建器
      // 先关闭之前的加载提示
      if (_loadingCancelFunc != null) {
        _loadingCancelFunc!();
      }

      // 显示新的加载提示并保存取消函数
      _loadingCancelFunc = WToast.showCustomDialog(
        toastBuilder: (cancelFunc) => loadingBuilder!(message, cancelFunc, dismissible),
        align: align,
        duration: null, // 加载提示通常没有自动消失时间
        animationDuration: animationDuration,
      );

      return _loadingCancelFunc!;
    } else {
      throw ArgumentError('loadingBuilder 不能为空，请先设置 loadingBuilder');
    }
  }

  /// 关闭加载提示
  void hideLoading() {
    // 通过变量关闭加载提示
    if (_loadingCancelFunc != null) {
      _loadingCancelFunc!();
      _loadingCancelFunc = null;
    }
  }
}
