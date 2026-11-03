import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import '../spec/cache_document.dart';
import 'cli_io.dart';

export '../spec/cache_document.dart' show readDocument, readDocuments;

String readToken(CacheStore store, {String? envToken}) {
  // CI / agent 优先用环境变量，避免把 token 写进项目目录。
  final fromEnv = (envToken ?? Platform.environment['FIGMA_TOKEN'] ?? '').trim();
  if (fromEnv.isNotEmpty) {
    return _validateToken(fromEnv, 'FIGMA_TOKEN');
  }

  final file = store.tokenFile;
  if (!file.existsSync()) {
    throw FigmaTokenException('缺少 ${file.path} 或 FIGMA_TOKEN，先跑 init 并填入 figd_ 令牌');
  }
  final token = file.readAsStringSync().trim();
  if (token.isEmpty || token.contains('REPLACE_ME')) {
    throw FigmaTokenException('${file.path} 里还是模板内容，请填入真实的 figd_ 令牌');
  }
  return _validateToken(token, file.path);
}

String _validateToken(String token, String source) {
  if (token.contains('REPLACE_ME') || token.isEmpty) {
    throw FigmaTokenException('$source 里还是模板内容，请填入真实的 figd_ 令牌');
  }
  if (!token.startsWith('figd_')) {
    throw FigmaTokenException('$source 里的 token 需要 figd_ 开头');
  }
  return token;
}

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
  final result = <String, File>{};
  for (final file in _sortCacheFiles(files)) {
    final ids = index[file.path]?.ids ?? const <String>{};
    for (final id in nodeIds) {
      if (result.containsKey(id)) continue;
      if (ids.contains(id)) result[id] = file;
    }
    if (result.length == nodeIds.length) break;
  }
  final missing = nodeIds.where((id) => !result.containsKey(id)).toList();
  if (missing.isNotEmpty) {
    throw StateError('在缓存里找不到节点：${missing.join(', ')}；先运行 `figma frames --verbose` 查看');
  }
  return result;
}

class _IndexEntry {
  _IndexEntry({required this.mtime, required this.size, required this.ids});

  final int mtime;
  final int size;
  final Set<String> ids;
}

Map<String, _IndexEntry> _loadIndex(CacheStore store, List<File> files) {
  final indexFile = File('${store.dir.path}/_nodes-index.json');
  final raw = indexFile.existsSync() ? _tryReadJson(indexFile) : null;
  final stored = raw is Map && raw['files'] is Map ? raw['files'] as Map : const {};
  final out = <String, _IndexEntry>{};
  var changed = false;
  for (final file in files) {
    final stat = file.statSync();
    final cached = stored[file.path];
    if (cached is Map &&
        cached['mtime'] == stat.modified.millisecondsSinceEpoch &&
        cached['size'] == stat.size &&
        cached['ids'] is List) {
      out[file.path] = _IndexEntry(
        mtime: stat.modified.millisecondsSinceEpoch,
        size: stat.size,
        ids: (cached['ids'] as List).map((e) => '$e').toSet(),
      );
      continue;
    }
    final ids = <String>{};
    try {
      final documents = readDocuments(file);
      for (final entry in documents.entries) {
        ids.add(entry.key);
        _collectIds(entry.value, ids);
      }
    } on FormatException {
      // 损坏缓存保留空索引，后续 resolver 会跳过。
    } on StateError {
      // 同上。
    }
    out[file.path] = _IndexEntry(
      mtime: stat.modified.millisecondsSinceEpoch,
      size: stat.size,
      ids: ids,
    );
    changed = true;
  }
  if (changed || !indexFile.existsSync()) {
    try {
      indexFile.writeAsStringSync(jsonEncode({
        'version': 1,
        'files': {
          for (final entry in out.entries)
            entry.key: {
              'mtime': entry.value.mtime,
              'size': entry.value.size,
              'ids': entry.value.ids.toList(),
            },
        },
      }));
    } on FileSystemException {
      // 只读缓存目录下仍允许 spec / tokens 工作。
    }
  }
  return out;
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
  return dir.listSync().whereType<File>().where((f) {
    final name = f.path.split('/').last;
    return name.startsWith('nodes-') && name.endsWith('.json');
  }).toList();
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
