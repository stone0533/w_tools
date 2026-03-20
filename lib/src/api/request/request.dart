// 网络请求处理模块

import 'package:dio/dio.dart';
import '../clients/dio_util.dart';
import 'dart:async';
import 'dart:convert';

/// 请求方法枚举
enum RequestMethod {
  get,
  post,
  put,
  delete,
  patch,
}

/// 请求参数类
class RequestParams {
  final Map<String, dynamic>? queryParameters;
  final dynamic data;
  final Options? options;
  final CancelToken? cancelToken;
  final int retryCount; // 重试次数
  final Duration retryDelay; // 重试延迟
  final bool enableCache; // 是否启用缓存

  const RequestParams({
    this.queryParameters,
    this.data,
    this.options,
    this.cancelToken,
    this.retryCount = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.enableCache = true,
  });
}

/// 请求缓存项
class RequestCacheItem<T> {
  final Response<T> response;
  final DateTime timestamp;
  final Duration? expiration;

  RequestCacheItem(this.response, this.timestamp, this.expiration);

  bool get isExpired {
    if (expiration == null) return false;
    return DateTime.now().difference(timestamp) > expiration!;
  }
}

/// 请求处理器
class RequestHandler {
  final DioUtil _dioUtil;
  final Map<String, Completer<Response>> _pendingRequests = {};
  final Map<String, RequestCacheItem> _cache = {};

  RequestHandler(this._dioUtil);

  /// 生成请求缓存键
  String _generateCacheKey(String path, RequestMethod method, RequestParams params) {
    final queryString = params.queryParameters != null ? json.encode(params.queryParameters) : '';
    final dataString = params.data != null ? json.encode(params.data) : '';
    return '$method:$path:$queryString:$dataString';
  }

  /// 发送请求
  Future<Response<T>> request<T>(
    String path,
    RequestMethod method,
    RequestParams params,
  ) async {
    final cacheKey = _generateCacheKey(path, method, params);

    // 检查缓存
    if (params.enableCache && _cache.containsKey(cacheKey)) {
      final cacheItem = _cache[cacheKey]!;
      if (!cacheItem.isExpired) {
        return cacheItem.response as Response<T>;
      } else {
        _cache.remove(cacheKey);
      }
    }

    // 检查是否已有相同请求
    if (_pendingRequests.containsKey(cacheKey)) {
      return _pendingRequests[cacheKey]!.future as Future<Response<T>>;
    }

    final completer = Completer<Response>();
    _pendingRequests[cacheKey] = completer;

    try {
      Response<T> response;
      int retryAttempts = 0;

      while (true) {
        try {
          switch (method) {
            case RequestMethod.get:
              response = await _dioUtil.dio.get<T>(
                path,
                queryParameters: params.queryParameters,
                options: params.options,
                cancelToken: params.cancelToken,
              );
              break;
            case RequestMethod.post:
              response = await _dioUtil.dio.post<T>(
                path,
                data: params.data,
                queryParameters: params.queryParameters,
                options: params.options,
                cancelToken: params.cancelToken,
              );
              break;
            case RequestMethod.put:
              response = await _dioUtil.dio.put<T>(
                path,
                data: params.data,
                queryParameters: params.queryParameters,
                options: params.options,
                cancelToken: params.cancelToken,
              );
              break;
            case RequestMethod.delete:
              response = await _dioUtil.dio.delete<T>(
                path,
                data: params.data,
                queryParameters: params.queryParameters,
                options: params.options,
                cancelToken: params.cancelToken,
              );
              break;
            case RequestMethod.patch:
              response = await _dioUtil.dio.patch<T>(
                path,
                data: params.data,
                queryParameters: params.queryParameters,
                options: params.options,
                cancelToken: params.cancelToken,
              );
              break;
          }

          // 缓存响应
          if (params.enableCache && method == RequestMethod.get) {
            final cacheExpiration = params.options?.extra?['cacheExpiration'] as Duration?;
            _cache[cacheKey] = RequestCacheItem(response, DateTime.now(), cacheExpiration);
          }

          completer.complete(response);
          return response;
        } catch (e) {
          if (e is DioException && retryAttempts < params.retryCount) {
            // 只对网络错误和超时错误进行重试
            if (e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.sendTimeout ||
                e.type == DioExceptionType.receiveTimeout) {
              retryAttempts++;
              await Future.delayed(params.retryDelay * retryAttempts);
              continue;
            }
          }
          completer.completeError(e);
          rethrow;
        }
      }
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  /// 发送 GET 请求
  Future<Response<T>> get<T>(
    String path,
    RequestParams params,
  ) async {
    return request<T>(path, RequestMethod.get, params);
  }

  /// 发送 POST 请求
  Future<Response<T>> post<T>(
    String path,
    RequestParams params,
  ) async {
    return request<T>(path, RequestMethod.post, params);
  }

  /// 发送 PUT 请求
  Future<Response<T>> put<T>(
    String path,
    RequestParams params,
  ) async {
    return request<T>(path, RequestMethod.put, params);
  }

  /// 发送 DELETE 请求
  Future<Response<T>> delete<T>(
    String path,
    RequestParams params,
  ) async {
    return request<T>(path, RequestMethod.delete, params);
  }

  /// 发送 PATCH 请求
  Future<Response<T>> patch<T>(
    String path,
    RequestParams params,
  ) async {
    return request<T>(path, RequestMethod.patch, params);
  }

  /// 清除缓存
  void clearCache() {
    _cache.clear();
  }

  /// 清除特定路径的缓存
  void clearCacheForPath(String path) {
    _cache.removeWhere((key, _) => key.contains(path));
  }
}
