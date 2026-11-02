import 'dart:convert';
import 'dart:io';

import 'figma_node.dart';

/// 读取 nodes 缓存里的全部 document。
///
/// `fetch nodes` 支持批量 ids，所以不能只看 `nodes.values.first`。
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

/// 按 node id 找 document；支持节点 id 作为顶层 key，或嵌套在某个 document 里。
Map<String, dynamic>? readDocument(File file, String nodeId) {
  final documents = readDocuments(file);
  return documents[nodeId] ??
      documents.values.where((d) => findFigmaNode(d, nodeId) != null).firstOrNull;
}
