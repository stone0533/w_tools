import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import '../spec/cache_document.dart';

/// 每个 nodeId 对应的缓存文件；用于 tokens / spec 跨缓存汇总。
Map<String, File> resolveNodeCaches(
  CacheStore store,
  List<String> nodeIds, {
  String? explicitFile,
  String? fileKey,
  bool preferFullDepth = false,
  int? targetDepth,
}) {
  if (explicitFile != null) {
    final file = File(explicitFile);
    return {for (final id in nodeIds) id: file};
  }
  final files = _nodesCacheFiles(store).where((file) => _matchesFileKey(file, fileKey)).toList();
  if (files.isEmpty) {
    throw StateError('${store.dir.path} 里没有 nodes-*.json，先拉一次节点树缓存');
  }
  final index = _loadIndex(store, files);
  final ordered = _sortCacheFiles(files);
  final result = <String, File>{};
  for (final id in nodeIds) {
    // 策略由调用方决定：spec / tokens 默认 preferFullDepth=true（--allow-depth 时取最新），
    // diff 基线取最新；命中裁剪缓存时由调用方打印提示。
    final file = _pickNodesCache(
      ordered,
      index.entries,
      id,
      preferFullDepth: preferFullDepth,
      targetDepth: targetDepth,
    );
    if (file != null) result[id] = file;
  }
  final missing = nodeIds.where((id) => !result.containsKey(id)).toList();
  if (missing.isNotEmpty) {
    throw StateError(missingNodesMessage(missing, corruptFiles: index.corruptFiles));
  }
  return result;
}

/// 同一 nodeId 出现在多个 fileKey 的缓存时返回提示；没有冲突返回 null。
String? multiFileKeyWarning(CacheStore store, List<String> nodeIds) {
  final files = _nodesCacheFiles(store);
  if (files.isEmpty) return null;
  final index = _loadIndex(store, files);
  for (final id in nodeIds) {
    final keys = <String>{};
    for (final file in files) {
      if (!(index.entries[file.path]?.ids.contains(id) ?? false)) continue;
      final key = cacheFileKey(file.path);
      if (key != null) keys.add(key);
    }
    if (keys.length > 1) {
      return '# 节点 $id 同时出现在多个 fileKey 的缓存（${keys.join(', ')}）；'
          '可能选错文件，建议加 --file= 指定缓存';
    }
  }
  return null;
}

/// 找包含 [nodeId] 的 nodes 缓存文件；找不到返回 null（不抛错）。
///
/// [preferFullDepth] 为 true 时优先取没有被 `--depth` 裁剪过的缓存；
/// 为 false 时按 mtime 新→旧取最新（diff 当前用 false，并会在 depth 基线时警告子节点可能缺失）。
File? findNodesCache(
  CacheStore store,
  String nodeId, {
  bool preferFullDepth = true,
  String? fileKey,
}) {
  final files = _nodesCacheFiles(store).where((file) => _matchesFileKey(file, fileKey)).toList();
  if (files.isEmpty) return null;
  final index = _loadIndex(store, files);
  return _pickNodesCache(_sortCacheFiles(files), index.entries, nodeId,
      preferFullDepth: preferFullDepth);
}

File? _pickNodesCache(
  List<File> ordered,
  Map<String, _IndexEntry> index,
  String nodeId, {
  required bool preferFullDepth,
  int? targetDepth,
}) {
  File? depthMatch;
  for (final file in ordered) {
    if (!(index[file.path]?.ids.contains(nodeId) ?? false)) continue;
    final depth = nodesCacheDepth(file.path);
    if (targetDepth != null) {
      if (depth == targetDepth) return file;
      continue;
    }
    if (!preferFullDepth) return file;
    if (depth == null) return file;
    depthMatch ??= file;
  }
  return targetDepth != null ? null : depthMatch;
}

bool _matchesFileKey(File file, String? fileKey) {
  if (fileKey == null || fileKey.isEmpty) return true;
  return file.uri.pathSegments.last.startsWith('nodes-$fileKey-');
}

/// 缓存文件名里的 `--depth` 后缀（`nodes-K-1-2-d2.json` → 2）；没有返回 null。
int? nodesCacheDepth(String path) {
  final name = path.replaceAll('\\', '/').split('/').last;
  final match = RegExp(r'-d(\d+)\.json$').firstMatch(name);
  return match == null ? null : int.tryParse(match.group(1)!);
}

/// 从一组缓存路径里挑出被 `--depth` 裁剪过的路径（去重，保持出现顺序）。
///
/// `spec` / `tokens` 需要完整子树；只剩裁剪缓存时仍可用，但要显式提示，
/// 避免把「子节点缺失」误判成设计稿为空。
List<String> depthLimitedCachePaths(Iterable<String> paths) {
  final seen = <String>{};
  return <String>[
    for (final path in paths)
      if (nodesCacheDepth(path) != null && seen.add(path)) path,
  ];
}

/// 从 `nodes-<fileKey>-...json` 解析 fileKey；不是标准缓存名时返回 null。
String? cacheFileKey(String path) {
  final name = path.replaceAll('\\', '/').split('/').last;
  return RegExp(r'^nodes-([^-]+)-').firstMatch(name)?.group(1);
}

/// 对每条 dN 来源，只找同一 fileKey 的完整缓存。
///
/// 同一 nodeId（尤其 `0:1`）可能同时存在于多个 Figma 文件；跨 fileKey 推荐完整缓存
/// 会把用户引到另一个文件，必须按 dN 文件名里的 fileKey 过滤。
List<String> fullCachePathsForDepth(
  CacheStore store,
  Iterable<String> depthPaths,
  Iterable<String> nodeIds,
) {
  final out = <String>{};
  for (final depth in depthPaths) {
    final key = cacheFileKey(depth);
    if (key == null) continue;
    out.addAll(fullNodesCachePaths(
      store,
      nodeIds,
      fileKey: key,
      excludePath: depth,
    ));
  }
  return out.toList();
}

/// 当前项目里包含目标 nodeId 的完整缓存（未带 `-dN` 后缀），用于裁剪缓存的提示。
///
/// 按索引过滤，避免把无关项目的完整缓存也列出来；按 mtime 新→旧排序。
List<String> fullNodesCachePaths(
  CacheStore store,
  Iterable<String> nodeIds, {
  String? fileKey,
  String? excludePath,
}) {
  final ids = nodeIds.toSet();
  if (ids.isEmpty) return const <String>[];
  final exclude = excludePath == null ? null : _canonicalPath(excludePath);
  final files = _nodesCacheFiles(store)
      .where((file) => _matchesFileKey(file, fileKey))
      .where((file) => nodesCacheDepth(file.path) == null)
      .where((file) => exclude == null || _canonicalPath(file.path) != exclude)
      .toList();
  if (files.isEmpty) return const <String>[];
  final index = _loadIndex(store, files);
  return <String>[
    for (final file in _sortCacheFiles(files))
      if (ids.any((id) => index.entries[file.path]?.ids.contains(id) ?? false)) file.path,
  ];
}

String _canonicalPath(String path) {
  try {
    return File(path).resolveSymbolicLinksSync();
  } on FileSystemException {
    return File(path).absolute.uri.normalizePath().toFilePath();
  }
}

/// 一个比选中完整缓存更新的 `-dN` 缓存（JSON `newerDepthAvailable` 的元素）。
class NewerDepthCache {
  const NewerDepthCache({
    required this.nodeId,
    required this.fullSource,
    required this.source,
    required this.depth,
    this.fileKey,
    this.version,
    this.lastModified,
  });

  final String nodeId;
  final String fullSource;
  final String source;
  final int depth;
  final String? fileKey;
  final String? version;
  final String? lastModified;

  Map<String, Object?> toJson() => <String, Object?>{
        'nodeId': nodeId,
        'source': source,
        'depth': depth,
        if (fileKey != null) 'fileKey': fileKey,
        if (version != null) 'version': version,
        if (lastModified != null) 'lastModified': lastModified,
      };
}

/// 完整缓存 vs `-dN` 的新旧判断结果。
class StaleDepthReport {
  const StaleDepthReport({required this.stale, required this.newer});

  const StaleDepthReport.none()
      : stale = false,
        newer = const <NewerDepthCache>[];

  final bool stale;
  final List<NewerDepthCache> newer;

  List<Map<String, Object?>> toJson() => <Map<String, Object?>>[
        for (final item in newer) item.toJson(),
      ];
}

/// 默认选中完整缓存、但同 id 存在更新的 `-dN` 缓存时的判断。
///
/// 优先比较缓存顶层 `version`（Figma 文件版本），再退 `lastModified`，最后才用
/// 文件 mtime。只看 mtime 会把「同一 version 的 dN 重写」误报成陈旧。
StaleDepthReport staleDepthReport(
  CacheStore store,
  Iterable<String> selectedSources,
  Iterable<String> nodeIds,
) {
  final selected = <File>[];
  for (final path in selectedSources) {
    final raw = File(path);
    final file = raw.isAbsolute ? raw : File('${store.root.path}/$path');
    if (nodesCacheDepth(file.path) == null && file.existsSync()) selected.add(file);
  }
  if (selected.isEmpty) return const StaleDepthReport.none();
  final depthFiles =
      _nodesCacheFiles(store).where((file) => nodesCacheDepth(file.path) != null).toList();
  if (depthFiles.isEmpty) return const StaleDepthReport.none();
  final index = _loadIndex(store, <File>[...selected, ...depthFiles]);
  final newer = <NewerDepthCache>[];
  final seen = <String>{};
  for (final full in selected) {
    final fullEntry = index.entries[full.path];
    if (fullEntry == null) continue;
    final fullKey = cacheFileKey(full.path);
    if (fullKey == null) continue;
    final candidates = depthFiles.where((file) => cacheFileKey(file.path) == fullKey).toList();
    if (candidates.isEmpty) continue;
    for (final id in nodeIds) {
      if (!fullEntry.ids.contains(id)) continue;
      for (final depth in candidates) {
        final depthEntry = index.entries[depth.path];
        if (depthEntry == null || !depthEntry.ids.contains(id)) continue;
        if (!_isNewerCache(full, fullEntry, depth, depthEntry)) continue;
        if (!seen.add('$id|${depth.path}')) continue;
        newer.add(NewerDepthCache(
          nodeId: id,
          fullSource: full.path,
          source: depth.path,
          depth: nodesCacheDepth(depth.path) ?? 0,
          fileKey: fullKey,
          version: depthEntry.version,
          lastModified: depthEntry.lastModified,
        ));
        break;
      }
    }
  }
  return StaleDepthReport(stale: newer.isNotEmpty, newer: newer);
}

bool _isNewerCache(File fullFile, _IndexEntry full, File depthFile, _IndexEntry depth) {
  final fullVersion = full.version;
  final depthVersion = depth.version;
  if (fullVersion != null && depthVersion != null) {
    final fullNumber = int.tryParse(fullVersion);
    final depthNumber = int.tryParse(depthVersion);
    if (fullNumber != null && depthNumber != null) return depthNumber > fullNumber;
    return depthVersion.compareTo(fullVersion) > 0;
  }
  final fullModified = full.lastModified;
  final depthModified = depth.lastModified;
  if (fullModified != null && depthModified != null) {
    final fullTime = DateTime.tryParse(fullModified);
    final depthTime = DateTime.tryParse(depthModified);
    if (fullTime != null && depthTime != null) return depthTime.isAfter(fullTime);
    return depthModified.compareTo(fullModified) > 0;
  }
  return depthFile.lastModifiedSync().isAfter(fullFile.lastModifiedSync());
}

String staleDepthMessage(StaleDepthReport report) {
  final item = report.newer.first;
  final reason = item.version != null
      ? 'dN version ${item.version} 更新'
      : (item.lastModified != null ? 'dN lastModified 更新' : 'dN 文件时间更晚');
  final shown = report.newer
      .take(3)
      .map((entry) => '${entry.fullSource} → ${entry.source}（depth=${entry.depth}）')
      .join('；');
  return '# 完整缓存可能陈旧：$shown；$reason；'
      '如需最新数据请 fetch --refresh，或加 --allow-depth（可能不完整）';
}

/// `spec` / `tokens` 命中裁剪缓存时的统一提示：给出可用的完整缓存路径。
String depthLimitedMessage(
  Iterable<String> depthPaths, {
  List<String> fullPaths = const <String>[],
  bool explicitFile = false,
}) {
  final buffer = StringBuffer(
    '# 数据源来自 --depth 裁剪缓存（${depthPaths.join(', ')}），子节点可能缺失',
  );
  if (fullPaths.isEmpty) {
    buffer.write(explicitFile
        ? '；未找到同一 fileKey 的完整缓存；可用 --file= 指定完整文件，或重新 fetch nodes'
        : '；未找到同一 fileKey 的完整缓存，可重新 fetch nodes');
  } else {
    final shown = fullPaths.take(3).toList();
    buffer.write('；可用完整缓存：${shown.join(', ')}');
    if (fullPaths.length > shown.length) buffer.write(' 等');
    buffer.write('（用 --file= 指定完整缓存）');
  }
  return buffer.toString();
}

/// 从一个 document 里收集 FRAME，按 id 合并进 [out]。
///
/// 行字段与 `frames --json` 一致（id / name / page / width / height / children / cacheFile），
/// 另带 `nested` 标记：`nested == false` 就是「默认只列顶层画板」的那批。
/// `all == false` 时不收嵌套画板（与 `frames` 默认行为一致）。
void collectFrames(
  Map document, {
  required bool all,
  int? maxDepth,
  required String cacheFile,
  String? fetchedAt,
  required Map<String, Map<String, Object?>> out,
}) {
  final type = '${document['type']}';
  if (_isFrameLike(type)) {
    // fetch nodes 只拿到一个 FRAME 时，没有 CANVAS 父节点，不能把画板名当页面名。
    _addFrame(document, cacheFile, out, '',
        pageId: null, nested: false, depth: 0, fetchedAt: fetchedAt);
    if (all) {
      _walkChildren(document, cacheFile, out, '',
          pageId: null, depth: 1, maxDepth: maxDepth, fetchedAt: fetchedAt);
    }
    return;
  }
  final page = '${document['name'] ?? ''}';
  final pageId = '${document['id'] ?? ''}';
  final children = document['children'];
  if (children is! List) return;
  for (final child in children) {
    if (child is! Map) continue;
    if (_isFrameLike('${child['type']}')) {
      _addFrame(child, cacheFile, out, page,
          pageId: pageId.isEmpty ? null : pageId, nested: false, depth: 0, fetchedAt: fetchedAt);
      if (all) {
        _walkChildren(child, cacheFile, out, page,
            pageId: pageId.isEmpty ? null : pageId,
            depth: 1,
            maxDepth: maxDepth,
            fetchedAt: fetchedAt);
      }
    } else if (all) {
      _walkChildren(child, cacheFile, out, page,
          pageId: pageId.isEmpty ? null : pageId,
          depth: 1,
          maxDepth: maxDepth,
          fetchedAt: fetchedAt);
    }
  }
}

void _walkChildren(
  Map node,
  String cacheFile,
  Map<String, Map<String, Object?>> out,
  String page, {
  required int depth,
  int? maxDepth,
  String? fetchedAt,
  String? pageId,
}) {
  if (maxDepth != null && depth > maxDepth) return;
  for (final child in (node['children'] as List?) ?? const []) {
    if (child is! Map) continue;
    if (_isFrameLike('${child['type']}')) {
      _addFrame(child, cacheFile, out, page,
          pageId: pageId, nested: depth > 0, depth: depth, fetchedAt: fetchedAt);
    }
    _walkChildren(child, cacheFile, out, page,
        depth: depth + 1, maxDepth: maxDepth, fetchedAt: fetchedAt, pageId: pageId);
  }
}

void _addFrame(
  Map node,
  String cacheFile,
  Map<String, Map<String, Object?>> out,
  String page, {
  required bool nested,
  required int depth,
  String? fetchedAt,
  String? pageId,
}) {
  final id = '${node['id'] ?? ''}';
  if (id.isEmpty) return;
  final bb = node['absoluteBoundingBox'];
  final children = node['children'];
  final next = <String, Object?>{
    'id': id,
    'type': '${node['type'] ?? ''}',
    'name': '${node['name'] ?? ''}',
    'page': page,
    'pageId': pageId,
    'width': bb is Map ? bb['width'] : null,
    'height': bb is Map ? bb['height'] : null,
    'children': children is List ? children.length : 0,
    'cacheFile': cacheFile,
    'nested': nested,
    'depth': depth,
    if (fetchedAt != null) 'fetchedAt': fetchedAt,
  };
  _mergeFrameRow(out, id, next);
}

bool _isFrameLike(String type) =>
    type == 'FRAME' || type == 'COMPONENT' || type == 'COMPONENT_SET' || type == 'SECTION';

/// 同一 id 出现多次时的合并规则：补空 page、留较大 children、顶层身份优先。
void _mergeFrameRow(Map<String, Map<String, Object?>> out, String id, Map<String, Object?> next) {
  final existing = out[id];
  if (existing == null) {
    out[id] = next;
    return;
  }
  if ('${existing['page']}'.isEmpty && '${next['page']}'.isNotEmpty) {
    existing['page'] = next['page'];
  }
  final nextChildren = next['children'] as int? ?? 0;
  if (nextChildren > (existing['children'] as int? ?? 0)) {
    existing['children'] = nextChildren;
  }
  if (existing['nested'] == true && next['nested'] != true) {
    existing['nested'] = false;
  }
  final nextPageId = next['pageId'];
  if (nextPageId is String &&
      nextPageId.isNotEmpty &&
      (existing['pageId'] == null || '${existing['pageId']}'.isEmpty)) {
    existing['pageId'] = nextPageId;
  }
  final nextDepth = next['depth'] as int? ?? 0;
  final existingDepth = existing['depth'] as int? ?? 0;
  if (nextDepth < existingDepth) existing['depth'] = nextDepth;
  final nextFetched = next['fetchedAt'];
  final existingFetched = existing['fetchedAt'];
  if (nextFetched is String &&
      (existingFetched is! String || nextFetched.compareTo(existingFetched) > 0)) {
    existing['fetchedAt'] = nextFetched;
  }
  // 同一节点同时出现在完整缓存和裁剪缓存时，完整（null）优先；否则取更小的 depth。
  final nextCacheDepth = next['cacheDepth'] as int?;
  final existingCacheDepth = existing['cacheDepth'] as int?;
  if (existingCacheDepth != null &&
      (nextCacheDepth == null || nextCacheDepth < existingCacheDepth)) {
    existing['cacheDepth'] = nextCacheDepth;
  }
}

/// 从索引产出 `frames` 的行；索引缺失 / 过期时重建并写回（只有 frames 维护索引）。
({List<Map<String, Object?>> rows, List<File> corrupt}) framesFromIndex(
  CacheStore store, {
  required bool all,
  int? maxDepth,
  required Directory root,
}) {
  final files = _nodesCacheFiles(store);
  if (files.isEmpty) {
    return (rows: const <Map<String, Object?>>[], corrupt: const <File>[]);
  }
  final index = _loadIndex(store, files);
  if (index.changed) _writeIndex(store, index.entries);
  final out = <String, Map<String, Object?>>{};
  for (final file in _sortCacheFiles(files)) {
    final entry = index.entries[file.path];
    if (entry == null) continue;
    final cacheFile = relativeToRoot(root, file);
    final fetchedAt = DateTime.fromMillisecondsSinceEpoch(entry.mtime).toIso8601String();
    for (final row in entry.frames) {
      final id = '${row['id'] ?? ''}';
      if (id.isEmpty) continue;
      _mergeFrameRow(
        out,
        id,
        <String, Object?>{
          ...row,
          'cacheFile': cacheFile,
          'cacheDepth': nodesCacheDepth(file.path),
          'fetchedAt': fetchedAt,
        },
      );
    }
  }
  return (
    rows: <Map<String, Object?>>[
      for (final row in out.values)
        if ((all || row['nested'] != true) &&
            (maxDepth == null || (row['depth'] as int? ?? 0) <= maxDepth))
          row,
    ],
    corrupt: index.corruptFiles,
  );
}

/// 缓存文件相对 `--root` 的路径；不在 root 下时原样返回（缓存默认在 `~/.cache`）。
String relativeToRoot(Directory root, File file) {
  final prefix = '${root.path}/';
  return file.path.startsWith(prefix) ? file.path.substring(prefix.length) : file.path;
}

class _IndexEntry {
  _IndexEntry({
    required this.mtime,
    required this.size,
    required this.ids,
    required this.frames,
    required this.corrupt,
    this.version,
    this.lastModified,
  });

  final int mtime;
  final int size;
  final Set<String> ids;

  /// 该缓存文件里的 FRAME 摘要（顶层 + 嵌套），见 [collectFrames]。
  final List<Map<String, Object?>> frames;

  /// 缓存顶层 `version`；缺失时为 null。
  final String? version;

  /// 缓存顶层 `lastModified`；缺失时为 null。
  final String? lastModified;

  /// 解析失败（截断 / 手改坏）：保留条目，报错时才能点名是哪个文件。
  final bool corrupt;
}

/// `_nodes-index.json` 的格式版本；不匹配就整份丢弃重建（不做兼容迁移）。
const int _indexVersion = 9;

/// 一次索引读取的结果：条目 + 解析失败的缓存文件 + 是否需要写回。
class _NodesIndex {
  _NodesIndex(this.entries, this.corruptFiles, this.changed);

  final Map<String, _IndexEntry> entries;
  final List<File> corruptFiles;
  final bool changed;
}

_NodesIndex _loadIndex(CacheStore store, List<File> files) {
  final indexFile = File('${store.dir.path}/_nodes-index.json');
  final raw = indexFile.existsSync() ? _tryReadJson(indexFile) : null;
  final version = raw is Map ? raw['version'] : null;
  final stored = (raw is Map && version == _indexVersion && raw['files'] is Map)
      ? raw['files'] as Map
      : const {};
  final entries = <String, _IndexEntry>{};
  final corruptFiles = <File>[];
  var changed = version != _indexVersion;
  for (final file in files) {
    final stat = file.statSync();
    final cached = stored[file.path];
    if (cached is Map &&
        cached['mtime'] == stat.modified.millisecondsSinceEpoch &&
        cached['size'] == stat.size &&
        cached['ids'] is List &&
        cached['frames'] is List &&
        cached['corrupt'] is bool) {
      final corrupt = cached['corrupt'] as bool;
      entries[file.path] = _IndexEntry(
        mtime: stat.modified.millisecondsSinceEpoch,
        size: stat.size,
        ids: (cached['ids'] as List).map((e) => '$e').toSet(),
        frames: <Map<String, Object?>>[
          for (final frame in cached['frames'] as List)
            if (frame is Map) Map<String, Object?>.from(frame),
        ],
        version: cached['version'] is String ? cached['version'] as String : null,
        lastModified: cached['lastModified'] is String ? cached['lastModified'] as String : null,
        corrupt: corrupt,
      );
      if (corrupt) corruptFiles.add(file);
      continue;
    }
    final ids = <String>{};
    final frames = <String, Map<String, Object?>>{};
    var corrupt = false;
    String? version;
    String? lastModified;
    try {
      final content = readCacheFile(file);
      version = content.version;
      lastModified = content.lastModified;
      for (final entry in content.documents.entries) {
        ids.add(entry.key);
        _collectIds(entry.value, ids);
        // cacheFile 在读索引时按 `--root` 算，存的时候留空。
        collectFrames(
          entry.value,
          all: true,
          maxDepth: null,
          cacheFile: '',
          out: frames,
        );
      }
    } on FormatException {
      corrupt = true;
    } on StateError {
      corrupt = true;
    }
    entries[file.path] = _IndexEntry(
      mtime: stat.modified.millisecondsSinceEpoch,
      size: stat.size,
      ids: ids,
      frames: frames.values.toList(),
      version: version,
      lastModified: lastModified,
      corrupt: corrupt,
    );
    if (corrupt) corruptFiles.add(file);
    changed = true;
  }
  return _NodesIndex(entries, corruptFiles, changed || !indexFile.existsSync());
}

/// 只有会更新索引的命令（frames）才写盘；spec / tokens 只读。
void _writeIndex(CacheStore store, Map<String, _IndexEntry> entries) {
  final indexFile = File('${store.dir.path}/_nodes-index.json');
  try {
    indexFile.writeAsStringSync(jsonEncode({
      'version': _indexVersion,
      'files': {
        for (final entry in entries.entries)
          entry.key: {
            'mtime': entry.value.mtime,
            'size': entry.value.size,
            'ids': entry.value.ids.toList(),
            'frames': entry.value.frames,
            'version': entry.value.version,
            'lastModified': entry.value.lastModified,
            'corrupt': entry.value.corrupt,
          },
      },
    }));
  } on FileSystemException {
    // 只读缓存目录下仍允许 frames 工作。
  }
}

/// "找不到节点"的统一文案；有解析失败的缓存时要点名，别让人先去怀疑 nodeId。
String missingNodesMessage(List<String> missing, {List<File> corruptFiles = const []}) {
  final buffer = StringBuffer('在缓存里找不到节点：${missing.join(', ')}');
  if (corruptFiles.isEmpty) {
    buffer.write(
      '；先运行 `figma frames --verbose` 查看，或 `figma fetch nodes <fileKey> <nodeId>` 拉取'
      '（fileKey 可用 `figma url <链接> --json` 解析）',
    );
    return buffer.toString();
  }
  final paths = corruptFiles.map((file) => file.path).join(', ');
  buffer.write('；另有 ${corruptFiles.length} 个缓存文件解析失败（$paths）');
  buffer.write('——跑 `figma cache clean` 或重新 fetch 后再试');
  return buffer.toString();
}

dynamic _tryReadJson(File file) {
  try {
    return jsonDecode(file.readAsStringSync());
  } on FormatException {
    return null;
  } on FileSystemException {
    return null;
  }
}

void _collectIds(Map node, Set<String> ids) {
  final id = '${node['id'] ?? ''}';
  if (id.isNotEmpty) ids.add(id);
  for (final child in (node['children'] as List?) ?? const []) {
    if (child is Map) _collectIds(child, ids);
  }
}

List<File> nodesCacheFiles(CacheStore store) => _nodesCacheFiles(store);

List<File> _nodesCacheFiles(CacheStore store) {
  final dir = store.dir;
  if (!dir.existsSync()) return const <File>[];
  return dir.listSync().whereType<File>().where((f) => isNodesCacheFile(f.path)).toList();
}

/// 是否是 nodes 缓存文件。
///
/// 先把 `\\` 归一化成 `/` 再取文件名：Windows 路径是 `C:\\...`，只按 `/` 切分会得到
/// 整条路径，导致 `spec` / `tokens` / `frames` 在 Windows 上找不到缓存。
bool isNodesCacheFile(String path) {
  final name = path.replaceAll('\\', '/').split('/').last;
  return name.startsWith('nodes-') && name.endsWith('.json');
}

List<File> _sortCacheFiles(List<File> files) {
  final sorted = List<File>.from(files);
  sorted.sort((a, b) {
    final am = a.lastModifiedSync();
    final bm = b.lastModifiedSync();
    final byTime = bm.compareTo(am);
    if (byTime != 0) return byTime;
    return b.lengthSync().compareTo(a.lengthSync());
  });
  return sorted;
}
