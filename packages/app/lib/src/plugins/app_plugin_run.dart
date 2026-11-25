import 'package:flutter/foundation.dart';

/// 一次插件 [WAppPlugin.init] / [WAppPlugin.onFirstFrame] 的执行记录。
@immutable
class WAppPluginRun {
  const WAppPluginRun({
    required this.name,
    required this.duration,
    this.error,
    this.stackTrace,
    this.timedOut = false,
  });

  /// 插件名。
  final String name;

  /// 本次执行耗时（单调时钟）。
  final Duration duration;

  /// 失败原因；成功时为 null。
  final Object? error;

  /// 失败堆栈。
  final StackTrace? stackTrace;

  /// 是否因为超时失败。
  final bool timedOut;

  /// 是否成功。
  bool get ok => error == null;

  @override
  String toString() =>
      'WAppPluginRun($name, ${duration.inMilliseconds}ms, '
      '${ok ? 'ok' : 'failed${timedOut ? ' (timeout)' : ''}'})';
}

/// 插件初始化失败（含超时）。
///
/// [cause] 保留插件自己抛出的原始异常；[stackTrace] 是原始堆栈
/// （超时时为超时发生处的堆栈）。[pluginName] 让启动兜底页 /
/// 日志能直接指出是哪个插件失败。
class WAppPluginInitException implements Exception {
  const WAppPluginInitException({
    required this.pluginName,
    required this.cause,
    required this.stackTrace,
    this.timedOut = false,
  });

  final String pluginName;
  final Object cause;
  final StackTrace stackTrace;
  final bool timedOut;

  @override
  String toString() => timedOut
      ? 'WAppPluginInitException(插件 "$pluginName" 初始化超时)'
      : 'WAppPluginInitException(插件 "$pluginName" 初始化失败): $cause';
}
