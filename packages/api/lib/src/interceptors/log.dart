import 'dart:convert';
import 'dart:typed_data';

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
/// 用 [parts] 选择片段。
class WLogInterceptor extends Interceptor {
  /// 要输出的片段；为 null 时使用包内默认值；空集表示全部关闭
  final Set<WLogPart>? parts;

  /// 是否打印请求信息
  final bool _request;

  /// 是否打印请求头
  final bool _requestHeader;

  /// 是否打印请求体
  final bool _requestBody;

  /// 是否打印响应体
  final bool _responseBody;

  /// 是否打印响应头
  final bool _responseHeader;

  /// 是否打印错误信息（详细）
  final bool _error;

  /// 是否打印错误友好提示
  final bool _errorHint;

  /// 是否启用日志
  final bool enableLog;

  /// 需要脱敏的请求 / 响应头（大小写不敏感）
  final Set<String> redactedHeaders;

  /// 单条 body 的默认最大输出字符数；`<= 0` 表示不截断
  static const int defaultMaxBodyLength = 2000;

  /// 默认需要脱敏的 query 参数（大小写不敏感）
  static const Set<String> defaultSensitiveQueryKeys = {
    'token',
    'access_token',
    'refresh_token',
    'api_key',
    'apikey',
    'secret',
    'password',
    'auth',
  };

  /// 单条 body 的最大输出字符数；超过后截断
  final int maxBodyLength;

  /// 需要脱敏的 query 参数（大小写不敏感）
  final Set<String> sensitiveQueryKeys;

  /// 默认脱敏的敏感头
  static const Set<String> defaultRedactedHeaders = {
    'authorization',
    'cookie',
    'set-cookie',
    'proxy-authorization',
    'x-api-key',
    'x-auth-token',
    'x-access-token',
    'x-csrf-token',
    'x-xsrf-token',
  };

  /// 构造函数
  ///
  /// [parts] 非空时，未列出的片段不输出；未传时使用包内默认值
  /// （默认不打印 request / response body）。[parts]、[redactedHeaders] 与
  /// [sensitiveQueryKeys] 都会被复制为不可变集合，构造后修改原集合不会影响本实例。
  ///
  /// [maxBodyLength] 为单条 body 的最大输出字符数，默认
  /// [defaultMaxBodyLength]；传 `<= 0` 表示不截断。
  WLogInterceptor({
    Set<WLogPart>? parts,
    this.enableLog = true,
    Set<String>? redactedHeaders,
    this.maxBodyLength = defaultMaxBodyLength,
    Set<String>? sensitiveQueryKeys,
  }) : parts = parts == null ? null : Set<WLogPart>.unmodifiable(parts),
       redactedHeaders = Set<String>.unmodifiable(
         (redactedHeaders ?? defaultRedactedHeaders).map((header) => header.toLowerCase()),
       ),
       sensitiveQueryKeys = Set<String>.unmodifiable(
         (sensitiveQueryKeys ?? defaultSensitiveQueryKeys).map((key) => key.toLowerCase()),
       ),
       _request = parts?.contains(WLogPart.request) ?? true,
       _requestHeader = parts?.contains(WLogPart.requestHeader) ?? true,
       _requestBody = parts?.contains(WLogPart.requestBody) ?? false,
       _responseHeader = parts?.contains(WLogPart.responseHeader) ?? false,
       _responseBody = parts?.contains(WLogPart.responseBody) ?? false,
       _error = parts?.contains(WLogPart.error) ?? true,
       _errorHint = parts?.contains(WLogPart.errorHint) ?? true;

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

    if (parts != null && parts!.isEmpty) {
      handler.next(options);
      return;
    }

    if (WApiConfig.logDebugHandler == null) {
      handler.next(options);
      return;
    }

    // parts 只开 error 等响应侧片段时，不要顺带打印请求行。
    if (parts != null && !_request && !_requestHeader && !_requestBody) {
      handler.next(options);
      return;
    }

    var builder = StringBuffer('*** Request *** \n');
    builder.write(_printKV('uri', _safeUri(options.uri)));

    if (_request) {
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
    if (_requestHeader) {
      builder.write('headers:\n');
      options.headers.forEach(
        (key, v) => builder.write(
          _printKV('  $key', _isRedacted(key) ? '***' : v),
        ),
      );
    }
    if (_requestBody) {
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

  /// 格式化为可读文本：Map/Iterable 走缩进 JSON，二进制只输出字节数
  String _message(dynamic res) {
    if (res is Uint8List) {
      return '<${res.length} bytes>';
    }
    String text;
    if (res is Map || res is Iterable) {
      var encoder = JsonEncoder.withIndent('  ', _toEncodableFallback);
      try {
        text = encoder.convert(res);
      } catch (_) {
        text = res.toString();
      }
    } else {
      text = res.toString();
    }
    return _truncate(text);
  }

  String _truncate(String text) {
    if (maxBodyLength <= 0 || text.length <= maxBodyLength) return text;
    return '${text.substring(0, maxBodyLength)}\n... (truncated, ${text.length} chars)';
  }

  /// query 中常见的敏感参数默认脱敏，避免 token 随 URI 进入日志。
  Uri _safeUri(Uri uri) {
    if (uri.queryParametersAll.isEmpty) return uri;

    var changed = false;
    final pairs = <String>[];
    uri.queryParametersAll.forEach((key, values) {
      final encodedKey = Uri.encodeQueryComponent(key);
      if (sensitiveQueryKeys.contains(key.toLowerCase())) {
        pairs.add('$encodedKey=***');
        changed = true;
      } else {
        for (final value in values) {
          pairs.add('$encodedKey=${Uri.encodeQueryComponent(value)}');
        }
      }
    });
    return changed ? uri.replace(query: pairs.join('&')) : uri;
  }

  /// 响应阶段：打印响应详情
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!enableLog || (parts != null && parts!.isEmpty)) {
      handler.next(response);
      return;
    }

    if (WApiConfig.logDebugHandler == null) {
      handler.next(response);
      return;
    }

    // parts 只开 error 等请求侧片段时，不要顺带打印响应行。
    if (parts != null && !_responseHeader && !_responseBody) {
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

    if (parts != null && parts!.isEmpty) {
      handler.next(err);
      return;
    }

    if (WApiConfig.logErrorHandler == null) {
      handler.next(err);
      return;
    }

    if (_error) {
      var builder = StringBuffer('*** DioError *** \n');
      builder.write('uri: ${_safeUri(err.requestOptions.uri)}\n');
      builder.write('$err');
      if (err.response != null) {
        _printResponse(err.response!, builder, (message) {
          WApiConfig.logErrorHandler?.call(message);
        });
      } else {
        WApiConfig.logErrorHandler?.call(builder.toString());
      }
    }

    if (_errorHint) _handleError(err);
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
    builder.write(_printKV('uri', _safeUri(response.requestOptions.uri)));
    // statusCode / redirect 属响应元信息，始终打印，不受 responseHeader 开关影响
    builder.write(_printKV('statusCode', response.statusCode));
    if (response.isRedirect == true) {
      builder.write(_printKV('redirect', response.realUri));
    }

    if (_responseHeader) {
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
    if (_responseBody) {
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
