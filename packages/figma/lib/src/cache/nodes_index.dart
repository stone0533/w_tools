import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import '../spec/cache_document.dart';

/// 每个 nodeId 对应的缓存文件；用于 tokens / spec 跨缓存汇总。
Map<String, File> resolveNodeCaches(
  CacheStore store,
  List<String> nodeIds, {
  String? explicitFile,
}) {
  if (explicitFile != null) {
    final file = File(explicitFile);
    return {for (final id in nodeIds) id: file};
  }
  final files = _nodesCacheFiles(store);
  if (files.isEmpty) {
    throw StateError('${store.dir.path} 里没有 nodes-*.json，先拉一次节点树缓存');
  }
  final index = _loadIndex(store, files);
  final ordered = _sortCacheFiles(files);
  final result = <String, File>{};
  for (final id in nodeIds) {
    // spec / tokens 需要完整子树：同 id 命中多个缓存时优先未裁剪的那份；
    // 只有 --depth 缓存时才退回它，由调用方打印提示。
    final file = _pickNodesCache(ordered, index.entries, id, preferFullDepth: true);
    if (file != null) result[id] = file;
  }
  final missing = nodeIds.where((id) => !result.containsKey(id)).toList();
  if (missing.isNotEmpty) {
    throw StateError(missingNodesMessage(missing, corruptFiles: index.corruptFiles));
  }
  return result;
}

/// 找包含 [nodeId] 的 nodes 缓存文件；找不到返回 null（不抛错）。
///
/// [preferFullDepth] 为 true 时优先取没有被 `--depth` 裁剪过的缓存（diff 的基线需要完整树）；
/// 只有 depth 版缓存时才退回它。同级按 mtime 新→旧。
File? findNodesCache(
  CacheStore store,
  String nodeId, {
  bool preferFullDepth = true,
}) {
  final files = _nodesCacheFiles(store);
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
}) {
  File? depthMatch;
  for (final file in ordered) {
    if (!(index[file.path]?.ids.contains(nodeId) ?? false)) continue;
    if (!preferFullDepth) return file;
    if (nodesCacheDepth(file.path) == null) return file;
    depthMatch ??= file;
  }
  return depthMatch;
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

/// 从一个 document 里收集 FRAME，按 id 合并进 [out]。
///
/// 行字段与 `frames --json` 一致（id / name / page / width / height / children / cacheFile），
/// 另带 `nested` 标记：`nested == false` 就是「默认只列顶层画板」的那批。
/// `all == false` 时不收嵌套画板（与 `frames` 默认行为一致）。
void collectFrames(
  Map document, {
  required bool all,
  required String cacheFile,
  required Map<String, Map<String, Object?>> out,
}) {
  final type = '${document['type']}';
  if (type == 'FRAME') {
    // fetch nodes 只拿到一个 FRAME 时，没有 CANVAS 父节点，不能把画板名当页面名。
    _addFrame(document, cacheFile, out, '', nested: false);
    if (all) _walkChildren(document, cacheFile, out, '', nested: true);
    return;
  }
  final page = '${document['name'] ?? ''}';
  final children = document['children'];
  if (children is! List) return;
  for (final child in children) {
    if (child is! Map) continue;
    if ('${child['type']}' == 'FRAME') {
      _addFrame(child, cacheFile, out, page, nested: false);
      if (all) _walkChildren(child, cacheFile, out, page, nested: true);
    } else if (all) {
      _walkChildren(child, cacheFile, out, page, nested: true);
    }
  }
}

void _walkChildren(
  Map node,
  String cacheFile,
  Map<String, Map<String, Object?>> out,
  String page, {
  required bool nested,
}) {
  for (final child in (node['children'] as List?) ?? const []) {
    if (child is! Map) continue;
    if ('${child['type']}' == 'FRAME') {
      _addFrame(child, cacheFile, out, page, nested: nested);
    }
    _walkChildren(child, cacheFile, out, page, nested: nested);
  }
}

void _addFrame(
  Map node,
  String cacheFile,
  Map<String, Map<String, Object?>> out,
  String page, {
  required bool nested,
}) {
  final id = '${node['id'] ?? ''}';
  if (id.isEmpty) return;
  final bb = node['absoluteBoundingBox'];
  final children = node['children'];
  final next = <String, Object?>{
    'id': id,
    'name': '${node['name'] ?? ''}',
    'page': page,
    'width': bb is Map ? bb['width'] : null,
    'height': bb is Map ? bb['height'] : null,
    'children': children is List ? children.length : 0,
    'cacheFile': cacheFile,
    'nested': nested,
  };
  _mergeFrameRow(out, id, next);
}

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
}

/// 只用 `_nodes-index.json` 产出 `frames` 的行，不读缓存文件内容。
List<Map<String, Object?>> framesFromIndex(
  CacheStore store, {
  required bool all,
  required Directory root,
}) {
  final files = _nodesCacheFiles(store);
  if (files.isEmpty) return const <Map<String, Object?>>[];
  final index = _loadIndex(store, files);
  final out = <String, Map<String, Object?>>{};
  for (final file in _sortCacheFiles(files)) {
    final entry = index.entries[file.path];
    if (entry == null) continue;
    final cacheFile = relativeToRoot(root, file);
    for (final row in entry.frames) {
      final id = '${row['id'] ?? ''}';
      if (id.isEmpty) continue;
      _mergeFrameRow(out, id, <String, Object?>{...row, 'cacheFile': cacheFile});
    }
  }
  return <Map<String, Object?>>[
    for (final row in out.values)
      if (all || row['nested'] != true) row,
  ];
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
  });

  final int mtime;
  final int size;
  final Set<String> ids;

  /// 该缓存文件里的 FRAME 摘要（顶层 + 嵌套），见 [collectFrames]。
  final List<Map<String, Object?>> frames;

  /// 解析失败（截断 / 手改坏）：保留条目，报错时才能点名是哪个文件。
  final bool corrupt;
}

/// `_nodes-index.json` 的格式版本；不匹配就整份丢弃重建（不做兼容迁移）。
const int _indexVersion = 3;

/// 一次索引读取的结果：条目 + 解析失败的缓存文件。
class _NodesIndex {
  _NodesIndex(this.entries, this.corruptFiles);

  final Map<String, _IndexEntry> entries;
  final List<File> corruptFiles;
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
        corrupt: corrupt,
      );
      if (corrupt) corruptFiles.add(file);
      continue;
    }
    final ids = <String>{};
    final frames = <String, Map<String, Object?>>{};
    var corrupt = false;
    try {
      final documents = readDocuments(file);
      for (final entry in documents.entries) {
        ids.add(entry.key);
        _collectIds(entry.value, ids);
        // cacheFile 在读索引时按 `--root` 算，存的时候留空。
        collectFrames(entry.value, all: true, cacheFile: '', out: frames);
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
      corrupt: corrupt,
    );
    if (corrupt) corruptFiles.add(file);
    changed = true;
  }
  if (changed || !indexFile.existsSync()) {
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
              'corrupt': entry.value.corrupt,
            },
        },
      }));
    } on FileSystemException {
      // 只读缓存目录下仍允许 spec / tokens 工作。
    }
  }
  return _NodesIndex(entries, corruptFiles);
}

/// "找不到节点"的统一文案；有解析失败的缓存时要点名，别让人先去怀疑 nodeId。
String missingNodesMessage(List<String> missing, {List<File> corruptFiles = const []}) {
  final buffer = StringBuffer('在缓存里找不到节点：${missing.join(', ')}');
  if (corruptFiles.isEmpty) {
    buffer.write('；先运行 `figma frames --verbose` 查看');
    return buffer.toString();
  }
  final paths = corruptFiles.map((file) => file.path).join(', ');
  buffer.write('；另有 ${corruptFiles.length} 个缓存文件解析失败（$paths）');
  buffer.write('——跑 `figma cache clean` 或重新 fetch 后再试');
  return buffer.toString();
}

/// 索引里记录的、解析失败的缓存文件（给"跳过但要说一声"的调用方用）。
List<File> corruptCacheFiles(CacheStore store) {
  final files = _nodesCacheFiles(store);
  if (files.isEmpty) return const <File>[];
  return _loadIndex(store, files).corruptFiles;
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
