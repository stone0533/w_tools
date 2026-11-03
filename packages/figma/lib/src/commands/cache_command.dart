import 'dart:io';

import '../cache/cache_store.dart';

/// 一个缓存目录的统计。
class CacheStats {
  CacheStats({required this.dir, required this.files, required this.bytes});

  final Directory dir;
  final int files;
  final int bytes;

  double get megabytes => bytes / (1024 * 1024);

  Map<String, Object?> toJson() => {
        'dir': dir.path,
        'files': files,
        'bytes': bytes,
        'megabytes': double.parse(megabytes.toStringAsFixed(1)),
      };
}

/// `figma cache stats | clean` 的实现。
class CacheCommand {
  CacheCommand(this.store);

  final CacheStore store;

  CacheStats stats() {
    var files = 0;
    var bytes = 0;
    if (store.dir.existsSync()) {
      for (final entity in store.dir.listSync(recursive: true)) {
        if (entity is! File) continue;
        files++;
        bytes += entity.statSync().size;
      }
    }
    return CacheStats(dir: store.dir, files: files, bytes: bytes);
  }

  /// 删除当前项目缓存；[all] 时删除账号下所有项目缓存（保留用量/预算）。
  /// 返回清理的目录数与字节数。
  (int dirs, int bytes) clean({bool all = false}) {
    final targets = <Directory>[];
    if (all) {
      if (store.cacheRoot.existsSync()) {
        for (final entity in store.cacheRoot.listSync()) {
          if (entity is Directory) targets.add(entity);
        }
      }
    } else if (store.dir.existsSync()) {
      targets.add(store.dir);
    }

    var bytes = 0;
    for (final dir in targets) {
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File) bytes += entity.statSync().size;
      }
      dir.deleteSync(recursive: true);
    }
    return (targets.length, bytes);
  }
}
