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
  });

  final File file;
  final Map<String, dynamic> json;
  final bool fromCache;
  final int tierCalls;
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
  }) {
    return _fetch(
      kind: 'file',
      file: store.cacheFile(kind: 'file', fileKey: fileKey, scale: depth),
      url: Uri.parse('https://api.figma.com/v1/files/$fileKey?depth=$depth'),
      refresh: refresh,
    );
  }

  Future<FetchResult> nodes({
    required String fileKey,
    required List<String> ids,
    bool refresh = false,
  }) {
    final joined = ids.join(',');
    return _fetch(
      kind: 'nodes',
      file: store.cacheFile(kind: 'nodes', fileKey: fileKey, ids: joined),
      url: Uri.parse('https://api.figma.com/v1/files/$fileKey/nodes?ids=$joined'),
      refresh: refresh,
    );
  }

  Future<FetchResult> images({
    required String fileKey,
    required List<String> ids,
    int scale = 2,
    bool refresh = false,
  }) {
    final joined = ids.join(',');
    return _fetch(
      kind: 'images',
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
    );
  }

  Future<FetchResult> _fetch({
    required String kind,
    required File file,
    required Uri url,
    required bool refresh,
  }) async {
    if (refresh && file.existsSync()) {
      file.deleteSync();
    }
    final cached = store.read(file);
    if (cached != null) {
      return FetchResult(file: file, json: cached, fromCache: true, tierCalls: 0);
    }
    final json = await client.getJson(url);
    store.write(file, json);
    if (log) {
      store.logUsage(kind: kind, cacheFile: file.uri.pathSegments.last);
    }
    return FetchResult(file: file, json: json, fromCache: false, tierCalls: 1);
  }
}
