import 'dart:convert';

import 'package:dio/dio.dart';
import '../../utils/logger.dart';

/// 日志打印函数类型
typedef LibLogPrint = void Function(String message);

/// 日志拦截器，用于记录 HTTP 请求和响应的详细信息
class WLogInterceptor extends Interceptor {
  /// 构造函数
  ///
  /// @param request 是否打印请求信息
  /// @param requestHeader 是否打印请求头
  /// @param requestBody 是否打印请求体
  /// @param responseHeader 是否打印响应头
  /// @param responseBody 是否打印响应体
  /// @param error 是否打印错误信息
  /// @param enableLog 是否启用日志
  WLogInterceptor({
    this.request = true,
    this.requestHeader = true,
    this.requestBody = true,
    this.responseHeader = false,
    this.responseBody = true,
    this.error = true,
    this.enableLog = true, // 添加环境判断开关
  });

  /// 是否打印请求信息
  bool request;

  /// 是否打印请求头
  bool requestHeader;

  /// 是否打印请求体
  bool requestBody;

  /// 是否打印响应体
  bool responseBody;

  /// 是否打印响应头
  bool responseHeader;

  /// 是否打印错误信息
  bool error;

  /// 是否启用日志
  bool enableLog;

  /// 请求拦截
  ///
  /// @param options 请求选项
  /// @param handler 请求处理器
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
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
      options.headers.forEach((key, v) => builder.write(_printKV('  $key', v)));
    }
    if (requestBody) {
      var res = options.data;
      builder.write('data:\n');
      builder.write(_message(res));
    }
    logD(builder.toString());
    handler.next(options);
  }

  /// 处理 JsonEncoder 无法处理的对象
  ///
  /// @param object 要处理的对象
  /// @return 可序列化的对象
  Object toEncodableFallback(dynamic object) {
    return object.toString();
  }

  /// 格式化消息
  ///
  /// @param res 要格式化的对象
  /// @return 格式化后的字符串
  String _message(dynamic res) {
    if (res is Map || res is Iterable) {
      var encoder = JsonEncoder.withIndent('  ', toEncodableFallback);
      return encoder.convert(res);
    } else {
      return res.toString();
    }
  }

  /// 响应拦截
  ///
  /// @param response 响应
  /// @param handler 响应处理器
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (!enableLog) {
      handler.next(response);
      return;
    }

    var builder = StringBuffer('*** Response *** \n');
    _printResponse(response, builder, (message) {
      logD(message);
    });
    handler.next(response);
  }

  /// 错误拦截
  ///
  /// @param err 错误
  /// @param handler 错误处理器
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
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
          logE(message);
        });
      } else {
        logE(builder.toString());
      }
    }

    // 优化错误处理逻辑
    _handleError(err);
    handler.next(err);
  }

  /// 处理错误
  ///
  /// @param err 错误
  void _handleError(DioException err) {
    // 根据错误类型进行不同的处理
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        // 网络超时处理
        logE('网络连接超时，请检查网络设置');
        break;
      case DioExceptionType.connectionError:
        // 网络连接错误处理
        logE('网络连接失败，请检查网络连接');
        break;
      case DioExceptionType.badResponse:
        // 服务器返回错误处理
        logE('服务器返回错误: ${err.response?.statusCode}');
        break;
      case DioExceptionType.cancel:
        // 请求取消处理
        logE('请求已取消');
        break;
      default:
        // 其他错误处理
        logE('网络请求失败: ${err.message}');
        break;
    }
  }

  /// 打印响应信息
  ///
  /// @param response 响应
  /// @param builder 字符串构建器
  /// @param pr 日志打印函数
  void _printResponse(Response response, StringBuffer builder, LibLogPrint pr) {
    builder.write(_printKV('uri', response.requestOptions.uri));
    if (responseHeader) {
      builder.write(_printKV('statusCode', response.statusCode));
      if (response.isRedirect == true) {
        builder.write(_printKV('redirect', response.realUri));
      }

      builder.write('headers:\n');
      response.headers.forEach(
        (key, v) => builder.write(_printKV(' $key', v.join('\r\n\t'))),
      );
    }
    if (responseBody) {
      var res = response.toString();
      builder.write('Response Text:\r\n');
      var resJ = res.trim();
      if (resJ.startsWith("{")) {
        Map<String, dynamic> decode = const JsonCodec().decode(resJ);
        builder.write(_message(decode));
      } else if (resJ.startsWith("[")) {
        List decode = const JsonCodec().decode(resJ);
        builder.write(_message(decode));
      } else {
        builder.write(res);
      }
    }
    pr(builder.toString());
  }

  /// 打印键值对
  ///
  /// @param key 键
  /// @param v 值
  /// @return 格式化的键值对字符串
  String _printKV(String key, Object? v) {
    return '$key: $v \n';
  }
}
