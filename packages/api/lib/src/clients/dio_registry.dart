import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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

  /// 创建时的配置（用于命中缓存时检测冲突）
  late final BaseOptions _options;

  /// 创建时的拦截器（用于命中缓存时检测冲突）
  late final List<Interceptor> _interceptors;

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
    _options = options.copyWith(baseUrl: baseUrl);
    _interceptors = List.unmodifiable(interceptors);
    _dio = Dio(_options);

    for (final element in _interceptors) {
      _dio.interceptors.add(element);
    }
  }

  /// 已创建的实例映射（key 为 baseUrl）
  static final Map<String, DioRegistry> _instances = {};

  /// 获取或创建指定 baseUrl 的实例（按 baseUrl 缓存）
  ///
  /// 同一 [baseUrl] 命中缓存时返回已有实例；如果这次显式传入了**不同**的
  /// [options] / [interceptors]，会抛 [ArgumentError]，不再静默忽略。
  /// 需要换配置请先 [dispose]。
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
    final existing = _instances[baseUrl];
    if (existing != null) {
      if (options != null && !_sameOptions(existing._options, options)) {
        throw ArgumentError.value(
          baseUrl,
          'baseUrl',
          'DioRegistry 已存在同一 baseUrl 的不同 BaseOptions；'
              '如需更换配置请先 DioRegistry.dispose(baseUrl)',
        );
      }
      if (interceptors != null && !listEquals(existing._interceptors, interceptors)) {
        throw ArgumentError.value(
          baseUrl,
          'baseUrl',
          'DioRegistry 已存在同一 baseUrl 的不同 interceptors；'
              '如需更换配置请先 DioRegistry.dispose(baseUrl)',
        );
      }
      return existing;
    }

    return _instances[baseUrl] = DioRegistry._internal(
      baseUrl,
      options ?? WApiConfig.baseOptions,
      List.unmodifiable(interceptors ?? const []),
    );
  }

  /// 比较两个 BaseOptions 的关键网络配置。
  ///
  /// `validateStatus` 按引用比较（默认实现是同一个顶层函数；自定义闭包即使语义
  /// 相同也会被视为不同配置）。
  static bool _sameOptions(BaseOptions a, BaseOptions b) {
    return a.connectTimeout == b.connectTimeout &&
        a.receiveTimeout == b.receiveTimeout &&
        a.sendTimeout == b.sendTimeout &&
        a.responseType == b.responseType &&
        a.contentType == b.contentType &&
        a.followRedirects == b.followRedirects &&
        a.receiveDataWhenStatusError == b.receiveDataWhenStatusError &&
        a.persistentConnection == b.persistentConnection &&
        a.listFormat == b.listFormat &&
        identical(a.validateStatus, b.validateStatus) &&
        mapEquals(a.headers, b.headers) &&
        mapEquals(a.extra, b.extra);
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
