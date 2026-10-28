import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 内存警告观察者
///
/// 实现 WidgetsBindingObserver 以安全地监听系统内存警告，
/// 不会覆盖其他库注册的 MethodChannel handler。
class _MemoryWarningObserver with WidgetsBindingObserver {
  final void Function(double percentage) _cleanCallback;

  _MemoryWarningObserver(this._cleanCallback);

  @override
  void didHaveMemoryPressure() {
    _cleanCallback(0.5);
  }
}

/// 缓存项类
///
/// 用于存储缓存的图片数据、时间戳和大小
class _CacheItem {
  final Uint8List data;
  DateTime timestamp;
  final int size;

  _CacheItem(this.data)
      : size = data.lengthInBytes,
        timestamp = DateTime.now();

  /// 更新时间戳
  void updateTimestamp() {
    timestamp = DateTime.now();
  }
}

/// 图片缓存管理器
///
/// 独立于 `WImage` 与 Flutter `ImageCache`：只用于 **资源字节预加载/统计**
/// （`preloadImage` / `cacheImage`），与 `ImageCache` 的内存预算互不影响。
/// `WImage` 本身已不再使用它，`WImageCachePolicy` 也不会修改它的上限。
///
/// 采用单例模式，实现了 LRU (Least Recently Used) 缓存策略。
class WImagePreloader {
  /// 单例实例
  static final WImagePreloader _instance = WImagePreloader._();

  /// 工厂构造函数
  factory WImagePreloader() => _instance;

  /// 私有构造函数
  WImagePreloader._() {
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
  int _maxCacheSize = 100;

  /// 最大缓存内存（100MB）
  int _maxCacheMemory = 100 * 1024 * 1024;

  /// 当前缓存内存
  int _currentCacheMemory = 0;

  /// 更新缓存上限（由 `WImageCachePolicy.configure` 调用）
  ///
  /// 缩小上限后若已超限，会立即按 LRU 清理。
  void configureLimits({int? maxCacheSize, int? maxCacheMemory}) {
    if (maxCacheSize != null && maxCacheSize > 0) {
      _maxCacheSize = maxCacheSize;
    }
    if (maxCacheMemory != null && maxCacheMemory > 0) {
      _maxCacheMemory = maxCacheMemory;
    }
    if (_cache.length > _maxCacheSize || _currentCacheMemory > _maxCacheMemory) {
      _cleanCacheUntilAvailable(0);
    }
  }

  /// 缓存命中次数
  int _cacheHits = 0;

  /// 缓存未命中次数
  int _cacheMisses = 0;

  /// 读取图片资源字节：命中缓存时直接返回，未命中则加载并写入缓存
  ///
  /// 同一资源的并发请求会复用同一个 [Future]，避免重复读取。
  ///
  /// - [assetPath]：图片资源路径
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

      // 超过单张图片内存上限时不入缓存，避免缓存被单张图片撑爆
      if (cacheItem.size <= _maxCacheMemory) {
        // 检查缓存大小和内存限制
        if (_cache.length >= _maxCacheSize ||
            _currentCacheMemory + cacheItem.size > _maxCacheMemory) {
          _cleanCacheUntilAvailable(cacheItem.size);
        }

        _currentCacheMemory += cacheItem.size;
        _cache[assetPath] = cacheItem;
      }
      completer.complete(uint8List);
    } catch (e) {
      completer.completeError(e);
    } finally {
      _pendingRequests.remove(assetPath);
    }

    return completer.future;
  }

  /// 预加载图片
  ///
  /// - [assetPath]：图片资源路径
  Future<void> preloadImage(String assetPath) async {
    await cacheImage(assetPath);
  }

  /// 批量预加载图片
  ///
  /// - [assetPaths]：图片资源路径列表
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
  /// 按最近访问时间从旧到新清理，直到同时满足内存与数量上限。
  /// - [requiredSize]：需要的空间大小
  void _cleanCacheUntilAvailable(int requiredSize) {
    final targetMemory = _currentCacheMemory + requiredSize - _maxCacheMemory;
    final targetCount = _cache.length - _maxCacheSize;

    if (targetMemory <= 0 && targetCount <= 0) return;

    // 按访问时间排序，优先清理最久未使用的
    final sortedKeys = _cache.keys.toList()
      ..sort((a, b) => _cache[a]!.timestamp.compareTo(_cache[b]!.timestamp));

    int cleanedMemory = 0;
    int cleanedCount = 0;

    for (final key in sortedKeys) {
      final bool memorySatisfied = targetMemory <= 0 || cleanedMemory >= targetMemory;
      final bool countSatisfied = targetCount <= 0 || cleanedCount >= targetCount;
      if (memorySatisfied && countSatisfied) break;

      final item = _cache.remove(key);
      if (item == null) continue;
      cleanedMemory += item.size;
      cleanedCount++;
      _currentCacheMemory -= item.size;
    }
  }

  /// 监听系统内存警告
  ///
  /// 通过 [WidgetsBindingObserver.didHaveMemoryPressure] 监听，
  /// 不会覆盖其它库注册的 MethodChannel handler。
  void _listenToMemoryWarnings() {
    WidgetsBinding.instance.addObserver(_MemoryWarningObserver(_cleanCacheByPercentage));
  }

  /// 按百分比清理缓存
  ///
  /// - [percentage]：清理百分比（0-1）
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

  /// 当前缓存的图片数量
  int get cacheSize => _cache.length;

  /// 当前缓存占用的内存（字节）
  int get cacheMemorySize => _currentCacheMemory;

  /// 缓存命中次数
  int get cacheHits => _cacheHits;

  /// 缓存未命中次数
  int get cacheMisses => _cacheMisses;

  /// 缓存命中率（0-1）
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
