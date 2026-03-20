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
  // 全局 loading 状态
  static CancelFunc? _loadingCancelFunc;

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

  /// 显示提示（内部方法，结合主题管理和队列管理）
  ///
  /// @param message 提示消息文本
  /// @param icon 提示图标
  /// @param iconColor 图标颜色
  /// @param duration 显示时长，默认 2 秒
  /// @param align 对齐方式，默认居中
  /// @param theme 主题，默认使用 light 主题
  /// @param animationDuration 动画时长
  /// @return CancelFunc 用于取消对话框的函数
  static CancelFunc _showToast(
    String message,
    IconData icon,
    Color iconColor, {
    Duration? duration = const Duration(seconds: 2),
    Alignment? align = Alignment.center,
    WToastTheme theme = WToastTheme.light,
    Duration? animationDuration = const Duration(milliseconds: 300),
  }) {
    assert(message.isNotEmpty, 'Message cannot be empty');
    
    // 创建缓存键
    final cacheKey = 'toast_${message.hashCode}_${icon.hashCode}_${iconColor.hashCode}_${theme.hashCode}';
    
    return _showWithWidget(
      widget: ToastWidgetCache.get(cacheKey, () => Container(
        padding: EdgeInsets.all(theme.padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(theme.borderRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 40),
            const SizedBox(height: 12),
            Text(message, style: theme.textStyle),
          ],
        ),
      )),
      align: align,
      duration: duration,
      animationDuration: animationDuration,
    );
  }

  /// 显示成功提示（使用 BotToast 原生方法 + 主题管理）
  ///
  /// @param message 成功消息文本
  /// @param duration 显示时长，默认 2 秒
  /// @param align 对齐方式，默认居中
  /// @param theme 主题，默认使用 light 主题
  /// @return CancelFunc 用于取消对话框的函数
  static CancelFunc showSuccess(String message, {
    Duration? duration = const Duration(seconds: 2),
    Alignment? align = Alignment.center,
    WToastTheme theme = WToastTheme.light,
  }) {
    return _showToast(
      message,
      Icons.check_circle,
      theme.successColor,
      duration: duration,
      align: align,
      theme: theme,
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  /// 显示错误提示（使用 BotToast 原生方法 + 主题管理）
  ///
  /// @param message 错误消息文本
  /// @param duration 显示时长，默认 2 秒
  /// @param align 对齐方式，默认居中
  /// @param theme 主题，默认使用 light 主题
  /// @return CancelFunc 用于取消对话框的函数
  static CancelFunc showError(String message, {
    Duration? duration = const Duration(seconds: 2),
    Alignment? align = Alignment.center,
    WToastTheme theme = WToastTheme.light,
  }) {
    return _showToast(
      message,
      Icons.error,
      theme.errorColor,
      duration: duration,
      align: align,
      theme: theme,
      animationDuration: const Duration(milliseconds: 400),
    );
  }

  /// 显示警告提示（使用 BotToast 原生方法 + 主题管理）
  ///
  /// @param message 警告消息文本
  /// @param duration 显示时长，默认 2 秒
  /// @param align 对齐方式，默认居中
  /// @param theme 主题，默认使用 light 主题
  /// @return CancelFunc 用于取消对话框的函数
  static CancelFunc showWarning(String message, {
    Duration? duration = const Duration(seconds: 2),
    Alignment? align = Alignment.center,
    WToastTheme theme = WToastTheme.light,
  }) {
    return _showToast(
      message,
      Icons.warning,
      theme.warningColor,
      duration: duration,
      align: align,
      theme: theme,
      animationDuration: const Duration(milliseconds: 350),
    );
  }

  /// 显示加载提示（使用 BotToast 原生方法 + 全局加载状态管理）
  ///
  /// @param message 加载提示文本，默认 "加载中..."
  /// @param dismissible 是否可点击关闭，默认 false
  /// @param theme 主题，默认使用 light 主题
  /// @return CancelFunc 用于取消对话框的函数
  static CancelFunc showLoading({
    String message = '加载中...',
    bool dismissible = false,
    WToastTheme theme = WToastTheme.light,
  }) {
    // 先关闭之前的 loading
    if (_loadingCancelFunc != null) {
      _loadingCancelFunc!();
    }
    
    _loadingCancelFunc = showCustomDialog(
      toastBuilder: (cancel) => GestureDetector(
        onTap: dismissible ? cancel : null,
        child: Container(
          padding: EdgeInsets.all(theme.padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(theme.borderRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(message, style: theme.textStyle),
            ],
          ),
        ),
      ),
      duration: null,
    );
    
    return _loadingCancelFunc!;
  }

  /// 关闭加载提示
  static void hideLoading() {
    if (_loadingCancelFunc != null) {
      _loadingCancelFunc!();
      _loadingCancelFunc = null;
    }
  }

  /// 显示带 Widget 的提示（内部方法）
  ///
  /// @param widget 要显示的 Widget
  /// @param align 对齐方式
  /// @param duration 显示时长
  /// @param backgroundColor 背景颜色
  /// @param animationDuration 动画时长
  /// @return CancelFunc 用于取消对话框的函数
  static CancelFunc _showWithWidget({
    required Widget widget,
    Alignment? align,
    Duration? duration,
    Color? backgroundColor,
    Duration? animationDuration,
  }) {
    // 添加到队列
    final toastData = {
      'widget': widget,
      'align': align,
      'duration': duration,
      'backgroundColor': backgroundColor,
      'animationDuration': animationDuration,
      'id': UniqueKey().toString(),
    };
    
    ToastQueueManager.add(toastData);
    
    // 返回一个取消函数
    return () {
      // 从队列中移除
      ToastQueueManager.remove(toastData['id'] as String);
    };
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

/// WToast 配置类，用于管理 WToast 的全局配置
///
/// 使用示例：
/// ```dart
/// // 配置并显示提示
/// WToastConfig.instance
///   ..theme = WToastTheme.dark
///   ..showSuccess('操作成功');
///
/// // 使用自定义构建器
/// WToastConfig.instance
///   ..messageBuilder = (message) => Container(
///         padding: EdgeInsets.all(16),
///         decoration: BoxDecoration(
///           color: Colors.blue,
///           borderRadius: BorderRadius.circular(8),
///         ),
///         child: Text(message, style: TextStyle(color: Colors.white)),
///       )
///   ..showMessage('自定义消息提示');
///
/// // 配置默认加载提示
/// WToastConfig.instance.setDefaultLoadingToast(
///   message: '加载中，请稍候...',
///   loadingWidget: CircularProgressIndicator(strokeWidth: 2),
/// );
/// ```
class WToastConfig {
  // 全局配置实例
  static WToastConfig? _instance;
  
  // 获取全局配置实例
  static WToastConfig get instance {
    _instance ??= WToastConfig();
    return _instance!;
  }
  
  // 重置全局配置
  static void reset() {
    _instance = null;
  }

  /// 对话框显示时长
  Duration? duration = const Duration(milliseconds: 800);

  /// 对话框背景颜色
  Color? backgroundColor = Colors.black38;

  /// 对话框对齐方式
  Alignment? align = Alignment.center;

  /// 构建对话框内容的回调函数
  Widget Function(CancelFunc cancelFunc)? toastBuilder;

  /// 对话框关闭时的回调函数
  void Function()? onClose;

  /// 动画时长
  Duration? animationDuration = const Duration(milliseconds: 200);

  /// 主题
  WToastTheme theme = WToastTheme.light;

  /// 自定义成功提示 Widget 构建回调
  Widget Function(String message)? successBuilder;

  /// 自定义错误提示 Widget 构建回调
  Widget Function(String message)? errorBuilder;

  /// 自定义警告提示 Widget 构建回调
  Widget Function(String message)? warningBuilder;

  /// 私有构造函数
  WToastConfig();

  /// 设置默认加载中对话框
  ///
  /// @param message 加载提示文本，默认 "加载中..."
  /// @param loadingWidget 加载图标，默认 CircularProgressIndicator
  /// @param backgroundColor 背景颜色，默认白色
  /// @param borderRadius 边框圆角，默认 8.0
  void setDefaultLoadingToast({
    String message = '加载中...',
    Widget? loadingWidget,
    Color? backgroundColor = Colors.white,
    double borderRadius = 8.0,
  }) {
    toastBuilder = (cancelFunc) => Container(
      padding: EdgeInsets.all(theme.padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loadingWidget ?? const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(message, style: theme.textStyle),
        ],
      ),
    );
  }

  /// 显示自定义对话框
  ///
  /// @return CancelFunc 用于取消对话框的函数
  /// @throws ArgumentError 如果 toastBuilder 为 null
  CancelFunc show() {
    if (toastBuilder == null) {
      throw ArgumentError('toastBuilder 不能为空');
    }

    return WToast.showCustomDialog(
      toastBuilder: toastBuilder!,
      align: align,
      onClose: onClose,
      backgroundColor: backgroundColor,
      duration: duration,
      animationDuration: animationDuration,
    );
  }

  /// 显示成功提示
  ///
  /// @param message 成功消息文本
  /// @param duration 显示时长，默认 2 秒
  /// @param align 对齐方式，默认居中
  /// @return CancelFunc 用于取消对话框的函数
  CancelFunc showSuccess(String message, {
    Duration? duration = const Duration(seconds: 2),
    Alignment? align = Alignment.center,
  }) {
    if (successBuilder != null) {
      // 使用自定义成功构建器
      final successWidget = successBuilder!(message);
      return WToast.showCustomDialog(
        toastBuilder: (cancelFunc) => successWidget,
        align: align,
        duration: duration,
        animationDuration: animationDuration,
      );
    } else {
      // 使用 WToast 的默认实现
      return WToast.showSuccess(
        message,
        duration: duration,
        align: align,
        theme: theme,
      );
    }
  }

  /// 显示错误提示
  ///
  /// @param message 错误消息文本
  /// @param duration 显示时长，默认 2 秒
  /// @param align 对齐方式，默认居中
  /// @return CancelFunc 用于取消对话框的函数
  CancelFunc showError(String message, {
    Duration? duration = const Duration(seconds: 2),
    Alignment? align = Alignment.center,
  }) {
    if (errorBuilder != null) {
      // 使用自定义错误构建器
      final errorWidget = errorBuilder!(message);
      return WToast.showCustomDialog(
        toastBuilder: (cancelFunc) => errorWidget,
        align: align,
        duration: duration,
        animationDuration: animationDuration,
      );
    } else {
      // 使用 WToast 的默认实现
      return WToast.showError(
        message,
        duration: duration,
        align: align,
        theme: theme,
      );
    }
  }

  /// 显示警告提示
  ///
  /// @param message 警告消息文本
  /// @param duration 显示时长，默认 2 秒
  /// @param align 对齐方式，默认居中
  /// @return CancelFunc 用于取消对话框的函数
  CancelFunc showWarning(String message, {
    Duration? duration = const Duration(seconds: 2),
    Alignment? align = Alignment.center,
  }) {
    if (warningBuilder != null) {
      // 使用自定义警告构建器
      final warningWidget = warningBuilder!(message);
      return WToast.showCustomDialog(
        toastBuilder: (cancelFunc) => warningWidget,
        align: align,
        duration: duration,
        animationDuration: animationDuration,
      );
    } else {
      // 使用 WToast 的默认实现
      return WToast.showWarning(
        message,
        duration: duration,
        align: align,
        theme: theme,
      );
    }
  }

  /// 显示加载提示
  ///
  /// @param message 加载提示文本，默认 "加载中..."
  /// @param dismissible 是否可点击关闭，默认 false
  /// @return CancelFunc 用于取消对话框的函数
  CancelFunc showLoading({
    String message = '加载中...',
    bool dismissible = false,
  }) {
    return WToast.showLoading(
      message: message,
      dismissible: dismissible,
      theme: theme,
    );
  }

  /// 关闭加载提示
  void hideLoading() {
    WToast.hideLoading();
  }
}

