import 'package:dio/dio.dart';

/// Cookie 拦截器，用于管理 HTTP 请求和响应中的 Cookie
class WCookieInterceptor extends Interceptor {
  /// 用于存储 Cookie 的 Map
  final Map<String, String> _cookies = {};

  /// 请求拦截
  ///
  /// @param options 请求选项
  /// @param handler 请求处理器
  /// @description 在请求发送之前添加 Cookie 到请求头中
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 在请求发送之前添加 Cookie 到请求头中
    if (_cookies.isNotEmpty) {
      options.headers['Cookie'] = _cookies.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('; ');
    }
    super.onRequest(options, handler);
  }

  /// 响应拦截
  ///
  /// @param response 响应
  /// @param handler 响应处理器
  /// @description 在响应返回之后保存新的 Cookie
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 在响应返回之后保存新的 Cookie
    final headers = response.headers.map;
    if (headers.containsKey('set-cookie')) {
      final cookies = headers['set-cookie']!;
      for (final cookie in cookies) {
        final parts = cookie.split(';').first.split('=');
        if (parts.length == 2) {
          final key = parts[0].trim();
          final value = parts[1].trim();
          _cookies[key] = value;
        }
      }
    }
    //
    super.onResponse(response, handler);
  }
}
