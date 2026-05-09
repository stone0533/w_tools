/// HTTP 配置类，用于存储 HTTP 请求的配置信息
///
/// @example
/// ```dart
/// // 创建默认配置
/// final config = HttpConfig();
///
/// // 创建自定义配置
/// final custom = HttpConfig(
///   connectTimeout: const Duration(seconds: 5),
///   retry: true,
///   retryCount: 3,
/// );
///
/// // 基于现有配置创建
/// final modified = custom.copyWith(retryCount: 5);
/// ```
class HttpConfig {
  // === 默认值常量 ===
  static const Duration _defaultConnectTimeout = Duration(milliseconds: 10000);
  static const Duration _defaultReceiveTimeout = Duration(milliseconds: 50000);
  static const int _defaultRetryCount = 3;
  static const Map<String, String> _defaultSecurityHeaders = {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Content-Security-Policy': "default-src 'self'",
  };

  // === 配置字段 ===
  /// 连接超时时间，默认 10 秒
  final Duration connectTimeout;

  /// 接收超时时间，默认 50 秒
  final Duration receiveTimeout;

  /// 是否启用重试，默认 false
  final bool retry;

  /// 重试次数，默认 3 次
  final int retryCount;

  /// 是否启用 HTTPS 证书验证，默认 true
  final bool enableCertificateValidation;

  /// 安全响应头部配置（不可变）
  final Map<String, String> securityHeaders;

  // === 构造函数 ===
  /// 创建 HTTP 配置
  ///
  /// @param connectTimeout 连接超时时间，默认 10 秒
  /// @param receiveTimeout 接收超时时间，默认 50 秒
  /// @param retry 是否启用重试，默认 false
  /// @param retryCount 重试次数，默认 3 次
  /// @param enableCertificateValidation 是否启用证书验证，默认 true
  /// @param securityHeaders 安全响应头部配置
  HttpConfig({
    Duration? connectTimeout,
    Duration? receiveTimeout,
    bool? retry,
    int? retryCount,
    bool? enableCertificateValidation,
    Map<String, String>? securityHeaders,
  })  : assert(connectTimeout == null || connectTimeout >= Duration.zero,
            'connectTimeout must be non-negative'),
        assert(receiveTimeout == null || receiveTimeout >= Duration.zero,
            'receiveTimeout must be non-negative'),
        assert(retryCount == null || retryCount > 0,
            'retryCount must be greater than 0'),
        connectTimeout = connectTimeout ?? _defaultConnectTimeout,
        receiveTimeout = receiveTimeout ?? _defaultReceiveTimeout,
        retry = retry ?? false,
        retryCount = retryCount ?? _defaultRetryCount,
        enableCertificateValidation = enableCertificateValidation ?? true,
        securityHeaders = Map.unmodifiable(securityHeaders ?? _defaultSecurityHeaders);

  // === 便捷方法 ===
  /// 添加安全响应头部并返回新配置
  ///
  /// @param key 头部键名
  /// @param value 头部值
  /// @return 新的 HttpConfig 实例
  HttpConfig addSecurityHeader(String key, String value) {
    final newHeaders = Map<String, String>.from(securityHeaders)..[key] = value;
    return copyWith(securityHeaders: newHeaders);
  }

  /// 复制配置并返回新实例
  HttpConfig copyWith({
    Duration? connectTimeout,
    Duration? receiveTimeout,
    bool? retry,
    int? retryCount,
    bool? enableCertificateValidation,
    Map<String, String>? securityHeaders,
  }) {
    return HttpConfig(
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      retry: retry ?? this.retry,
      retryCount: retryCount ?? this.retryCount,
      enableCertificateValidation: enableCertificateValidation ?? this.enableCertificateValidation,
      securityHeaders: securityHeaders,
    );
  }

  // === 便捷工厂方法 ===
  /// 创建快速超时配置（适合局域网或内部服务）
  ///
  /// 连接超时：3秒，接收超时：10秒
  factory HttpConfig.fastTimeout() {
    return HttpConfig(
      connectTimeout: const Duration(milliseconds: 3000),
      receiveTimeout: const Duration(milliseconds: 10000),
    );
  }

  /// 创建带重试机制的配置
  ///
  /// @param count 重试次数，默认 3 次
  factory HttpConfig.withRetry({int count = 3}) {
    return HttpConfig(
      retry: true,
      retryCount: count,
    );
  }

  /// 创建不安全配置（仅用于测试环境）
  ///
  /// 禁用 HTTPS 证书验证，**请勿在生产环境使用**
  factory HttpConfig.unsafe() {
    return HttpConfig(
      enableCertificateValidation: false,
    );
  }
}
