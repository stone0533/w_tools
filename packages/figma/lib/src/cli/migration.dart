import 'dart:io';

import '../cache/cache_store.dart';

/// 迁移 marker：放在项目缓存目录里，一个项目只迁一次。
File migratedMarker(CacheStore store) => File('${store.dir.path}/_migrated-v1');

/// 把 `<project>/.figma-cache/`、`<project>/.figma-token` 一次性搬到用户目录。
///
/// - marker 已存在 → 直接返回空（不再 stat 旧路径，也不再重复打印 note）；
/// - 旧路径都不存在 → 返回空且**不写 marker**（项目以后被拷进老数据时仍能迁）；
/// - 有旧路径 → 走 [CacheStore.migrateLegacy]，成功后写 marker。
///
/// 迁移本身是公开方法，这里只负责"每个项目只跑一次"的收口。
List<String> ensureLegacyMigrated(CacheStore store) {
  final marker = migratedMarker(store);
  if (marker.existsSync()) return const <String>[];
  if (!store.legacyDir.existsSync() && !store.legacyTokenFile.existsSync()) {
    return const <String>[];
  }
  final notes = store.migrateLegacy();
  marker.parent.createSync(recursive: true);
  marker.writeAsStringSync(DateTime.now().toIso8601String());
  return notes;
}
