import 'dart:convert';

import 'package:dio/dio.dart';

import '../api_config.dart';

/// 日志输出片段。
enum WLogPart {
  request,
  requestHeader,
  requestBody,
  responseHeader,
  responseBody,
  error,
  errorHint,
}

/// 日志拦截器，用于记录 HTTP 请求和响应的详细信息。
///
/// 2.0 起用 [parts] 选择片段；旧 bool 参数保留（5.0 移除）。
class WLogInterceptor extends Interceptor {
  /// 要输出的片段；为 null 时按旧 bool 参数
  final Set<WLogPart>? parts;

  /// 是否打印请求信息
  final bool request;

  /// 是否打印请求头
  final bool requestHeader;

  /// 是否打印请求体
  final bool requestBody;

  /// 是否打印响应体
  final bool responseBody;

  /// 是否打印响应头
  final bool responseHeader;

  /// 是否打印错误信息（详细）
  final bool error;

  /// 是否打印错误友好提示
  final bool errorHint;

  /// 是否启用日志
  final bool enableLog;

  /// 需要脱敏的请求 / 响应头（大小写不敏感）
  final Set<String> redactedHeaders;

  /// 默认脱敏的敏感头
  static const Set<String> defaultRedactedHeaders = {
    'authorization',
    'cookie',
    'set-cookie',
    'proxy-authorization',
    'x-api-key',
  };

  /// 构造函数
  ///
  /// [parts] 非空时，未列出的片段不输出；否则沿用旧 bool 参数。
  WLogInterceptor({
    this.parts,

    /// remove-in: 5.0.0
    @Deprecated('2.0 起用 parts: {WLogPart.request}；5.0 移除') bool? request,

    /// remove-in: 5.0.0
    @Deprecated('2.0 起用 parts: {WLogPart.requestHeader}；5.0 移除') bool? requestHeader,

    /// remove-in: 5.0.0
    @Deprecated('2.0 起用 parts: {WLogPart.requestBody}；5.0 移除') bool? requestBody,

    /// remove-in: 5.0.0
    @Deprecated('2.0 起用 parts: {WLogPart.responseHeader}；5.0 移除') bool? responseHeader,

    /// remove-in: 5.0.0
    @Deprecated('2.0 起用 parts: {WLogPart.responseBody}；5.0 移除') bool? responseBody,

    /// remove-in: 5.0.0
    @Deprecated('2.0 起用 parts: {WLogPart.error}；5.0 移除') bool? error,
    this.enableLog = true,
    this.redactedHeaders = defaultRedactedHeaders,
  }) : request = parts?.contains(WLogPart.request) ?? request ?? true,
       requestHeader = parts?.contains(WLogPart.requestHeader) ?? requestHeader ?? true,
       requestBody = parts?.contains(WLogPart.requestBody) ?? requestBody ?? true,
       responseHeader = parts?.contains(WLogPart.responseHeader) ?? responseHeader ?? false,
       responseBody = parts?.contains(WLogPart.responseBody) ?? responseBody ?? true,
       error = parts?.contains(WLogPart.error) ?? error ?? true,
       errorHint = parts?.contains(WLogPart.errorHint) ?? true;

  /// 请求阶段：打印请求详情
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (!enableLog) {
      handler.next(options);
      return;
    }

    var builder = StringBuffer('*** Request *** \n');
    builder.write(_printKV('uri', options.uri));

    if (request) {
      builder.write(_printKV('method', options.method));
      builder.write(_printKV('responseType', options.responseType.toString()));
      builder.write(_printKV('followRedirects', options.followRedirects));
      builder.write(_printKV('connectTimeout', options.connectTimeout));
      builder.write(_printKV('sendTimeout', options.sendTimeout));
      builder.write(_printKV('receiveTimeout', options.receiveTimeout));
      builder.write(
        _printKV(
          'receiveDataWhenStatusError',
          options.receiveDataWhenStatusError,
        ),
      );
      builder.write(_printKV('extra', options.extra));
    }
    if (requestHeader) {
      builder.write('headers:\n');
      options.headers.forEach(
        (key, v) => builder.write(
          _printKV('  $key', _isRedacted(key) ? '***' : v),
        ),
      );
    }
    if (requestBody) {
      var res = options.data;
      builder.write('data:\n');
      builder.write(_message(res));
    }
    WApiConfig.logDebugHandler?.call(builder.toString());
    handler.next(options);
  }

  /// 处理 JsonEncoder 无法处理的对象
  Object _toEncodableFallback(dynamic object) {
    return object.toString();
  }

  /// 格式化为可读文本：Map/Iterable 走缩进 JSON，其余回退 toString()
  String _message(dynamic res) {
    if (res is Map || res is Iterable) {
      var encoder = JsonEncoder.withIndent('  ', _toEncodableFallback);
      return encoder.convert(res);
    } else {
      return res.toString();
    }
  }

  /// 响应阶段：打印响应详情
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!enableLog) {
      handler.next(response);
      return;
    }

    var builder = StringBuffer('*** Response *** \n');
    _printResponse(response, builder, (message) {
      WApiConfig.logDebugHandler?.call(message);
    });
    handler.next(response);
  }

  /// 错误阶段：打印错误详情与友好提示
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!enableLog) {
      handler.next(err);
      return;
    }

    if (error) {
      var builder = StringBuffer('*** DioError *** \n');
      builder.write('uri: ${err.requestOptions.uri}\n');
      builder.write('$err');
      if (err.response != null) {
        _printResponse(err.response!, builder, (message) {
          WApiConfig.logErrorHandler?.call(message);
        });
      } else {
        WApiConfig.logErrorHandler?.call(builder.toString());
      }
    }

    if (errorHint) _handleError(err);
    handler.next(err);
  }

  /// 按错误类型给出用户友好的提示语
  void _handleError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        WApiConfig.logErrorHandler?.call('网络连接超时，请检查网络设置');
        break;
      case DioExceptionType.connectionError:
        WApiConfig.logErrorHandler?.call('网络连接失败，请检查网络连接');
        break;
      case DioExceptionType.badResponse:
        WApiConfig.logErrorHandler?.call('服务器返回错误: ${err.response?.statusCode}');
        break;
      case DioExceptionType.cancel:
        WApiConfig.logErrorHandler?.call('请求已取消');
        break;
      default:
        WApiConfig.logErrorHandler?.call('网络请求失败: ${err.message}');
        break;
    }
  }

  /// 打印响应信息
  void _printResponse(Response response, StringBuffer builder, void Function(String) pr) {
    builder.write(_printKV('uri', response.requestOptions.uri));
    // statusCode / redirect 属响应元信息，始终打印，不受 responseHeader 开关影响
    builder.write(_printKV('statusCode', response.statusCode));
    if (response.isRedirect == true) {
      builder.write(_printKV('redirect', response.realUri));
    }

    if (responseHeader) {
      builder.write('headers:\n');
      response.headers.forEach(
        (key, v) => builder.write(
          _printKV(
            ' $key',
            _isRedacted(key) ? '***' : v.join('\r\n\t'),
          ),
        ),
      );
    }
    if (responseBody) {
      builder.write('Response Text:\r\n');
      // 直接使用 response.data，交由 _message 安全格式化。
      // 不再用 response.toString() + 手动 jsonDecode：List 的 toString()（如 ["a","b"] → [a, b]）
      // 并非合法 JSON，会导致解析抛异常并让成功的请求失败。
      builder.write(_message(response.data));
    }
    pr(builder.toString());
  }

  bool _isRedacted(String header) => redactedHeaders.contains(header.toLowerCase());

  /// 打印键值对
  String _printKV(String key, Object? v) {
    return '$key: $v \n';
  }
}
