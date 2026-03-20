import 'dart:async';
import 'package:flutter/services.dart';

/// 缓存项类
///
/// 用于存储缓存的图片数据、时间戳和大小
class _CacheItem {
  final Uint8List data;
  DateTime timestamp;
  final int size;

  _CacheItem(this.data) : size = data.lengthInBytes, timestamp = DateTime.now();

  /// 更新时间戳
  void updateTimestamp() {
    timestamp = DateTime.now();
  }
}

/// 图片缓存管理器
///
/// 用于管理本地图片的缓存，采用单例模式
/// 实现了 LRU (Least Recently Used) 缓存策略
class WImageCacheManager {
  /// 单例实例
  static final WImageCacheManager _instance = WImageCacheManager._();

  /// 工厂构造函数
  factory WImageCacheManager() => _instance;

  /// 私有构造函数
  WImageCacheManager._() {
    // 监听内存警告
    _listenToMemoryWarnings();
  }

  /// 缓存映射，键为图片路径，值为缓存项
  /// 使用 LinkedHashMap 实现 LRU 缓存策略
  /// 注意：Dart 中集合字面量创建的就是 LinkedHashMap，保持插入顺序
  final Map<String, _CacheItem> _cache = {};

  /// 正在进行的请求映射，避免重复请求
  final Map<String, Completer<Uint8List>> _pendingRequests = {};

  /// 最大缓存数量
  final int _maxCacheSize = 100;

  /// 最大缓存内存（100MB）
  final int _maxCacheMemory = 100 * 1024 * 1024;

  /// 小型图片阈值（100KB）
  final int _smallImageThreshold = 100 * 1024;

  /// 中型图片阈值（1MB）
  final int _mediumImageThreshold = 1024 * 1024;

  /// 小型图片最大缓存数量
  final int _maxSmallImageCacheSize = 80;

  /// 中型图片最大缓存数量
  final int _maxMediumImageCacheSize = 15;

  /// 大型图片最大缓存数量
  final int _maxLargeImageCacheSize = 5;

  /// 当前缓存内存
  int _currentCacheMemory = 0;

  /// 缓存命中次数
  int _cacheHits = 0;

  /// 缓存未命中次数
  int _cacheMisses = 0;

  /// 缓存图片
  ///
  /// @param assetPath 图片资源路径
  /// @return Future<Uint8List> 图片数据
  Future<Uint8List> cacheImage(String assetPath) async {
    // 清理过期缓存
    _cleanExpiredCache();

    // 检查缓存中是否已有
    if (_cache.containsKey(assetPath)) {
      _cacheHits++;
      // 移动到缓存末尾，表示最近使用
      final item = _cache[assetPath]!;
      _cache.remove(assetPath);
      item.updateTimestamp(); // 更新时间戳，避免创建新对象
      _cache[assetPath] = item;
      return item.data;
    }

    _cacheMisses++;
    // 检查是否已有请求
    if (_pendingRequests.containsKey(assetPath)) {
      return _pendingRequests[assetPath]!.future;
    }

    // 创建新的请求
    final completer = Completer<Uint8List>();
    _pendingRequests[assetPath] = completer;

    try {
      final byteData = await rootBundle.load(assetPath);
      final uint8List = byteData.buffer.asUint8List();
      final cacheItem = _CacheItem(uint8List);

      // 检查缓存大小和内存限制
      if (_cache.length >= _maxCacheSize ||
          _currentCacheMemory + cacheItem.size > _maxCacheMemory) {
        _cleanCacheUntilAvailable(cacheItem.size);
      }

      _currentCacheMemory += cacheItem.size;
      _cache[assetPath] = cacheItem;
      completer.complete(uint8List);
    } catch (e) {
      // 使用日志框架记录错误
      // WLogger.e('Image cache error: $e');
      completer.completeError(e);
    } finally {
      _pendingRequests.remove(assetPath);
    }

    return completer.future;
  }

  /// 预加载图片
  ///
  /// @param assetPath 图片资源路径
  Future<void> preloadImage(String assetPath) async {
    await cacheImage(assetPath);
  }

  /// 批量预加载图片
  ///
  /// @param assetPaths 图片资源路径列表
  Future<void> preloadImages(List<String> assetPaths) async {
    await Future.wait(assetPaths.map(cacheImage));
  }

  /// 清理过期缓存
  void _cleanExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _cache.forEach((key, item) {
      if (now.difference(item.timestamp).inHours > 24) {
        expiredKeys.add(key);
        _currentCacheMemory -= item.size;
      }
    });

    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }

  /// 清理缓存直到有足够空间
  ///
  /// @param requiredSize 需要的空间大小
  void _cleanCacheUntilAvailable(int requiredSize) {
    // 计算需要清理的目标大小
    final targetMemory = _currentCacheMemory + requiredSize - _maxCacheMemory;
    final targetCount = _cache.length - _maxCacheSize;

    if (targetMemory <= 0 && targetCount <= 0) return;

    // 统计不同大小的图片数量
    int smallImageCount = 0;
    int mediumImageCount = 0;
    int largeImageCount = 0;

    _cache.forEach((key, item) {
      if (item.size < _smallImageThreshold) {
        smallImageCount++;
      } else if (item.size < _mediumImageThreshold) {
        mediumImageCount++;
      } else {
        largeImageCount++;
      }
    });

    // 按访问时间排序，优先清理最久未使用的
    final sortedKeys = _cache.keys.toList()
      ..sort((a, b) => _cache[a]!.timestamp.compareTo(_cache[b]!.timestamp));

    int cleanedMemory = 0;
    int cleanedCount = 0;

    for (final key in sortedKeys) {
      if ((targetMemory > 0 && cleanedMemory >= targetMemory) &&
          (targetCount > 0 && cleanedCount >= targetCount)) {
        break;
      }

      final item = _cache[key];
      if (item != null) {
        // 优先清理大型图片，然后是中型图片，最后是小型图片
        bool shouldClean = false;
        
        if (item.size >= _mediumImageThreshold && largeImageCount > _maxLargeImageCacheSize) {
          shouldClean = true;
          largeImageCount--;
        } else if (item.size >= _smallImageThreshold && item.size < _mediumImageThreshold && mediumImageCount > _maxMediumImageCacheSize) {
          shouldClean = true;
          mediumImageCount--;
        } else if (item.size < _smallImageThreshold && smallImageCount > _maxSmallImageCacheSize) {
          shouldClean = true;
          smallImageCount--;
        } else if (targetMemory > 0 || targetCount > 0) {
          // 如果还是需要清理，就按访问时间清理
          shouldClean = true;
        }

        if (shouldClean) {
          cleanedMemory += item.size;
          cleanedCount++;
          _currentCacheMemory -= item.size;
          _cache.remove(key);
        }
      }
    }
  }

  /// 监听内存警告
  void _listenToMemoryWarnings() {
    // 在Flutter中，通过SystemChannels来监听内存警告
    SystemChannels.platform.setMethodCallHandler((call) async {
      if (call.method == 'SystemNavigator.didReceiveMemoryWarning') {
        // 内存警告时清理一半缓存
        _cleanCacheByPercentage(0.5);
      }
    });
  }

  /// 按百分比清理缓存
  ///
  /// @param percentage 清理百分比（0-1）
  void _cleanCacheByPercentage(double percentage) {
    final targetCount = (_cache.length * (1 - percentage)).round();
    while (_cache.length > targetCount && _cache.isNotEmpty) {
      // 移除第一个元素（最不常用的）
      final key = _cache.keys.first;
      final item = _cache[key];
      if (item != null) {
        _currentCacheMemory -= item.size;
        _cache.remove(key);
      }
    }
  }

  /// 清除所有缓存
  void clearCache() {
    _cache.clear();
    _currentCacheMemory = 0;
  }

  /// 获取缓存大小
  ///
  /// @return int 缓存的图片数量
  int get cacheSize => _cache.length;

  /// 获取缓存内存大小
  ///
  /// @return int 缓存内存大小（字节）
  int get cacheMemorySize => _currentCacheMemory;

  /// 获取缓存命中次数
  ///
  /// @return int 缓存命中次数
  int get cacheHits => _cacheHits;

  /// 获取缓存未命中次数
  ///
  /// @return int 缓存未命中次数
  int get cacheMisses => _cacheMisses;

  /// 获取缓存命中率
  ///
  /// @return double 缓存命中率（0-1）
  double get cacheHitRate {
    final total = _cacheHits + _cacheMisses;
    return total > 0 ? _cacheHits / total : 0.0;
  }

  /// 重置缓存统计信息
  void resetCacheStats() {
    _cacheHits = 0;
    _cacheMisses = 0;
  }
}
