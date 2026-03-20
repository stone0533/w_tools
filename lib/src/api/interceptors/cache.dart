import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:w_tools/src/utils/logger.dart';

/// 缓存拦截器，用于缓存 HTTP 请求响应
class WCacheInterceptor extends Interceptor {
  /// 构造函数
  ///
  /// @param maxCacheSize 最大缓存大小，默认 10MB
  /// @param maxCacheAge 最大缓存时间，默认 24 小时
  /// @param cacheDirectory 缓存目录
  WCacheInterceptor({
    this.maxCacheSize = 1024 * 1024 * 10, // 默认10MB缓存
    this.maxCacheAge = 60 * 60 * 24, // 默认24小时
    this.cacheDirectory,
  }) {
    _initCacheDirectory();
  }

  /// 最大缓存大小
  final int maxCacheSize;

  /// 最大缓存时间
  final int maxCacheAge;

  /// 缓存目录
  Directory? cacheDirectory;

  /// 内存缓存
  final Map<String, Response> _memoryCache = {};

  /// 初始化缓存目录
  void _initCacheDirectory() async {
    if (cacheDirectory == null) {
      final directory = Directory.systemTemp;
      cacheDirectory = Directory('${directory.path}/flutter_w_cache');
      if (!cacheDirectory!.existsSync()) {
        cacheDirectory!.createSync(recursive: true);
      }
    }
  }

  /// 请求拦截
  ///
  /// @param options 请求选项
  /// @param handler 请求处理器
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 只缓存GET请求
    if (options.method.toUpperCase() == 'GET') {
      final cacheKey = _generateCacheKey(options);

      // 先从内存缓存中查找
      if (_memoryCache.containsKey(cacheKey)) {
        final cachedResponse = _memoryCache[cacheKey];
        if (cachedResponse != null && !_isCacheExpired(cachedResponse)) {
          logD('使用内存缓存: ${options.uri}');
          handler.resolve(cachedResponse);
          return;
        }
      }

      // 再从磁盘缓存中查找
      final cachedResponse = await _getCachedResponse(cacheKey);
      if (cachedResponse != null) {
        logD('使用磁盘缓存: ${options.uri}');
        handler.resolve(cachedResponse);
        return;
      }
    }

    handler.next(options);
  }

  /// 响应拦截
  ///
  /// @param response 响应
  /// @param handler 响应处理器
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // 只缓存GET请求
    if (response.requestOptions.method.toUpperCase() == 'GET') {
      final cacheKey = _generateCacheKey(response.requestOptions);

      // 存储到内存缓存
      _memoryCache[cacheKey] = response;

      // 存储到磁盘缓存
      await _cacheResponse(cacheKey, response);

      // 清理过期缓存
      _cleanExpiredCache();
    }

    handler.next(response);
  }

  /// 生成缓存键
  ///
  /// @param options 请求选项
  /// @return 缓存键
  String _generateCacheKey(RequestOptions options) {
    // 根据请求URL和参数生成缓存键
    final params = options.queryParameters;
    final paramsString = params.isEmpty ? '' : '?${_encodeParams(params)}';
    return '${options.baseUrl}${options.path}$paramsString';
  }

  /// 编码参数
  ///
  /// @param params 参数
  /// @return 编码后的参数字符串
  String _encodeParams(Map<String, dynamic> params) {
    return params.entries.map((entry) => '${entry.key}=${entry.value}').join('&');
  }

  /// 检查缓存是否过期
  ///
  /// @param response 响应
  /// @return 是否过期
  bool _isCacheExpired(Response response) {
    final timestamp = response.extra['cacheTimestamp'] as int?;
    if (timestamp == null) return true;
    return DateTime.now().millisecondsSinceEpoch - timestamp > maxCacheAge * 1000;
  }

  /// 获取缓存响应
  ///
  /// @param cacheKey 缓存键
  /// @return 缓存的响应
  Future<Response?> _getCachedResponse(String cacheKey) async {
    if (cacheDirectory == null) return null;

    final cacheFile = File('${cacheDirectory!.path}/${_hashKey(cacheKey)}');
    if (!cacheFile.existsSync()) return null;

    try {
      final content = await cacheFile.readAsString();
      final map = jsonDecode(content);

      final timestamp = map['timestamp'] as int;
      if (DateTime.now().millisecondsSinceEpoch - timestamp > maxCacheAge * 1000) {
        // 缓存过期
        cacheFile.deleteSync();
        return null;
      }

      final response = Response(
        requestOptions: RequestOptions(
          baseUrl: map['baseUrl'],
          path: map['path'],
          method: map['method'],
          queryParameters: map['queryParameters'],
        ),
        statusCode: map['statusCode'],
        headers: Headers.fromMap(map['headers']),
        data: map['data'],
      )..extra['cacheTimestamp'] = timestamp;

      return response;
    } catch (e) {
      logE('读取缓存失败: $e');
      cacheFile.deleteSync();
      return null;
    }
  }

  /// 缓存响应
  ///
  /// @param cacheKey 缓存键
  /// @param response 响应
  Future<void> _cacheResponse(String cacheKey, Response response) async {
    if (cacheDirectory == null) return;

    try {
      final cacheFile = File('${cacheDirectory!.path}/${_hashKey(cacheKey)}');
      final map = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'baseUrl': response.requestOptions.baseUrl,
        'path': response.requestOptions.path,
        'method': response.requestOptions.method,
        'queryParameters': response.requestOptions.queryParameters,
        'statusCode': response.statusCode,
        'headers': response.headers.map,
        'data': response.data,
      };

      await cacheFile.writeAsString(jsonEncode(map));
      response.extra['cacheTimestamp'] = map['timestamp'];
    } catch (e) {
      logE('写入缓存失败: $e');
    }
  }

  /// 清理过期缓存
  void _cleanExpiredCache() async {
    if (cacheDirectory == null) return;

    try {
      final files = cacheDirectory!.listSync();
      int totalSize = 0;

      for (var file in files) {
        if (file is File) {
          final stat = file.statSync();
          totalSize += stat.size;

          // 删除过期缓存
          if (DateTime.now().millisecondsSinceEpoch - stat.modified.millisecondsSinceEpoch >
              maxCacheAge * 1000) {
            file.deleteSync();
            totalSize -= stat.size;
          }
        }
      }

      // 如果缓存大小超过限制，删除最旧的文件
      if (totalSize > maxCacheSize) {
        final files = cacheDirectory!.listSync().whereType<File>().toList();
        files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));

        for (var file in files) {
          if (totalSize <= maxCacheSize) break;
          final stat = file.statSync();
          file.deleteSync();
          totalSize -= stat.size;
        }
      }
    } catch (e) {
      logE('清理缓存失败: $e');
    }
  }

  /// 生成哈希键
  ///
  /// @param key 原始键
  /// @return 哈希键
  String _hashKey(String key) {
    // 使用简单的哈希算法生成文件名
    int hash = 0;
    for (int i = 0; i < key.length; i++) {
      hash = key.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return hash.toString();
  }

  /// 清除所有缓存
  Future<void> clearCache() async {
    _memoryCache.clear();
    if (cacheDirectory != null && cacheDirectory!.existsSync()) {
      cacheDirectory!.deleteSync(recursive: true);
      cacheDirectory!.createSync(recursive: true);
    }
  }
}
