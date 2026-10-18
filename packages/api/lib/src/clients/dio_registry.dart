import 'package:dio/dio.dart';

import '../api_config.dart';

/// Dio 实例注册表：按 `baseUrl` 缓存并复用 [Dio] 实例
///
/// 跨平台兼容：Web 使用 BrowserHttpClientAdapter，Android/iOS/Desktop 使用 IOHttpClientAdapter。
/// 如需在原生平台自定义 HTTPS 证书验证，使用条件导入：
/// ```dart
/// import 'package:dio/io.dart' if (dart.library.html) '';
/// ```
/// 然后在 `!kIsWeb` 分支里 cast `dio.httpClientAdapter as IOHttpClientAdapter`。
class DioRegistry {
  /// Dio 实例
  late Dio _dio;

  /// 获取 Dio 实例
  Dio get dio {
    return _dio;
  }

  /// 私有构造函数
  ///
  /// 传入的 [options] 会被复制并注入 [baseUrl]，因此：
  /// - 传入的 BaseOptions 实例不会被本类修改；
  /// - 多个 Dio 实例之间不会共享同一份可变配置。
  DioRegistry._internal(
    String baseUrl,
    BaseOptions options,
    List<Interceptor> interceptors,
  ) {
    _dio = Dio(options.copyWith(baseUrl: baseUrl));

    for (final element in interceptors) {
      _dio.interceptors.add(element);
    }
  }

  /// 已创建的实例映射（key 为 baseUrl）
  static final Map<String, DioRegistry> _instances = {};

  /// 获取或创建指定 baseUrl 的实例（按 baseUrl 缓存）
  ///
  /// 注意：同一 [baseUrl] 命中缓存后会**直接返回已有实例**，此时传入的
  /// [options] / [interceptors] 会被忽略；如需更换配置请先 [dispose]。
  ///
  /// @param baseUrl 基础 URL
  /// @param options Dio 基础配置，缺省使用 [WApiConfig.baseOptions]
  /// @param interceptors 拦截器列表，按传入顺序挂载
  /// @return DioRegistry 实例
  static DioRegistry forBaseUrl(
    String baseUrl, {
    BaseOptions? options,
    List<Interceptor>? interceptors,
  }) {
    return _instances.putIfAbsent(baseUrl, () {
      return DioRegistry._internal(
        baseUrl,
        options ?? WApiConfig.baseOptions,
        List.unmodifiable(interceptors ?? const []),
      );
    });
  }

  /// 释放指定 baseUrl 的实例及其 Dio 资源
  static void dispose(String baseUrl) {
    final registry = _instances.remove(baseUrl);
    registry?._dio.close(force: true);
  }

  /// 清空所有缓存的实例
  static void clearCache() {
    for (final registry in _instances.values) {
      registry._dio.close(force: true);
    }
    _instances.clear();
  }
}
