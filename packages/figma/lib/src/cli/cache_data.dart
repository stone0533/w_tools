import 'dart:io';

import '../cache/cache_store.dart';
import '../spec/cache_document.dart';
import '../spec/figma_node.dart';
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

/// 选择包含这些 nodeId 的缓存；优先内容匹配，再按 mtime / 大小。
File resolveNodesCache(
  Directory root,
  List<String> nodeIds, {
  String? explicitFile,
}) {
  if (explicitFile != null) return File(explicitFile);
  final files = _nodesCacheFiles(root);
  if (files.isEmpty) {
    throw StateError('${root.path}/.figma-cache 里没有 nodes-*.json，先拉一次节点树缓存');
  }

  final found = <String, List<File>>{};
  for (final file in _sortCacheFiles(files)) {
    Map<String, Map<String, dynamic>> documents;
    try {
      documents = readDocuments(file);
    } on FormatException {
      continue;
    } on StateError {
      continue;
    }
    final missing = <String>[];
    for (final id in nodeIds) {
      final document =
          documents[id] ?? documents.values.where((d) => findFigmaNode(d, id) != null).firstOrNull;
      if (document == null) {
        missing.add(id);
      } else {
        found.putIfAbsent(id, () => <File>[]).add(file);
      }
    }
    if (missing.isEmpty) return file;
  }

  final hints = <String>[];
  for (final id in nodeIds) {
    final files = found[id] ?? const <File>[];
    if (files.isEmpty) continue;
    final names = files.map((f) => _relative(root, f)).join(', ');
    hints.add('$id 在 $names');
  }
  final detail = hints.isEmpty ? '' : '；${hints.join('；')}';
  throw StateError(
    '节点 ${nodeIds.join(', ')} 不在默认缓存里$detail。'
    '加 --file=<缓存文件> 指定，或先运行 `figma frames --verbose` 查看',
  );
}

/// 每个 nodeId 对应的缓存文件；用于 tokens 跨缓存汇总。
Map<String, File> resolveNodeCaches(
  Directory root,
  List<String> nodeIds, {
  String? explicitFile,
}) {
  if (explicitFile != null) {
    final file = File(explicitFile);
    return {for (final id in nodeIds) id: file};
  }
  final files = _nodesCacheFiles(root);
  if (files.isEmpty) {
    throw StateError('${root.path}/.figma-cache 里没有 nodes-*.json，先拉一次节点树缓存');
  }
  final result = <String, File>{};
  for (final file in _sortCacheFiles(files)) {
    Map<String, Map<String, dynamic>> documents;
    try {
      documents = readDocuments(file);
    } on FormatException {
      continue;
    } on StateError {
      continue;
    }
    for (final id in nodeIds) {
      if (result.containsKey(id)) continue;
      final document =
          documents[id] ?? documents.values.where((d) => findFigmaNode(d, id) != null).firstOrNull;
      if (document != null) result[id] = file;
    }
    if (result.length == nodeIds.length) break;
  }
  final missing = nodeIds.where((id) => !result.containsKey(id)).toList();
  if (missing.isNotEmpty) {
    throw StateError('在缓存里找不到节点：${missing.join(', ')}；先运行 `figma frames --verbose` 查看');
  }
  return result;
}

List<File> _nodesCacheFiles(Directory root) {
  final dir = Directory('${root.path}/.figma-cache');
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

String _relative(Directory root, File file) {
  final prefix = '${root.path}/';
  return file.path.startsWith(prefix) ? file.path.substring(prefix.length) : file.path;
}

/// 当前 .figma-cache 下的全部 nodes 缓存文件。
List<File> nodesCacheFiles(CacheStore store) {
  if (!store.dir.existsSync()) return const <File>[];
  return store.dir.listSync().whereType<File>().where((f) {
    final name = f.path.split('/').last;
    return name.startsWith('nodes-') && name.endsWith('.json');
  }).toList();
}
