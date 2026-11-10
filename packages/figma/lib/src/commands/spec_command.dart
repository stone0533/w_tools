import 'dart:io';

import '../cache/cache_store.dart';
import '../cache/nodes_index.dart';
import '../spec/cache_document.dart';
import '../spec/figma_node.dart';
import '../spec/spec_renderer.dart';

/// `spec` 的一个节点条目：结构化 node +（按需）markdown。
class SpecEntry {
  SpecEntry({
    required this.source,
    required this.nodeId,
    required this.node,
    this.markdown,
  });

  final String source;
  final String nodeId;
  final Map<String, dynamic> node;
  final String? markdown;
}

/// `spec` 的结果：条目 + 可直接打印的 markdown 列表。
class SpecResult {
  SpecResult(this.entries, this.markdowns);

  final List<SpecEntry> entries;
  final List<String> markdowns;
}

/// `spec` 的纯逻辑：定位缓存 → 取节点 → 按需裁剪 / 渲染。
///
/// 不做参数解析、不打印；`--node-only` 的取舍由调用方通过 [includeMarkdown] 决定。
class SpecCommand {
  SpecCommand(this.store, {this.renderer = const FigmaSpecRenderer()});

  final CacheStore store;
  final FigmaSpecRenderer renderer;

  SpecResult run({
    required List<String> nodeIds,
    String? file,
    int? nodeDepth,
    bool includeMarkdown = true,
  }) {
    final sources = resolveNodeCaches(store, nodeIds, explicitFile: file);
    final documents = <File, Map<String, Map<String, dynamic>>>{};
    final entries = <SpecEntry>[];
    final markdowns = <String>[];
    final missing = <String>[];

    for (final nodeId in nodeIds) {
      final source = sources[nodeId]!;
      final docs = documents.putIfAbsent(source, () => readDocuments(source));
      final document =
          docs[nodeId] ?? docs.values.where((d) => findFigmaNode(d, nodeId) != null).firstOrNull;
      if (document == null) {
        missing.add(nodeId);
        continue;
      }
      final rawNode = findFigmaNode(document, nodeId)!;
      final node = nodeDepth == null ? rawNode : trimNode(rawNode, nodeDepth);
      final markdown = includeMarkdown ? renderer.renderMarkdownFromRoot(document, nodeId) : null;
      if (markdown != null) markdowns.add(markdown);
      entries.add(SpecEntry(
        source: source.path,
        nodeId: nodeId,
        node: Map<String, dynamic>.from(node),
        markdown: markdown,
      ));
    }
    if (missing.isNotEmpty) {
      throw StateError(missingNodesMessage(missing));
    }
    return SpecResult(entries, markdowns);
  }
}

/// 限制 JSON 里的原始节点深度；0 表示只保留当前节点，不带 children。
Map<String, dynamic> trimNode(Map node, int depth) {
  final copy = Map<String, dynamic>.from(node);
  if (depth <= 0) {
    copy.remove('children');
    return copy;
  }
  final children = node['children'];
  if (children is List) {
    copy['children'] = <Object?>[
      for (final child in children)
        if (child is Map) trimNode(child, depth - 1) else child,
    ];
  }
  return copy;
}
