import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api_settings.dart';
import '../interceptors/retry.dart';
import '../interceptors/token.dart';

/// Dio 实例注册表：按 `baseUrl` 缓存并复用 [Dio] 实例
///
/// 默认复用 dio 的平台 adapter；需要自定义 HTTPS 证书验证时，按 dio 文档
/// 在原生分支里操作 `httpClientAdapter`，不要把平台判断塞进本类。
///
/// ```dart
/// final dio = DioRegistry.forBaseUrl(
///   'https://api.example.com',
///   interceptors: [WLogInterceptor(parts: {WLogPart.request})],
/// ).dio;
/// final response = await dio.get('/gifts');
/// ```
class DioRegistry {
  /// Dio 实例
  late Dio _dio;

  /// 创建时的配置（用于命中缓存时检测冲突）
  late final BaseOptions _options;

  /// 创建时的拦截器（用于命中缓存时检测冲突）
  late final List<Interceptor> _interceptors;

  /// 创建时间（用于 TTL 判断）
  final DateTime _createdAt = DateTime.now();

  /// 获取 Dio 实例
  Dio get dio {
    return _dio;
  }

  /// 私有构造函数
  ///
  /// 传入的 [options] 会被复制并注入 [baseUrl]，因此：
  /// - 传入的 BaseOptions 实例不会被本类修改；
  /// - headers / extra / queryParameters 不与调用方共享同一份可变 Map。
  DioRegistry._internal(
    String baseUrl,
    BaseOptions options,
    List<Interceptor> interceptors,
  ) {
    _options = options.copyWith(
      baseUrl: baseUrl,
      queryParameters: Map<String, dynamic>.from(options.queryParameters),
    );
    _interceptors = List.unmodifiable(interceptors);
    _dio = Dio(_options);

    try {
      for (final element in _interceptors) {
        _dio.interceptors.add(element);
        if (element is WTokenInterceptor) element.bindDio(_dio);
        if (element is WRetryInterceptor) element.bindDio(_dio);
      }
    } catch (_) {
      // 绑定失败时不要留下一个半初始化的 Dio。
      _dio.close(force: true);
      rethrow;
    }
  }

  /// 已创建的实例映射（key 为 baseUrl；按最近使用排序）
  static final Map<String, DioRegistry> _instances = {};

  /// 最大缓存实例数；`null` 表示不限制（默认），`<= 0` 表示不缓存
  ///
  /// 设置后按最近使用淘汰：命中缓存的实例会被移到队尾，新实例入队后若超出上限，
  /// 队首实例会被 `close(force: false)` 关闭并移除（不强制中断在途请求）。
  ///
  /// `<= 0` 时不缓存：每次 [forBaseUrl] 都新建实例，返回的实例仍可用，但不会被
  /// 注册表持有；需要释放时由调用方 `registry.dio.close(force: true)`。
  ///
  /// remove-in: 7.0.0
  @Deprecated('LRU cache will be removed in 7.0.0; use dispose/replace instead')
  static int? maxCachedInstances;

  /// 缓存 TTL；`null` 表示不过期（默认）
  ///
  /// 在 [forBaseUrl] / [maybeForBaseUrl] 访问时惰性判断，过期实例会被
  /// `close(force: false)` 关闭并移除（不强制中断在途请求）。
  ///
  /// remove-in: 7.0.0
  @Deprecated('Cache TTL will be removed in 7.0.0; rebuild the registry instead')
  static Duration? cacheTtl;

  bool get _expired {
    // ignore: deprecated_member_use_from_same_package
    final ttl = cacheTtl;
    return ttl != null && DateTime.now().difference(_createdAt) > ttl;
  }

  /// 获取或创建指定 baseUrl 的实例（按 baseUrl 缓存）
  ///
  /// 同一 [baseUrl] 命中缓存时返回已有实例；如果这次显式传入了**不同**的
  /// [options] / [interceptors]，会抛 [ArgumentError]，不再静默忽略。
  /// 需要换配置时传 [replace] = `true`，或先 [dispose]。
  ///
  /// [replace] 会先关闭并移除同一 [baseUrl] 的旧实例，再按本次配置重建；
  /// 旧实例上的在途请求会随 `close(force: true)` 一起结束。
  ///
  /// @param baseUrl 基础 URL
  /// @param options Dio 基础配置，缺省使用 [WApiSettings.baseOptions]
  /// @param interceptors 拦截器列表，按传入顺序挂载
  /// @param replace 是否替换同 baseUrl 的已有实例
  /// @return DioRegistry 实例
  static DioRegistry forBaseUrl(
    String baseUrl, {
    BaseOptions? options,
    List<Interceptor>? interceptors,
    bool replace = false,
  }) {
    if (replace) {
      dispose(baseUrl);
    }
    final existing = _instances[baseUrl];
    if (existing != null && existing._expired) {
      _instances.remove(baseUrl);
      existing._dio.close(force: false);
    }
    final active = _instances[baseUrl];
    if (active != null) {
      if (options != null && !_sameOptions(active._options, options)) {
        throw ArgumentError.value(
          baseUrl,
          'baseUrl',
          'DioRegistry 已存在同一 baseUrl 的不同 BaseOptions；'
              '如需更换配置请先 DioRegistry.dispose(baseUrl)',
        );
      }
      if (interceptors != null && !listEquals(active._interceptors, interceptors)) {
        throw ArgumentError.value(
          baseUrl,
          'baseUrl',
          'DioRegistry 已存在同一 baseUrl 的不同 interceptors；'
              '如需更换配置请先 DioRegistry.dispose(baseUrl)',
        );
      }
      _instances.remove(baseUrl);
      _instances[baseUrl] = active;
      _evictOverflow();
      return active;
    }

    final registry = DioRegistry._internal(
      baseUrl,
      options ?? WApiSettings.baseOptions,
      List.unmodifiable(interceptors ?? const []),
    );
    // `<= 0` 表示不缓存：实例仍返回给调用方，但不能立刻 close，否则调用方拿到
    // 一个已关闭的 Dio。
    // ignore: deprecated_member_use_from_same_package
    final max = maxCachedInstances;
    if (max != null && max <= 0) {
      return registry;
    }
    _instances[baseUrl] = registry;
    _evictOverflow();
    return registry;
  }

  static void _evictOverflow() {
    // ignore: deprecated_member_use_from_same_package
    final max = maxCachedInstances;
    if (max == null || max <= 0) return;
    // 淘汰不强制中断在途请求（close force:false）；显式 dispose / clearCache 仍
    // 使用 force:true。
    while (_instances.isNotEmpty && _instances.length > max) {
      final oldest = _instances.keys.first;
      final evicted = _instances.remove(oldest);
      evicted?._dio.close(force: false);
    }
  }

  /// 已注册的 Dio（不创建新实例）；未注册返回 null。
  ///
  /// 供 [WTokenInterceptor] 在重试时复用当前实例，避免隐式注册污染缓存。
  static Dio? maybeForBaseUrl(String baseUrl) {
    final registry = _instances[baseUrl];
    if (registry == null) return null;
    if (registry._expired) {
      _instances.remove(baseUrl);
      registry._dio.close(force: false);
      return null;
    }
    return registry.dio;
  }

  /// 比较两个 BaseOptions 的关键网络配置。
  ///
  /// header 名按大小写不敏感比较；query / extra 的值按内容深度比较（含 List / Map / Set）。
  /// `validateStatus` 按引用比较（默认实现是同一个顶层函数；自定义闭包即使语义
  /// 相同也会被视为不同配置）。
  static bool _sameOptions(BaseOptions a, BaseOptions b) {
    return a.connectTimeout == b.connectTimeout &&
        a.receiveTimeout == b.receiveTimeout &&
        a.sendTimeout == b.sendTimeout &&
        a.transformTimeout == b.transformTimeout &&
        a.responseType == b.responseType &&
        a.contentType == b.contentType &&
        a.followRedirects == b.followRedirects &&
        a.receiveDataWhenStatusError == b.receiveDataWhenStatusError &&
        a.persistentConnection == b.persistentConnection &&
        a.listFormat == b.listFormat &&
        a.method == b.method &&
        _sameMap(a.queryParameters, b.queryParameters) &&
        a.maxRedirects == b.maxRedirects &&
        a.preserveHeaderCase == b.preserveHeaderCase &&
        identical(a.requestEncoder, b.requestEncoder) &&
        identical(a.responseDecoder, b.responseDecoder) &&
        identical(a.validateStatus, b.validateStatus) &&
        _sameHeaderMap(a.headers, b.headers) &&
        _sameMap(a.extra, b.extra);
  }

  /// header 名大小写不敏感，值按内容比较。
  static bool _sameHeaderMap(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    if (a.length != b.length) return false;
    final loweredB = <String, dynamic>{
      for (final entry in b.entries) entry.key.toLowerCase(): entry.value,
    };
    for (final entry in a.entries) {
      final key = entry.key.toLowerCase();
      if (!loweredB.containsKey(key)) return false;
      if (!_sameValue(entry.value, loweredB[key])) return false;
    }
    return true;
  }

  /// query / extra 的 key 保留原语义，只做值的内容比较。
  static bool _sameMap(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (!_sameValue(entry.value, b[entry.key])) return false;
    }
    return true;
  }

  static bool _sameValue(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!_sameValue(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_sameValue(a[i], b[i])) return false;
      }
      return true;
    }
    if (a is Set && b is Set) {
      if (a.length != b.length) return false;
      return a.every(b.contains);
    }
    return a == b;
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
