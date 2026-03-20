import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';

import 'http_config.dart';
import '../interceptors/cache.dart';

/// Dio 工具类，用于创建和管理 Dio 实例
class DioUtil {
  /// 基础 URL
  final String _baseUrl;

  /// HTTP 配置
  final HttpConfig _config;

  /// 拦截器列表
  final List<Interceptor> _interceptors;

  /// Dio 实例
  late Dio _dio;

  /// 获取 Dio 实例
  Dio get dio {
    return _dio;
  }

  /// 私有构造函数
  ///
  /// @param baseUrl 基础 URL
  /// @param config HTTP 配置
  /// @param interceptors 拦截器列表
  DioUtil._internal(this._baseUrl, this._config, this._interceptors) {
    BaseOptions options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: _config.connectTimeout,
      receiveTimeout: _config.receiveTimeOut,
      headers: _config.securityHeaders,
    );
    _dio = Dio(options);

    // 配置 HTTPS 证书验证
    if (_config.enableCertificateValidation) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          // 这里可以添加自定义的证书验证逻辑
          // 默认返回 false，拒绝无效证书
          return false;
        };
        return client;
      };
    }

    for (var element in _interceptors) {
      _dio.interceptors.add(element);
    }
  }

  /// 存储 DioUtil 实例的映射
  static final Map<String, DioUtil> _dioUtils = {};

  /// 获取 DioUtil 实例
  ///
  /// @param baseUrl 基础 URL
  /// @param config HTTP 配置
  /// @param interceptors 拦截器列表
  /// @param applyInterceptors 额外的拦截器列表
  /// @param enableCache 是否启用缓存
  /// @param maxCacheSize 最大缓存大小，默认 10MB
  /// @param maxCacheAge 最大缓存时间，默认 24 小时
  /// @return DioUtil 实例
  static DioUtil instance(
    String baseUrl, {
    HttpConfig? config,
    List<Interceptor>? interceptors,
    List<Interceptor>? applyInterceptors,
    bool enableCache = false,
    int maxCacheSize = 1024 * 1024 * 10, // 默认10MB缓存
    int maxCacheAge = 60 * 60 * 24, // 默认24小时
  }) {
    if (!_dioUtils.containsKey(baseUrl)) {
      var inter = interceptors ?? [];
      if (applyInterceptors != null) {
        inter.addAll(applyInterceptors);
      }

      // 添加缓存拦截器
      if (enableCache) {
        inter.add(
          WCacheInterceptor(
            maxCacheSize: maxCacheSize,
            maxCacheAge: maxCacheAge,
          ),
        );
      }

      _dioUtils[baseUrl] = DioUtil._internal(
        baseUrl,
        config ?? HttpConfigBuilder().build(),
        inter,
      );
    }
    return _dioUtils[baseUrl]!;
  }
}
