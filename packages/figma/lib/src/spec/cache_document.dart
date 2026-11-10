import 'dart:convert';
import 'dart:io';

import 'figma_node.dart';

/// 读取 nodes 缓存里的全部 document。
///
/// `fetch nodes` 支持批量 ids，所以不能只看 `nodes.values.first`。
/// 缓存被截断 / 手改坏时抛 [StateError]（退出码 1），不要让它变成 CLI 的“参数错误”。
Map<String, Map<String, dynamic>> readDocuments(File file) {
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

/// 按 node id 找 document；支持节点 id 作为顶层 key，或嵌套在某个 document 里。
Map<String, dynamic>? readDocument(File file, String nodeId) {
  final documents = readDocuments(file);
  return documents[nodeId] ??
      documents.values.where((d) => findFigmaNode(d, nodeId) != null).firstOrNull;
}
