import 'package:logger/logger.dart';
import 'dart:core';

// 日志级别说明：
// verbose（最详细）-->trace
// debug
// info
// warning
// error
// wtf（最严重）-->fatal
// nothing（关闭日志）-->off

/// 输出 Trace 级别的日志
///
/// @param message 日志消息
/// @param time 日志时间
/// @param error 错误信息
/// @param stackTrace 堆栈跟踪
/// @param tag 日志标签
logT(
  dynamic message, {
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
  String? tag,
}) => _WLoggerConfig.instance.logger.t(
  _formatMessage(message, tag),
  time: time,
  error: error,
  stackTrace: stackTrace,
);

/// 输出 Debug 级别的日志
///
/// @param message 日志消息
/// @param time 日志时间
/// @param error 错误信息
/// @param stackTrace 堆栈跟踪
/// @param tag 日志标签
logD(
  dynamic message, {
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
  String? tag,
}) => _WLoggerConfig.instance.logger.d(
  _formatMessage(message, tag),
  time: time,
  error: error,
  stackTrace: stackTrace,
);

/// 输出 Info 级别的日志
///
/// @param message 日志消息
/// @param time 日志时间
/// @param error 错误信息
/// @param stackTrace 堆栈跟踪
/// @param tag 日志标签
logI(
  dynamic message, {
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
  String? tag,
}) => _WLoggerConfig.instance.logger.i(
  _formatMessage(message, tag),
  time: time,
  error: error,
  stackTrace: stackTrace,
);

/// 输出 Warning 级别的日志
///
/// @param message 日志消息
/// @param time 日志时间
/// @param error 错误信息
/// @param stackTrace 堆栈跟踪
/// @param tag 日志标签
logW(
  dynamic message, {
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
  String? tag,
}) => _WLoggerConfig.instance.logger.w(
  _formatMessage(message, tag),
  time: time,
  error: error,
  stackTrace: stackTrace,
);

/// 输出 Error 级别的日志
///
/// @param message 日志消息
/// @param time 日志时间
/// @param error 错误信息
/// @param stackTrace 堆栈跟踪
/// @param tag 日志标签
logE(
  dynamic message, {
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
  String? tag,
}) => _WLoggerConfig.instance.logger.e(
  _formatMessage(message, tag),
  time: time,
  error: error,
  stackTrace: stackTrace,
);

/// 输出 Fatal 级别的日志
///
/// @param message 日志消息
/// @param time 日志时间
/// @param error 错误信息
/// @param stackTrace 堆栈跟踪
/// @param tag 日志标签
logF(
  dynamic message, {
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
  String? tag,
}) => _WLoggerConfig.instance.logger.f(
  _formatMessage(message, tag),
  time: time,
  error: error,
  stackTrace: stackTrace,
);

/// 格式化日志消息，添加标签
///
/// @param message 原始消息
/// @param tag 标签
/// @return 格式化后的消息
String _formatMessage(dynamic message, String? tag) {
  if (tag == null) {
    return message.toString();
  }
  return "[$tag] $message";
}

/// 日志配置类，单例模式
///
/// 管理日志实例和性能计时器
class _WLoggerConfig {
  // 日志实例
  late Logger logger;

  // 性能计时器映射，用于存储不同键对应的计时器
  final Map<String, Stopwatch> _performanceTimers = {};

  // 单例实例
  static final _WLoggerConfig _instance = _WLoggerConfig._internal();

  // 私有构造函数，初始化日志配置
  _WLoggerConfig._internal() {
    logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0, // 不显示方法调用栈
        errorMethodCount: 5, // 错误时显示5行方法调用栈
        lineLength: 50, // 日志行长度
        colors: true, // 启用彩色输出
        printEmojis: false, // 不显示表情符号
        dateTimeFormat: DateTimeFormat.dateAndTime, // 日期时间格式
      ),
    );
  }

  // 获取单例实例
  static _WLoggerConfig get instance => _instance;

  /// 开始性能计时
  ///
  /// @param key 计时器键名
  void startPerformanceTimer(String key) {
    _performanceTimers[key] = Stopwatch()..start();
  }

  /// 结束性能计时并返回耗时（毫秒）
  ///
  /// @param key 计时器键名
  /// @param message 可选的消息，用于输出日志
  /// @return 耗时（毫秒）
  int stopPerformanceTimer(String key, {String? message}) {
    final timer = _performanceTimers[key];
    if (timer == null) {
      logW("Performance timer not found: $key");
      return 0;
    }

    timer.stop();
    final elapsed = timer.elapsedMilliseconds;
    _performanceTimers.remove(key);

    if (message != null) {
      logI("$message: $elapsed ms");
    }

    return elapsed;
  }

  /// 取消性能计时
  ///
  /// @param key 计时器键名
  void cancelPerformanceTimer(String key) {
    _performanceTimers.remove(key);
  }

  /// 获取所有正在进行的性能计时
  ///
  /// @return 正在进行的计时器键名列表
  List<String> getActivePerformanceTimers() {
    return _performanceTimers.keys.toList();
  }
}

/// 日志工具类，提供静态方法访问日志功能
class WLogger {
  /// 关闭所有日志输出
  static void turnOff() {
    _WLoggerConfig.instance.logger = Logger(level: Level.off);
  }

  /// 设置日志级别
  ///
  /// @param level 日志级别
  static void setLevel(Level level) {
    _WLoggerConfig.instance.logger = Logger(level: level);
  }

  /// 输出 Trace 级别的日志
  ///
  /// @param message 日志消息
  /// @param time 日志时间
  /// @param error 错误信息
  /// @param stackTrace 堆栈跟踪
  /// @param tag 日志标签
  static void t(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) => _WLoggerConfig.instance.logger.t(
    _formatMessage(message, tag),
    time: time,
    error: error,
    stackTrace: stackTrace,
  );

  /// 输出 Debug 级别的日志
  ///
  /// @param message 日志消息
  /// @param time 日志时间
  /// @param error 错误信息
  /// @param stackTrace 堆栈跟踪
  /// @param tag 日志标签
  static void d(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) => _WLoggerConfig.instance.logger.d(
    _formatMessage(message, tag),
    time: time,
    error: error,
    stackTrace: stackTrace,
  );

  /// 输出 Info 级别的日志
  ///
  /// @param message 日志消息
  /// @param time 日志时间
  /// @param error 错误信息
  /// @param stackTrace 堆栈跟踪
  /// @param tag 日志标签
  static void i(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) => _WLoggerConfig.instance.logger.i(
    _formatMessage(message, tag),
    time: time,
    error: error,
    stackTrace: stackTrace,
  );

  /// 输出 Warning 级别的日志
  ///
  /// @param message 日志消息
  /// @param time 日志时间
  /// @param error 错误信息
  /// @param stackTrace 堆栈跟踪
  /// @param tag 日志标签
  static void w(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) => _WLoggerConfig.instance.logger.w(
    _formatMessage(message, tag),
    time: time,
    error: error,
    stackTrace: stackTrace,
  );

  /// 输出 Error 级别的日志
  ///
  /// @param message 日志消息
  /// @param time 日志时间
  /// @param error 错误信息
  /// @param stackTrace 堆栈跟踪
  /// @param tag 日志标签
  static void e(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) => _WLoggerConfig.instance.logger.e(
    _formatMessage(message, tag),
    time: time,
    error: error,
    stackTrace: stackTrace,
  );

  /// 输出 Fatal 级别的日志
  ///
  /// @param message 日志消息
  /// @param time 日志时间
  /// @param error 错误信息
  /// @param stackTrace 堆栈跟踪
  /// @param tag 日志标签
  static void f(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) => _WLoggerConfig.instance.logger.f(
    _formatMessage(message, tag),
    time: time,
    error: error,
    stackTrace: stackTrace,
  );

  // 性能统计相关方法

  /// 开始性能计时
  ///
  /// @param key 计时器键名
  static void startPerformance(String key) {
    _WLoggerConfig.instance.startPerformanceTimer(key);
  }

  /// 结束性能计时并返回耗时（毫秒）
  ///
  /// @param key 计时器键名
  /// @param message 可选的消息，用于输出日志
  /// @return 耗时（毫秒）
  static int stopPerformance(String key, {String? message}) {
    return _WLoggerConfig.instance.stopPerformanceTimer(key, message: message);
  }

  /// 取消性能计时
  ///
  /// @param key 计时器键名
  static void cancelPerformance(String key) {
    _WLoggerConfig.instance.cancelPerformanceTimer(key);
  }

  /// 获取所有正在进行的性能计时
  ///
  /// @return 正在进行的计时器键名列表
  static List<String> getActivePerformanceTimers() {
    return _WLoggerConfig.instance.getActivePerformanceTimers();
  }

  /// 执行并计时一个函数
  ///
  /// @param key 计时器键名
  /// @param function 要执行的函数
  /// @param message 可选的消息，用于输出日志
  /// @return 函数的返回值
  static T measurePerformance<T>(String key, T Function() function, {String? message}) {
    startPerformance(key);
    try {
      return function();
    } finally {
      stopPerformance(key, message: message);
    }
  }
}
