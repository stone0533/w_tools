import 'package:logger/logger.dart';
import 'dart:core';

// 重新导出日志级别，调用方无需为 WLogger.setLevel 额外引入 logger 包
export 'package:logger/logger.dart' show Level;

// 日志级别（由低到高）：trace → debug → info → warning → error → fatal；
// Level.off 关闭全部输出。

/// 在消息前拼接 `[tag] `；[tag] 为 null 时原样返回消息
String _formatMessage(dynamic message, String? tag) {
  if (tag == null) {
    return message.toString();
  }
  return "[$tag] $message";
}

/// 日志单例配置：持有 Logger、PrettyPrinter 与性能计时器
class _WLoggerConfig {
  // 日志实例，切换级别时重建
  late Logger logger;

  // 日志打印器：切换级别时复用，避免丢失格式配置
  final LogPrinter printer;

  // 性能计时器映射
  final Map<String, Stopwatch> _performanceTimers = {};

  // 单例实例
  static final _WLoggerConfig _instance = _WLoggerConfig._internal();

  // 私有构造函数，初始化日志格式
  _WLoggerConfig._internal()
      : printer = PrettyPrinter(
          methodCount: 0, // 不显示方法调用栈
          errorMethodCount: 5, // 错误时显示 5 行方法调用栈
          lineLength: 50, // 日志行长度
          colors: true, // 启用彩色输出
          printEmojis: false, // 不显示表情符号
          dateTimeFormat: DateTimeFormat.dateAndTime, // 日期时间格式
        ) {
    logger = Logger(printer: printer);
  }

  /// 获取单例实例
  static _WLoggerConfig get instance => _instance;

  /// 开始性能计时
  void startPerformanceTimer(String key) {
    _performanceTimers[key] = Stopwatch()..start();
  }

  /// 结束性能计时并返回耗时（毫秒）
  ///
  /// 计时器不存在时记录警告并返回 0。
  int stopPerformanceTimer(String key, {String? message}) {
    final timer = _performanceTimers[key];
    if (timer == null) {
      WLogger.w("Performance timer not found: $key");
      return 0;
    }

    timer.stop();
    final elapsed = timer.elapsedMilliseconds;
    _performanceTimers.remove(key);

    if (message != null) {
      WLogger.i("$message: $elapsed ms");
    }

    return elapsed;
  }

  /// 取消性能计时
  void cancelPerformanceTimer(String key) {
    _performanceTimers.remove(key);
  }

  /// 获取所有正在进行的性能计时键名
  List<String> getActivePerformanceTimers() {
    return _performanceTimers.keys.toList();
  }
}

/// 日志工具类（静态入口）
class WLogger {
  // 纯静态工具类，禁止实例化
  WLogger._();

  /// 关闭所有日志输出
  static void turnOff() {
    setLevel(Level.off);
  }

  /// 设置日志级别
  ///
  /// 复用既有 [LogPrinter]，保留输出格式配置。
  static void setLevel(Level level) {
    final config = _WLoggerConfig.instance;
    config.logger = Logger(printer: config.printer, level: level);
  }

  /// 输出 Trace 级别日志
  ///
  /// - [message]：日志内容（任意对象，内部转为字符串）
  /// - [time]：日志时间，默认当前时间
  /// - [error]：附带错误对象
  /// - [stackTrace]：附带堆栈
  /// - [tag]：非空时以 `[tag] ` 前缀拼接到消息前
  static void t(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) =>
      _WLoggerConfig.instance.logger.t(
        _formatMessage(message, tag),
        time: time,
        error: error,
        stackTrace: stackTrace,
      );

  /// 输出 Debug 级别日志，参数说明见 [t]
  static void d(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) =>
      _WLoggerConfig.instance.logger.d(
        _formatMessage(message, tag),
        time: time,
        error: error,
        stackTrace: stackTrace,
      );

  /// 输出 Info 级别日志，参数说明见 [t]
  static void i(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) =>
      _WLoggerConfig.instance.logger.i(
        _formatMessage(message, tag),
        time: time,
        error: error,
        stackTrace: stackTrace,
      );

  /// 输出 Warning 级别日志，参数说明见 [t]
  static void w(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) =>
      _WLoggerConfig.instance.logger.w(
        _formatMessage(message, tag),
        time: time,
        error: error,
        stackTrace: stackTrace,
      );

  /// 输出 Error 级别日志，参数说明见 [t]
  static void e(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) =>
      _WLoggerConfig.instance.logger.e(
        _formatMessage(message, tag),
        time: time,
        error: error,
        stackTrace: stackTrace,
      );

  /// 输出 Fatal 级别日志，参数说明见 [t]
  static void f(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) =>
      _WLoggerConfig.instance.logger.f(
        _formatMessage(message, tag),
        time: time,
        error: error,
        stackTrace: stackTrace,
      );

  /// 开始性能计时
  static void startPerformanceTimer(String key) {
    _WLoggerConfig.instance.startPerformanceTimer(key);
  }

  /// 结束性能计时并返回耗时（毫秒）
  ///
  /// 计时器不存在时记录警告并返回 0。
  static int stopPerformanceTimer(String key, {String? message}) {
    return _WLoggerConfig.instance.stopPerformanceTimer(key, message: message);
  }

  /// 取消性能计时
  static void cancelPerformanceTimer(String key) {
    _WLoggerConfig.instance.cancelPerformanceTimer(key);
  }

  /// 获取所有正在进行的性能计时键名
  static List<String> getActivePerformanceTimers() {
    return _WLoggerConfig.instance.getActivePerformanceTimers();
  }

  /// 执行同步函数并记录耗时
  ///
  /// 函数抛出异常时仍会结束计时，并把异常继续抛出。
  static T measureSync<T>(String key, T Function() function, {String? message}) {
    startPerformanceTimer(key);
    try {
      return function();
    } finally {
      stopPerformanceTimer(key, message: message);
    }
  }
}
