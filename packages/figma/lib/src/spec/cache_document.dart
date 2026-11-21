import 'dart:convert';
import 'dart:io';

import 'figma_node.dart';

/// 一个 nodes 缓存的 document 与顶层元数据（`version` / `lastModified`）。
class CacheContent {
  CacheContent({
    required this.documents,
    this.version,
    this.lastModified,
  });

  final Map<String, Map<String, dynamic>> documents;

  /// Figma 文件版本；缺失时为 null。
  final String? version;

  /// Figma 文件的 lastModified（ISO 字符串）；缺失时为 null。
  final String? lastModified;
}

/// 读取 nodes 缓存的 document + 顶层元数据。
///
/// `version` 是判断「完整缓存 vs dN 谁更新」的首选事实；文件 mtime 只是最后兜底。
/// 缓存被截断 / 手改坏时抛 [StateError]（退出码 1），不要让它变成 CLI 的“参数错误”。
CacheContent readCacheFile(File file) {
  final Object? raw;
  try {
    raw = jsonDecode(file.readAsStringSync());
  } on FormatException catch (e) {
    throw StateError(
      '缓存文件损坏：${file.path}（${e.message}）；跑 `figma cache clean` 或重新 fetch 后再试',
    );
  }
  final nodes = (raw is Map) ? raw['nodes'] : null;
  if (nodes is! Map || nodes.isEmpty) {
    throw StateError('${file.path} 不是 nodes 缓存（缺少 nodes 字段）');
  }
  final documents = <String, Map<String, dynamic>>{};
  var sawNodeObject = false;
  for (final entry in nodes.entries) {
    final value = entry.value;
    if (value is! Map) continue;
    sawNodeObject = true;
    final document = value['document'];
    if (document is Map) {
      documents['${entry.key}'] = document.cast<String, dynamic>();
    }
  }
  final version = raw is Map ? raw['version'] : null;
  final lastModified = raw is Map ? raw['lastModified'] : null;
  if (documents.isEmpty) {
    // 全 null（节点不存在）是合法的空缓存，不是“解析失败”。
    if (!sawNodeObject) {
      return CacheContent(
        documents: const <String, Map<String, dynamic>>{},
        version: version is String ? version : (version?.toString()),
        lastModified: lastModified is String ? lastModified : (lastModified?.toString()),
      );
    }
    throw StateError('${file.path} 缺少 document');
  }
  return CacheContent(
    documents: documents,
    version: version is String ? version : (version?.toString()),
    lastModified: lastModified is String ? lastModified : (lastModified?.toString()),
  );
}

/// 读取 nodes 缓存里的全部 document。
///
/// `fetch nodes` 支持批量 ids，所以不能只看 `nodes.values.first`。
Map<String, Map<String, dynamic>> readDocuments(File file) => readCacheFile(file).documents;

/// 按 node id 找 document；支持节点 id 作为顶层 key，或嵌套在某个 document 里。
Map<String, dynamic>? readDocument(File file, String nodeId) {
  final documents = readDocuments(file);
  return documents[nodeId] ??
      documents.values.where((d) => findFigmaNode(d, nodeId) != null).firstOrNull;
}
