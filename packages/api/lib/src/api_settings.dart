import 'package:dio/dio.dart';

/// API / 网络层全局设置。
///
/// 运行期可改：默认 [baseOptions] 与日志回调。`baseOptions` 在
/// [DioRegistry.forBaseUrl] 创建实例时被复制，之后修改只影响新实例。
///
/// 默认只设置 connect / receive 超时，**不设置 `sendTimeout`**；大文件上传
/// 请显式覆盖 [baseOptions] 的 `sendTimeout`。
class WApiSettings {
  /// 默认 Dio 基础配置（可全局覆盖）
  ///
  /// [DioRegistry.forBaseUrl] 在使用时会**复制**它（`copyWith`），不会修改该实例，
  /// 因此可安全地作为全局默认；也可在调用处显式传 `options` 覆盖。
  static BaseOptions baseOptions = _defaults();

  /// Debug 日志回调，需显式注入
  ///
  /// 示例: `WApiSettings.logDebugHandler = (m) => WLogger.d(m);`
  static void Function(String message)? logDebugHandler;

  /// Error 日志回调，需显式注入
  ///
  /// 示例: `WApiSettings.logErrorHandler = (m) => WLogger.e(m);`
  static void Function(String message)? logErrorHandler;

  /// 恢复默认配置并清空日志回调；主要供测试和示例清理全局状态。
  ///
  /// 只重置本类；`DioRegistry` 的实例缓存由 `DioRegistry.clearCache()` 单独清理。
  static void reset() {
    baseOptions = _defaults();
    logDebugHandler = null;
    logErrorHandler = null;
  }

  static BaseOptions _defaults() => BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 50),
  );

  WApiSettings._();
}
