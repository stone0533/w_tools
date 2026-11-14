import 'package:dio/dio.dart';

import 'log_sanitizer.dart';
import 'log_support.dart' as log_support;

/// 日志输出片段。
enum WLogPart {
  request,
  requestHeader,
  requestBody,
  responseHeader,
  responseBody,
  error,
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

  /// 是否启用日志
  final bool enableLog;

  /// 需要脱敏的请求 / 响应头（大小写不敏感）
  final Set<String> redactedHeaders;

  /// 单条 body 的默认最大输出字符数；`<= 0` 表示不截断
  static const int defaultMaxBodyLength = 2000;

  /// 默认需要脱敏的 query 参数（大小写不敏感）
  static const Set<String> defaultSensitiveQueryKeys = log_support.defaultSensitiveQueryKeys;

  /// 默认需要脱敏的 body key（大小写不敏感）。
  ///
  /// 在 query 默认值之外补充登录 / 凭证常见字段；只做 key 精确匹配，不做子串匹配，
  /// 避免 `password_policy` 这类业务字段被误伤。
  static const Set<String> defaultSensitiveBodyKeys = {
    'token',
    'access_token',
    'refresh_token',
    'id_token',
    'api_key',
    'apikey',
    'secret',
    'client_secret',
    'password',
    'passwd',
    'pwd',
    'new_password',
    'old_password',
    'confirm_password',
    'verification_code',
    'sms_code',
    'auth',
    'authorization',
    'cookie',
    'session',
  };

  /// 单条 body 的最大输出字符数；超过后截断
  final int maxBodyLength;

  /// 需要脱敏的 query 参数（大小写不敏感）
  final Set<String> sensitiveQueryKeys;

  /// 需要脱敏的 body key（大小写不敏感）
  final Set<String> sensitiveBodyKeys;

  WLogSanitizer? _sanitizerCache;

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
  /// （默认不打印 request / response body）。[parts]、[redactedHeaders]、
  /// [sensitiveQueryKeys] 与 [sensitiveBodyKeys] 都会被复制为不可变集合，
  /// 构造后修改原集合不会影响本实例。
  ///
  /// [sensitiveBodyKeys] 用于 `requestBody` / `responseBody`：按 key 递归脱敏
  /// Map / List、JSON 字符串与 FormData 的字段；默认见
  /// [defaultSensitiveBodyKeys]。只做 key 精确匹配，不做子串匹配。
  ///
  /// [redactedHeaders]、[sensitiveQueryKeys]、[sensitiveBodyKeys] 会与内置默认值**合并**，
  /// 不能整体替换默认集合；需要完全自定义时请自行实现 `Interceptor`。
  ///
  /// [maxBodyLength] 为单条 body 的最大输出字符数，默认
  /// [defaultMaxBodyLength]；传 `<= 0` 表示不截断。
  WLogInterceptor({
    Set<WLogPart>? parts,
    this.enableLog = true,
    Set<String>? redactedHeaders,
    this.maxBodyLength = defaultMaxBodyLength,
    Set<String>? sensitiveQueryKeys,
    Set<String>? sensitiveBodyKeys,
  }) : parts = parts == null ? null : Set<WLogPart>.unmodifiable(parts),
       redactedHeaders = _mergeLower(
         redactedHeaders,
         defaultRedactedHeaders,
       ),
       sensitiveQueryKeys = _mergeLower(
         sensitiveQueryKeys,
         defaultSensitiveQueryKeys,
       ),
       sensitiveBodyKeys = _mergeLower(
         sensitiveBodyKeys,
         defaultSensitiveBodyKeys,
       ),
       _request = parts?.contains(WLogPart.request) ?? true,
       _requestHeader = parts?.contains(WLogPart.requestHeader) ?? true,
       _requestBody = parts?.contains(WLogPart.requestBody) ?? false,
       _responseHeader = parts?.contains(WLogPart.responseHeader) ?? false,
       _responseBody = parts?.contains(WLogPart.responseBody) ?? false,
       _error = parts?.contains(WLogPart.error) ?? true;

  static Set<String> _mergeLower(
    Set<String>? custom,
    Set<String> defaults,
  ) {
    final source = <String>{...defaults, ...?custom};
    return Set<String>.unmodifiable(
      source.map((value) => value.toLowerCase()),
    );
  }

  WLogSanitizer get _sanitizer => _sanitizerCache ??= WLogSanitizer(
    redactedHeaders: redactedHeaders,
    sensitiveQueryKeys: sensitiveQueryKeys,
    sensitiveBodyKeys: sensitiveBodyKeys,
    maxBodyLength: maxBodyLength,
  );

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

    if (!log_support.hasDebugHandler) {
      handler.next(options);
      return;
    }

    // parts 只开 error 等响应侧片段时，不要顺带打印请求行。
    if (parts != null && !_request && !_requestHeader && !_requestBody) {
      handler.next(options);
      return;
    }

    var builder = StringBuffer('*** Request *** \n');
    builder.write(_printKV('uri', _sanitizer.safeUri(options.uri)));

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
          _printKV('  $key', _sanitizer.isRedactedHeader(key) ? '***' : v),
        ),
      );
    }
    if (_requestBody) {
      var res = options.data;
      builder.write('data:\n');
      builder.write(_sanitizer.formatBody(res));
    }
    log_support.logDebug(builder.toString());
    handler.next(options);
  }

  /// 响应阶段：打印响应详情
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!enableLog || (parts != null && parts!.isEmpty)) {
      handler.next(response);
      return;
    }

    if (!log_support.hasDebugHandler) {
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
      log_support.logDebug(message);
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

    if (!log_support.hasErrorHandler) {
      handler.next(err);
      return;
    }

    // error 关掉但显式开了 responseHeader / responseBody 时，仍然输出
    // 错误响应片段；只开 response* 的人不应该拿到空日志。
    if (_error || (err.response != null && (_responseHeader || _responseBody))) {
      final builder = StringBuffer();
      if (_error) {
        builder.write('*** DioError *** \n');
        builder.write('uri: ${_sanitizer.safeUri(err.requestOptions.uri)}\n');
        builder.write('$err');
      }
      if (err.response != null) {
        if (_error) builder.write('\n');
        _printResponse(err.response!, builder, log_support.logError);
      } else {
        log_support.logError(builder.toString());
      }
    }

    handler.next(err);
  }

  /// 打印响应信息
  void _printResponse(Response response, StringBuffer builder, void Function(String) pr) {
    builder.write(_printKV('uri', _sanitizer.safeUri(response.requestOptions.uri)));
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
            _sanitizer.isRedactedHeader(key) ? '***' : v.join('\r\n\t'),
          ),
        ),
      );
    }
    if (_responseBody) {
      builder.write('Response Text:\r\n');
      // 直接使用 response.data，交由 sanitizer 安全格式化。
      // 不再用 response.toString() + 手动 jsonDecode：List 的 toString()（如 ["a","b"] → [a, b]）
      // 并非合法 JSON，会导致解析抛异常并让成功的请求失败。
      builder.write(_sanitizer.formatBody(response.data));
    }
    pr(builder.toString());
  }

  /// 打印键值对
  String _printKV(String key, Object? v) {
    return '$key: $v \n';
  }
}
