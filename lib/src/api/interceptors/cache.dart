import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:w_tools/src/utils/logger.dart';

/// 内存缓存条目，记录响应和插入时间
class _CachedResponse {
  final Response response;
  final int timestamp;

  _CachedResponse(this.response) : timestamp = DateTime.now().millisecondsSinceEpoch;
}

/// 缓存拦截器，用于缓存 HTTP 请求响应
class WCacheInterceptor extends Interceptor {
  /// 构造函数
  ///
  /// @param maxCacheSize 最大缓存大小，默认 10MB
  /// @param maxCacheAge 最大缓存时间，默认 24 小时
  /// @param maxMemoryEntries 内存缓存最大条目数，默认 100
  /// @param cacheDirectory 缓存目录
  WCacheInterceptor({
    this.maxCacheSize = 1024 * 1024 * 10,
    this.maxCacheAge = 60 * 60 * 24,
    this.maxMemoryEntries = 100,
    Directory? cacheDirectory,
  }) : _cacheDirectory = cacheDirectory;

  /// 最大缓存大小
  final int maxCacheSize;

  /// 最大缓存时间
  final int maxCacheAge;

  /// 内存缓存最大条目数
  final int maxMemoryEntries;

  /// 缓存目录
  Directory? _cacheDirectory;
  Directory? get cacheDirectory => _cacheDirectory;

  /// 内存缓存（记录插入顺序，用于 LRU 淘汰）
  final Map<String, _CachedResponse> _memoryCache = {};

  /// 初始化缓存目录
  Future<void> _initCacheDirectory() async {
    if (_cacheDirectory == null) {
      final directory = Directory.systemTemp;
      _cacheDirectory = Directory('${directory.path}/flutter_w_cache');
      if (!_cacheDirectory!.existsSync()) {
        await _cacheDirectory!.create(recursive: true);
      }
    }
  }

  /// 请求拦截
  ///
  /// @param options 请求选项
  /// @param handler 请求处理器
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 确保缓存目录已初始化
    await _initCacheDirectory();

    // 只缓存GET请求
    if (options.method.toUpperCase() == 'GET') {
      final cacheKey = _generateCacheKey(options);

      // 先从内存缓存中查找
      if (_memoryCache.containsKey(cacheKey)) {
        final cachedEntry = _memoryCache[cacheKey];
        if (cachedEntry != null && !_isMemoryCacheExpired(cachedEntry)) {
          logD('使用内存缓存: ${options.uri}');
          handler.resolve(cachedEntry.response);
          return;
        } else if (cachedEntry != null) {
          // 缓存过期，移除
          _memoryCache.remove(cacheKey);
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
    // 确保缓存目录已初始化
    await _initCacheDirectory();

    // 只缓存GET请求
    if (response.requestOptions.method.toUpperCase() == 'GET') {
      final cacheKey = _generateCacheKey(response.requestOptions);

      // 内存缓存大小控制：超过限制时删除最旧的缓存（LRU 策略）
      if (_memoryCache.length >= maxMemoryEntries && !_memoryCache.containsKey(cacheKey)) {
        _evictOldestCache();
      }

      // 存储到内存缓存
      _memoryCache[cacheKey] = _CachedResponse(response);

      // 存储到磁盘缓存
      await _cacheResponse(cacheKey, response);

      // 清理过期缓存
      await _cleanExpiredCache();
    }

    handler.next(response);
  }

  /// 淘汰最旧的内存缓存
  void _evictOldestCache() {
    if (_memoryCache.isEmpty) return;

    // 找到最旧的缓存
    String? oldestKey;
    int oldestTimestamp = DateTime.now().millisecondsSinceEpoch;

    _memoryCache.forEach((key, entry) {
      final timestamp = entry.timestamp;
      if (timestamp < oldestTimestamp) {
        oldestTimestamp = timestamp;
        oldestKey = key;
      }
    });

    if (oldestKey != null) {
      _memoryCache.remove(oldestKey);
      logD('内存缓存已满，淘汰最旧缓存: $oldestKey');
    }
  }

  /// 生成缓存键
  ///
  /// @param options 请求选项
  /// @return 缓存键
  String _generateCacheKey(RequestOptions options) {
    final params = options.queryParameters;
    final paramsString = params.isEmpty ? '' : '?${_encodeParams(params)}';
    return '${options.baseUrl}${options.path}$paramsString';
  }

  /// 编码参数（URL 编码）
  ///
  /// @param params 参数
  /// @return 编码后的参数字符串
  String _encodeParams(Map<String, dynamic> params) {
    return params.entries.map((entry) {
      final key = Uri.encodeComponent(entry.key.toString());
      final value = Uri.encodeComponent(entry.value.toString());
      return '$key=$value';
    }).join('&');
  }

  /// 检查内存缓存是否过期
  ///
  /// @param entry 缓存条目
  /// @return 是否过期
  bool _isMemoryCacheExpired(_CachedResponse entry) {
    return DateTime.now().millisecondsSinceEpoch - entry.timestamp > maxCacheAge * 1000;
  }

  /// 获取缓存响应
  ///
  /// @param cacheKey 缓存键
  /// @return 缓存的响应
  Future<Response?> _getCachedResponse(String cacheKey) async {
    if (_cacheDirectory == null) return null;

    final cacheFile = File('${_cacheDirectory!.path}/${_hashKey(cacheKey)}');
    if (!cacheFile.existsSync()) return null;

    try {
      final content = await cacheFile.readAsString();
      final map = jsonDecode(content);

      final timestamp = map['timestamp'] as int;
      if (DateTime.now().millisecondsSinceEpoch - timestamp > maxCacheAge * 1000) {
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
    if (_cacheDirectory == null) return;

    try {
      final cacheFile = File('${_cacheDirectory!.path}/${_hashKey(cacheKey)}');
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
  Future<void> _cleanExpiredCache() async {
    if (_cacheDirectory == null) return;

    try {
      final files = _cacheDirectory!.listSync();
      int totalSize = 0;

      for (var file in files) {
        if (file is File) {
          final stat = file.statSync();
          totalSize += stat.size;

          if (DateTime.now().millisecondsSinceEpoch - stat.modified.millisecondsSinceEpoch >
              maxCacheAge * 1000) {
            file.deleteSync();
            totalSize -= stat.size;
          }
        }
      }

      if (totalSize > maxCacheSize) {
        final files = _cacheDirectory!.listSync().whereType<File>().toList();
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

  /// 生成 MD5 哈希键
  ///
  /// @param key 原始键
  /// @return MD5 哈希键
  String _hashKey(String key) {
    final bytes = utf8.encode(key);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// 清除所有缓存
  Future<void> clearCache() async {
    _memoryCache.clear();
    if (_cacheDirectory != null && _cacheDirectory!.existsSync()) {
      _cacheDirectory!.deleteSync(recursive: true);
      await _cacheDirectory!.create(recursive: true);
    }
  }
}
