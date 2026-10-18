import 'package:dio/dio.dart';

/// API / 网络层配置
class WApiConfig {
  /// 默认 Dio 基础配置（可全局覆盖）
  ///
  /// [DioRegistry.forBaseUrl] 在使用时会**复制**它（`copyWith`），不会修改该实例，
  /// 因此可安全地作为全局默认；也可在调用处显式传 `options` 覆盖。
  static BaseOptions baseOptions = BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 50),
  );

  /// Debug 日志回调，需显式注入
  ///
  /// 示例: `WApiConfig.logDebugHandler = (m) => WLogger.d(m);`
  static void Function(dynamic message)? logDebugHandler;

  /// Error 日志回调，需显式注入
  ///
  /// 示例: `WApiConfig.logErrorHandler = (m) => WLogger.e(m);`
  static void Function(dynamic message)? logErrorHandler;

  WApiConfig._();
}
