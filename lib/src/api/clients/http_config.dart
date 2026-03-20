/// HTTP 配置类，用于存储 HTTP 请求的配置信息
class HttpConfig {
  /// 连接超时时间
  final Duration _connectTimeout;

  /// 接收超时时间
  final Duration _receiveTimeOut;

  /// 是否重试
  final bool _retry;

  /// 重试次数
  final int _retryCount;

  /// 是否启用 HTTPS 证书验证
  final bool _enableCertificateValidation;

  /// 安全头部配置
  final Map<String, String> _securityHeaders;

  /// 获取连接超时时间
  get connectTimeout {
    return _connectTimeout;
  }

  /// 获取接收超时时间
  get receiveTimeOut {
    return _receiveTimeOut;
  }

  /// 获取是否重试
  get retry {
    return _retry;
  }

  /// 获取重试次数
  get retryCount {
    return _retryCount;
  }

  /// 获取是否启用 HTTPS 证书验证
  get enableCertificateValidation {
    return _enableCertificateValidation;
  }

  /// 获取安全头部配置
  get securityHeaders {
    return _securityHeaders;
  }

  /// 构造函数
  ///
  /// @param builder HttpConfigBuilder 实例
  HttpConfig(HttpConfigBuilder builder)
    : _connectTimeout = builder._connectTimeout,
      _receiveTimeOut = builder._receiveTimeOut,
      _retry = builder._retry,
      _retryCount = builder._retryCount,
      _enableCertificateValidation = builder._enableCertificateValidation,
      _securityHeaders = builder._securityHeaders;
}

/// HTTP 配置构建器，用于构建 HttpConfig 实例
class HttpConfigBuilder {
  /// 连接超时时间，默认 10 秒
  Duration _connectTimeout = const Duration(milliseconds: 10000); //连接超时时间
  /// 接收超时时间，默认 50 秒
  Duration _receiveTimeOut = const Duration(milliseconds: 50000); //接收超时时间
  /// 是否重试，默认 false
  bool _retry = false;

  /// 重试次数，默认 3 次
  int _retryCount = 3;

  /// 是否启用 HTTPS 证书验证，默认 true
  bool _enableCertificateValidation = true;

  /// 安全头部配置
  Map<String, String> _securityHeaders = {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Content-Security-Policy': "default-src 'self'",
  };

  /// 设置连接超时时间
  ///
  /// @param connectTimeout 连接超时时间
  /// @return HttpConfigBuilder 实例，用于链式调用
  HttpConfigBuilder setConnectTimeout(Duration connectTimeout) {
    _connectTimeout = connectTimeout;
    return this;
  }

  /// 设置接收超时时间
  ///
  /// @param receiveTimeOut 接收超时时间
  /// @return HttpConfigBuilder 实例，用于链式调用
  HttpConfigBuilder setReceiveTimeOut(Duration receiveTimeOut) {
    _receiveTimeOut = receiveTimeOut;
    return this;
  }

  /// 设置是否重试
  ///
  /// @param retry 是否重试
  /// @return HttpConfigBuilder 实例，用于链式调用
  HttpConfigBuilder setRetry(bool retry) {
    _retry = retry;
    return this;
  }

  /// 设置重试次数
  ///
  /// @param retryCount 重试次数
  /// @return HttpConfigBuilder 实例，用于链式调用
  HttpConfigBuilder setRetryCount(int retryCount) {
    _retryCount = retryCount;
    return this;
  }

  /// 设置是否启用 HTTPS 证书验证
  ///
  /// @param enable 是否启用
  /// @return HttpConfigBuilder 实例，用于链式调用
  HttpConfigBuilder setEnableCertificateValidation(bool enable) {
    _enableCertificateValidation = enable;
    return this;
  }

  /// 添加安全头部
  ///
  /// @param key 头部键
  /// @param value 头部值
  /// @return HttpConfigBuilder 实例，用于链式调用
  HttpConfigBuilder addSecurityHeader(String key, String value) {
    _securityHeaders[key] = value;
    return this;
  }

  /// 设置安全头部
  ///
  /// @param headers 安全头部映射
  /// @return HttpConfigBuilder 实例，用于链式调用
  HttpConfigBuilder setSecurityHeaders(Map<String, String> headers) {
    _securityHeaders = headers;
    return this;
  }

  /// 构建 HttpConfig 实例
  ///
  /// @return HttpConfig 实例
  HttpConfig build() => HttpConfig(this);
}
