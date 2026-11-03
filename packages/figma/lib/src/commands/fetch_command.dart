import 'dart:io';

import '../cache/cache_store.dart';
import '../client/figma_client.dart';

/// `fetch` 的结果（缓存命中或真实请求）。
class FetchResult {
  FetchResult({
    required this.file,
    required this.json,
    required this.fromCache,
    required this.tierCalls,
    this.stale = false,
    this.cachedVersion,
    this.latestVersion,
  });

  final File file;
  final Map<String, dynamic> json;
  final bool fromCache;
  final int tierCalls;

  /// 缓存命中但线上版本已变（需 `--refresh` 才会重拉）。
  final bool stale;
  final String? cachedVersion;
  final String? latestVersion;
}

/// 取数：`file` / `nodes` / `images`。
///
/// 规则（见 docs/figma-cli.md §2.4）：
/// - 缓存命中直接返回，不写日志、不算 Tier 1；
/// - `refresh` 才删除缓存并重新请求；
/// - 只有真的打了接口才写用量日志。
class FetchCommand {
  FetchCommand({required this.store, required this.client, this.log = true});

  final CacheStore store;
  final FigmaClient client;
  final bool log;

  Future<FetchResult> file({
    required String fileKey,
    int depth = 3,
    bool refresh = false,
    bool checkStale = false,
  }) {
    return _fetch(
      kind: 'file',
      fileKey: fileKey,
      file: store.cacheFile(kind: 'file', fileKey: fileKey, depth: depth),
      url: Uri.parse('https://api.figma.com/v1/files/$fileKey?depth=$depth'),
      refresh: refresh,
      checkStale: checkStale,
    );
  }

  Future<FetchResult> nodes({
    required String fileKey,
    required List<String> ids,
    int? depth,
    bool refresh = false,
    bool checkStale = false,
  }) {
    final joined = ids.join(',');
    return _fetch(
      kind: 'nodes',
      fileKey: fileKey,
      // 不同 depth 用不同缓存文件，避免 `--depth=1` 的结果覆盖完整缓存
      file: store.cacheFile(kind: 'nodes', fileKey: fileKey, ids: joined, depth: depth),
      url: Uri.parse(
        'https://api.figma.com/v1/files/$fileKey/nodes?ids=$joined'
        '${depth == null ? '' : '&depth=$depth'}',
      ),
      refresh: refresh,
      checkStale: checkStale,
    );
  }

  Future<FetchResult> images({
    required String fileKey,
    required List<String> ids,
    int scale = 2,
    bool refresh = false,
    bool checkStale = false,
  }) {
    final joined = ids.join(',');
    return _fetch(
      kind: 'images',
      fileKey: fileKey,
      file: store.cacheFile(
        kind: 'images',
        fileKey: fileKey,
        ids: joined,
        scale: scale,
      ),
      url: Uri.parse(
        'https://api.figma.com/v1/images/$fileKey?ids=$joined&format=png&scale=$scale',
      ),
      refresh: refresh,
      checkStale: checkStale,
    );
  }

  Future<FetchResult> _fetch({
    required String kind,
    required String fileKey,
    required File file,
    required Uri url,
    required bool refresh,
    required bool checkStale,
  }) async {
    final cached = refresh ? null : store.read(file);
    if (cached != null) {
      final stale = checkStale ? await _checkStale(fileKey, updateMeta: false) : null;
      return FetchResult(
        file: file,
        json: cached,
        fromCache: true,
        tierCalls: 0,
        stale: stale?.stale ?? false,
        cachedVersion: stale?.cachedVersion,
        latestVersion: stale?.latestVersion,
      );
    }
    final json = await client.getJson(url);
    store.write(file, json);
    if (log) {
      store.logUsage(kind: kind, cacheFile: file.uri.pathSegments.last);
    }
    if (checkStale) await _checkStale(fileKey, updateMeta: true);
    return FetchResult(
      file: file,
      json: json,
      fromCache: false,
      tierCalls: 1,
      stale: false,
    );
  }

  /// 用 Tier 3 的 `file/meta`（不占 20 次/月）判断缓存是否过期。
  ///
  /// 只提示、不自动重拉：自动重拉会在不知不觉中消耗 Tier 1。
  Future<({bool stale, String? cachedVersion, String? latestVersion})?> _checkStale(
    String fileKey, {
    required bool updateMeta,
  }) async {
    final metaUrl = Uri.parse('https://api.figma.com/v1/files/$fileKey/meta');
    final meta = await client.getJson(metaUrl);
    final fileMeta = meta['file'];
    final latest = fileMeta is Map ? '${fileMeta['version'] ?? ''}' : '';
    if (latest.isEmpty) return null;

    final metaFile = store.metaFile(fileKey);
    final previous = store.read(metaFile);
    final cachedVersion = previous == null ? null : '${previous['version'] ?? ''}';
    final stale = cachedVersion != null && cachedVersion.isNotEmpty && cachedVersion != latest;
    // 缓存命中时不能把 latest 写进 meta，否则第一次报 stale 后，
    // 下一次检查会误以为缓存已经是最新版本。
    // 第一次看到该 fileKey 时建立基线；之后缓存命中绝不覆盖已有 meta。
    if (updateMeta || previous == null) {
      store.write(metaFile, {
        'version': latest,
        'lastTouchedAt': fileMeta is Map ? '${fileMeta['lastTouchedAt'] ?? ''}' : '',
        'checkedAt': DateTime.now().toIso8601String(),
      });
    }
    return (stale: stale, cachedVersion: cachedVersion, latestVersion: latest);
  }
}
