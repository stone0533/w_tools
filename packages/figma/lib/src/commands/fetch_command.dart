import 'dart:io';

import '../cache/cache_store.dart';
import '../cache/nodes_index.dart';
import '../client/figma_client.dart';
import 'file_meta.dart';

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
    this.missingNodeIds = const <String>[],
  });

  final File file;
  final Map<String, dynamic> json;
  final bool fromCache;
  final int tierCalls;

  /// 缓存命中但线上版本已变（需 `--refresh` 才会重拉）。
  final bool stale;
  final String? cachedVersion;
  final String? latestVersion;

  /// 请求了但 Figma 返回 null / 缺失的 nodeId。
  final List<String> missingNodeIds;
}

/// 取数：`nodes` / `imageUrls`（图片地址不缓存）。
///
/// 规则（见 packages/figma/README.md 的「缓存与额度」）：
/// - 缓存命中直接返回，不写日志、不算 Tier 1；
/// - `refresh` 跳过缓存读取并重新请求，成功后覆盖；失败保留旧缓存；
/// - 只有真的打了接口才写用量日志。
class FetchCommand {
  FetchCommand({
    required this.store,
    required this.client,
    this.log = true,
  });

  final CacheStore store;
  final FigmaClient client;
  final bool log;

  Future<FetchResult> nodes({
    required String fileKey,
    required List<String> ids,
    int? depth,
    bool refresh = false,
    bool checkStale = false,
  }) {
    final joined = _canonicalIds(ids);
    return _fetch(
      kind: 'nodes',
      fileKey: fileKey,
      // 不同 depth 用不同缓存文件，避免 `--depth=1` 的结果覆盖完整缓存
      file: store.cacheFile(kind: 'nodes', fileKey: fileKey, ids: joined, depth: depth),
      request: () => client.fileNodes(fileKey, joined, depth: depth),
      requestedIds: ids,
      refresh: refresh,
      checkStale: checkStale,
    );
  }

  /// 取图片下载地址（nodeId → 签名 URL）；不写缓存：Figma 的签名 URL 会过期。
  ///
  /// 每次调用都会请求 Figma（1 次 Tier 1），即使同一组 ids 之前取过。
  Future<Map<String, String?>> imageUrls({
    required String fileKey,
    required List<String> ids,
    int scale = 2,
  }) async {
    final joined = _canonicalIds(ids);
    final json = await client.fileImages(fileKey, joined, scale: scale);
    if (log) {
      store.logUsage(kind: 'images', cacheFile: 'imageUrls:$fileKey');
    }
    final raw = json['images'];
    final urls = <String, String?>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final value = entry.value;
        urls['${entry.key}'] = value is String && value.isNotEmpty ? value : null;
      }
    }
    return urls;
  }

  /// ids 的缓存 key / URL 参数顺序不应影响命中；去重后按字符串排序。
  String _canonicalIds(Iterable<String> ids) {
    final unique = ids.toSet().toList()..sort();
    return unique.join(',');
  }

  Future<FetchResult> _fetch({
    required String kind,
    required String fileKey,
    required File file,
    required Future<Map<String, dynamic>> Function() request,
    List<String>? requestedIds,
    required bool refresh,
    required bool checkStale,
  }) async {
    final cached = refresh ? null : store.read(file);
    if (cached != null) {
      final stale = checkStale
          ? await _checkStale(
              fileKey,
              updateMeta: false,
              cachedVersion: '${cached['version'] ?? ''}',
            )
          : null;
      final cachedMissing = <String>{
        ...?(cached['missingNodeIds'] as List?)?.map((e) => '$e'),
      };
      if (requestedIds != null) {
        final nodes = cached['nodes'];
        for (final id in requestedIds) {
          if (nodes is! Map || nodes[id] is! Map) cachedMissing.add(id);
        }
      }
      if (cachedMissing.isNotEmpty && requestedIds != null) {
        final extra = _mergedCachedNodes(
          cachedMissing.toList(),
          nodesCacheDepth(file.path),
          fileKey,
        );
        final extraNodes = extra?['nodes'];
        final cachedNodes = cached['nodes'];
        if (extraNodes is Map && cachedNodes is Map) {
          final remaining = cachedMissing.difference(
            extraNodes.keys.map((key) => '$key').toSet(),
          );
          final merged = <String, dynamic>{
            ...cached,
            'nodes': <String, dynamic>{...cachedNodes, ...extraNodes},
          };
          if (remaining.isEmpty) {
            merged.remove('missingNodeIds');
          } else {
            merged['missingNodeIds'] = remaining.toList();
          }
          store.write(file, merged);
          return FetchResult(
            file: file,
            json: merged,
            fromCache: true,
            tierCalls: 0,
            stale: stale?.stale ?? false,
            cachedVersion: stale?.cachedVersion,
            latestVersion: stale?.latestVersion,
            missingNodeIds: remaining.toList(),
          );
        }
      }
      return FetchResult(
        file: file,
        json: cached,
        fromCache: true,
        tierCalls: 0,
        stale: stale?.stale ?? false,
        cachedVersion: stale?.cachedVersion,
        latestVersion: stale?.latestVersion,
        missingNodeIds: cachedMissing.toList(),
      );
    }
    final targetDepth = nodesCacheDepth(file.path);
    if (!refresh &&
        requestedIds != null &&
        requestedIds.isNotEmpty &&
        !file.existsSync() &&
        targetDepth != null) {
      final full = _fullCacheForIds(requestedIds, fileKey);
      if (full != null) {
        final fullJson = store.read(full);
        if (fullJson != null) {
          final stale = checkStale
              ? await _checkStale(
                  fileKey,
                  updateMeta: false,
                  cachedVersion: '${fullJson['version'] ?? ''}',
                )
              : null;
          return FetchResult(
            file: full,
            json: fullJson,
            fromCache: true,
            tierCalls: 0,
            stale: stale?.stale ?? false,
            cachedVersion: stale?.cachedVersion,
            latestVersion: stale?.latestVersion,
          );
        }
      }
    }
    if (!refresh && requestedIds != null && requestedIds.isNotEmpty && !file.existsSync()) {
      final merged = _mergedCachedNodes(
        requestedIds,
        targetDepth,
        fileKey,
      );
      if (merged != null) {
        store.write(file, merged);
        final stale = checkStale
            ? await _checkStale(
                fileKey,
                updateMeta: false,
                cachedVersion: '${merged['version'] ?? ''}',
              )
            : null;
        return FetchResult(
          file: file,
          json: merged,
          fromCache: true,
          tierCalls: 0,
          stale: stale?.stale ?? false,
          cachedVersion: stale?.cachedVersion,
          latestVersion: stale?.latestVersion,
        );
      }
    }
    if (!refresh && file.existsSync()) {
      throw StateError(
        '缓存文件损坏：${file.path}；用 --refresh 重新拉取，或先 cache clean',
      );
    }
    // 只有真的要走网络才写缓存与日志（缓存命中在上面已经返回）
    var json = await request();
    var missing = const <String>[];
    if (kind == 'nodes' && requestedIds != null && requestedIds.isNotEmpty) {
      final nodes = json['nodes'];
      if (nodes is! Map) {
        if (log) store.logUsage(kind: kind, cacheFile: '-');
        throw StateError(
          'Figma 返回的 nodes 字段不是对象（fileKey=$fileKey；本次已消耗 1 次 Tier 1）',
        );
      }
      final requested = requestedIds.toSet();
      missing = <String>[
        for (final id in requested)
          if (nodes[id] is! Map) id,
      ];
      if (missing.length == requested.length) {
        if (log) store.logUsage(kind: kind, cacheFile: '-');
        throw StateError(
          'Figma 没有返回节点：${missing.join(', ')}'
          '（nodeId 不存在或无权访问；本次已消耗 1 次 Tier 1）',
        );
      }
      if (missing.isNotEmpty) {
        final filtered = Map<String, dynamic>.from(nodes)
          ..removeWhere((key, value) => requested.contains(key) && value is! Map);
        json = <String, dynamic>{...json, 'nodes': filtered, 'missingNodeIds': missing};
      }
    }
    if (log) {
      store.logUsage(kind: kind, cacheFile: file.uri.pathSegments.last);
    }
    store.write(file, json);
    if (checkStale) await _checkStale(fileKey, updateMeta: true);
    return FetchResult(
      file: file,
      json: json,
      fromCache: false,
      tierCalls: 1,
      stale: false,
      missingNodeIds: missing,
    );
  }

  Map<String, dynamic>? _nodeEntry(File file, String id) {
    final raw = store.read(file);
    final nodes = raw?['nodes'];
    if (nodes is! Map || nodes[id] is! Map) return null;
    return Map<String, dynamic>.from(nodes[id] as Map);
  }

  /// 找一份包含全部 ids 的完整缓存；找不到或分布在多个文件时返回 null。
  File? _fullCacheForIds(List<String> ids, String fileKey) {
    try {
      final sources = resolveNodeCaches(
        store,
        ids,
        fileKey: fileKey,
        preferFullDepth: true,
      );
      final files = sources.values.toSet();
      if (files.length == 1) {
        final file = files.single;
        return nodesCacheDepth(file.path) == null && store.read(file) != null ? file : null;
      }
      final nodes = <String, dynamic>{};
      for (final id in ids) {
        final file = sources[id]!;
        if (nodesCacheDepth(file.path) != null) return null;
        final entry = _nodeEntry(file, id);
        if (entry == null) return null;
        nodes[id] = entry;
      }
      final full = store.cacheFile(
        kind: 'nodes',
        fileKey: fileKey,
        ids: _canonicalIds(ids),
      );
      final existing = store.read(full);
      final firstRaw = store.read(sources[ids.first]!);
      final existingNodes = existing?['nodes'];
      final mergedNodes = <String, dynamic>{
        if (existingNodes is Map) ...Map<String, dynamic>.from(existingNodes),
        ...nodes,
      };
      final payload = <String, dynamic>{
        ...?firstRaw,
        ...?existing,
        'nodes': mergedNodes,
      };
      final oldMissing = existing?['missingNodeIds'];
      if (oldMissing is List) {
        final remaining = oldMissing.where((id) => !mergedNodes.containsKey('$id')).toList();
        if (remaining.isEmpty) {
          payload.remove('missingNodeIds');
        } else {
          payload['missingNodeIds'] = remaining;
        }
      }
      payload.remove('missingNodeIds');
      store.write(full, payload);
      return full;
    } on StateError {
      return null;
    } on FormatException {
      return null;
    }
  }

  /// 从已有 nodes 缓存里按单 id 拼出一份缓存；全部命中时避免重烧 Tier 1。
  Map<String, dynamic>? _mergedCachedNodes(
    List<String> ids,
    int? targetDepth,
    String fileKey,
  ) {
    try {
      final sources = resolveNodeCaches(
        store,
        ids,
        fileKey: fileKey,
        preferFullDepth: targetDepth == null,
        targetDepth: targetDepth,
      );
      final nodes = <String, dynamic>{};
      Map<String, dynamic>? topLevel;
      for (final id in ids) {
        final file = sources[id]!;
        // 完整目标不能拿裁剪缓存拼：否则 `fetch nodes K id` 会以为拿到了完整树。
        if (targetDepth == null && nodesCacheDepth(file.path) != null) return null;
        final entry = _nodeEntry(file, id);
        if (entry == null) return null;
        if (topLevel == null) {
          final raw = store.read(file);
          if (raw != null) {
            topLevel = Map<String, dynamic>.from(raw)..remove('nodes');
          }
        }
        nodes[id] = entry;
      }
      final merged = <String, dynamic>{...?topLevel, 'nodes': nodes};
      merged.remove('missingNodeIds');
      return merged;
    } on StateError {
      return null;
    } on FormatException {
      return null;
    }
  }

  /// 用 Tier 3 的 `file/meta`（不占 20 次/月）判断缓存是否过期。
  ///
  /// 只提示、不自动重拉：自动重拉会在不知不觉中消耗 Tier 1。
  Future<({bool stale, String? cachedVersion, String? latestVersion})?> _checkStale(
    String fileKey, {
    required bool updateMeta,
    String? cachedVersion,
  }) async {
    final fileMeta = await readFileMeta(client, fileKey);
    final latest = fileMeta?.version;
    if (latest == null) return null;

    final metaFile = store.metaFile(fileKey);
    final previous = store.read(metaFile);
    final cached = cachedVersion ?? (previous == null ? '' : '${previous['version'] ?? ''}');
    final stale = cached.isNotEmpty && cached != latest;
    // 缓存命中时不能把 latest 写进 meta，否则第一次报 stale 后，
    // 下一次检查会误以为缓存已经是最新版本。
    // 第一次看到该 fileKey 时建立基线；之后缓存命中绝不覆盖已有 meta。
    if (updateMeta || previous == null) {
      store.write(metaFile, {
        'version': latest,
        if (fileMeta?.lastTouchedAt != null) 'lastTouchedAt': fileMeta!.lastTouchedAt,
        'checkedAt': DateTime.now().toIso8601String(),
      });
    }
    return (
      stale: stale,
      cachedVersion: cached.isEmpty ? null : cached,
      latestVersion: latest,
    );
  }
}
