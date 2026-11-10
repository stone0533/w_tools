import 'dart:io';

import '../cache/cache_store.dart';
import '../cache/nodes_index.dart';
import '../spec/cache_document.dart';
import '../spec/figma_node.dart';
import '../tokens/token_collector.dart';
import '../tokens/token_renderer.dart';

/// `tokens` 的结果：四类统计 + 数据源 + 可直接打印的 markdown。
class TokensReport {
  TokensReport({
    required this.colors,
    required this.texts,
    required this.radii,
    required this.spacings,
    required this.sources,
    required this.nodeIds,
    required this.markdown,
  });

  final List<ColorUsage> colors;
  final List<TextStyleUsage> texts;
  final List<NumberUsage> radii;
  final List<NumberUsage> spacings;
  final List<String> sources;
  final List<String> nodeIds;
  final String markdown;
}

/// `tokens` 的纯逻辑：定位缓存 → 汇总 → 渲染。
///
/// 语义名映射（`--map` 的 YAML）由调用方解析后作为 [colorNames] 传进来。
class TokensCommand {
  TokensCommand(this.store, {this.renderer = const TokenRenderer()});

  final CacheStore store;
  final TokenRenderer renderer;

  TokensReport run({
    required List<String> nodeIds,
    String? file,
    int min = 1,
    Map<String, String> colorNames = const <String, String>{},
  }) {
    final sources = resolveNodeCaches(store, nodeIds, explicitFile: file);
    final documents = <File, Map<String, dynamic>>{};
    final collector = TokenCollector(minCount: min);

    for (final id in nodeIds) {
      final cache = sources[id]!;
      final docs = documents.putIfAbsent(cache, () => readDocuments(cache));
      final document =
          docs[id] ?? docs.values.where((d) => findFigmaNode(d, id) != null).firstOrNull;
      final node = document == null ? null : findFigmaNode(document, id);
      if (node == null) {
        throw StateError(missingNodesMessage(<String>[id]));
      }
      collector.collect(node);
    }

    final sourceFiles = sources.values.map((cache) => cache.path).toSet().toList();
    final markdown = renderer.renderMarkdown(
      tokens: collector,
      source: sourceFiles.join(', '),
      nodeIds: nodeIds,
      colorNames: colorNames,
    );
    return TokensReport(
      colors: collector.colorsSorted(),
      texts: collector.textsSorted(),
      radii: collector.radiiSorted(),
      spacings: collector.spacingsSorted(),
      sources: sourceFiles,
      nodeIds: nodeIds,
      markdown: markdown,
    );
  }
}
