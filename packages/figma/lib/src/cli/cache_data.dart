import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import 'cli_io.dart';

String readToken(CacheStore store) {
  final file = store.tokenFile;
  if (!file.existsSync()) {
    throw FigmaTokenException('缺少 ${file.path}，先跑 init 并填入 figd_ 令牌');
  }
  final token = file.readAsStringSync().trim();
  if (token.isEmpty || token.contains('REPLACE_ME')) {
    throw FigmaTokenException('${file.path} 里还是模板内容，请填入真实的 figd_ 令牌');
  }
  if (!token.startsWith('figd_')) {
    throw FigmaTokenException('${file.path} 里的 token 需要 figd_ 开头');
  }
  return token;
}

File pickLargestCache(Directory root) {
  final dir = Directory('${root.path}/.figma-cache');
  if (!dir.existsSync()) {
    throw StateError('找不到 ${dir.path}，先拉一次节点树缓存');
  }
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.split('/').last.startsWith('nodes-') && f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => b.lengthSync().compareTo(a.lengthSync()));
  if (files.isEmpty) {
    throw StateError('${dir.path} 里没有 nodes-*.json，先拉一次节点树缓存');
  }
  return files.first;
}

Map<String, Map<String, dynamic>> readDocuments(File file) {
  final raw = jsonDecode(file.readAsStringSync());
  final nodes = (raw is Map) ? raw['nodes'] : null;
  if (nodes is! Map || nodes.isEmpty) {
    throw StateError('${file.path} 不是 nodes 缓存（缺少 nodes 字段）');
  }
  final documents = <String, Map<String, dynamic>>{};
  for (final entry in nodes.entries) {
    final value = entry.value;
    if (value is! Map) continue;
    final document = value['document'];
    if (document is Map) {
      documents['${entry.key}'] = document.cast<String, dynamic>();
    }
  }
  if (documents.isEmpty) {
    throw StateError('${file.path} 缺少 document');
  }
  return documents;
}
