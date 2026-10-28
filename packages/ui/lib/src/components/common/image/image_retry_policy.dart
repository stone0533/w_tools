import 'dart:math';

import 'package:flutter/painting.dart';

/// 网络错误是否值得自动重试（内部策略，不对外导出）
///
/// - `4xx`（除 `408` / `429`）：请求本身有问题，重试没有意义
/// - `5xx` / `408` / `429`：典型瞬态错误，可重试
/// - 拿不到状态码（连接被重置、DNS 失败等）：可重试
bool isRetryableNetworkError(Object error) {
  final statusCode = _statusCodeOf(error);
  if (statusCode == null) return true;
  return statusCode >= 500 || statusCode == 408 || statusCode == 429;
}

/// 读取错误里的 HTTP 状态码
///
/// [NetworkImageLoadException] 是 Flutter 自己的类型；
/// `cached_network_image` 经 `flutter_cache_manager` 抛出的
/// `HttpExceptionWithStatus` 不在本包的依赖里，用字段读取兼容两者。
int? _statusCodeOf(Object error) {
  if (error is NetworkImageLoadException) return error.statusCode;
  try {
    final dynamic candidate = error;
    final code = candidate.statusCode;
    return code is int ? code : null;
  } catch (_) {
    return null;
  }
}

/// 第 [attempt] 次重试前的等待时间（指数退避 + 抖动）
///
/// [attempt] 从 0 开始：0 → base，1 → 2×base，2 → 4×base……
/// 抖动在 80%–100% 之间，避免同屏多张图在同一时刻齐刷刷重试。
Duration retryDelayFor(
  int attempt, {
  Duration base = const Duration(milliseconds: 1000),
  Duration maxDelay = const Duration(seconds: 30),
  Random? random,
}) {
  final exponent = attempt < 0 ? 0 : (attempt > 8 ? 8 : attempt);
  final raw = base.inMilliseconds * (1 << exponent);
  final capped = raw > maxDelay.inMilliseconds ? maxDelay.inMilliseconds : raw;
  final jitterFactor = 0.8 + 0.2 * (random?.nextDouble() ?? 0.5);
  final delay = (capped * jitterFactor).round();
  return Duration(milliseconds: delay < 1 ? 1 : delay);
}
