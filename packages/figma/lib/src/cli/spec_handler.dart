import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import '../cache/nodes_index.dart';
import '../spec/cache_document.dart';
import '../spec/figma_node.dart';
import '../spec/spec_renderer.dart';
import 'args.dart';
import 'cli_io.dart';

Future<void> runSpec(
  List<String> args, {
  FigmaSpecRenderer renderer = const FigmaSpecRenderer(),
  CacheStore? store,
}) async {
  final options = parseCommand(args, 'spec');
  rejectExtra(options, 1);

  if (options.nodeOnly && !options.json) {
    throw const FormatException('--node-only 只与 --json 一起使用');
  }

  final rawIds = options.positional.isEmpty ? null : options.positional.first;
  if (rawIds == null) {
    stderr.writeln('spec 需要 nodeId，例如：spec 1862:9222');
    exitCode = 2;
    return;
  }
  final nodeIds = parseNodeIds(rawIds);
  if (nodeIds.isEmpty) {
    stderr.writeln('spec 需要 nodeId，例如：spec 1862:9222');
    exitCode = 2;
    return;
  }

  // `--node-only` 只影响 `--json`：文本模式的输出本身就是 markdown，必须照常渲染。
  final includeMarkdown = !options.json || !options.nodeOnly;
  final prefixes = (options.skipNamePrefix ?? '')
      .split(',')
      .map((prefix) => prefix.trim())
      .where((prefix) => prefix.isNotEmpty)
      .toList();
  final effectiveRenderer = prefixes.isEmpty && !options.withId && !options.withLayout
      ? renderer
      : FigmaSpecRenderer(
          skipNamePrefixes: prefixes.isEmpty ? renderer.skipNamePrefixes : prefixes,
          showNodeId: options.withId,
          showLayout: options.withLayout,
        );
  final cacheStore = store ?? CacheStore(Directory(options.root));
  if (options.file == null) {
    final warning = multiFileKeyWarning(cacheStore, nodeIds);
    if (warning != null) printNote(warning);
  }
  final result = buildSpecReport(
    cacheStore,
    nodeIds: nodeIds,
    file: options.file,
    nodeDepth: options.nodeDepth,
    includeMarkdown: includeMarkdown,
    skipHidden: options.skipHidden,
    preferFullDepth: !options.allowDepth,
    renderer: effectiveRenderer,
  );

  final staleReport = options.file == null
      ? staleDepthReport(cacheStore, result.entries.map((entry) => entry.source), nodeIds)
      : const StaleDepthReport.none();
  if (staleReport.stale) printNote(staleDepthMessage(staleReport));

  final depthLimited = depthLimitedCachePaths(result.entries.map((entry) => entry.source));
  final depthMessage = depthLimited.isEmpty
      ? null
      : depthLimitedMessage(
          depthLimited,
          fullPaths: fullCachePathsForDepth(cacheStore, depthLimited, nodeIds),
          explicitFile: options.file != null,
        );
  if (depthMessage != null) printNote(depthMessage);

  if (options.json) {
    final items = <Map<String, Object?>>[
      for (final entry in result.entries)
        <String, Object?>{
          'source': entry.source,
          'sourceDepth': nodesCacheDepth(entry.source),
          'depthLimited': nodesCacheDepth(entry.source) != null,
          'nodeId': entry.nodeId,
          if (entry.markdown != null && !options.nodeOnly) 'markdown': entry.markdown,
          'node': entry.node,
        },
    ];
    printLine(jsonEncode(<String, Object?>{
      'schema': 'w_tools_figma.specs/1',
      'depthLimited': depthLimited.isNotEmpty,
      'staleAgainstDepth': staleReport.stale,
      'newerDepthAvailable': staleReport.toJson(),
      'items': items,
    }));
    return;
  }

  final sourcePaths = result.entries.map((entry) => entry.source).toSet().join(', ');
  stderr.writeln('> 数据源：$sourcePaths');
  for (var i = 0; i < result.markdowns.length; i++) {
    if (i > 0) printLine('');
    printOut(result.markdowns[i]);
  }
}

typedef SpecEntryData = ({
  String source,
  String nodeId,
  Map<String, dynamic> node,
  String? markdown,
});

typedef SpecReport = ({List<SpecEntryData> entries, List<String> markdowns});

bool _containsNode(Map node, String targetId) {
  if ('${node['id'] ?? ''}' == targetId) return true;
  final children = node['children'];
  if (children is! List) return false;
  for (final child in children) {
    if (child is Map && _containsNode(child, targetId)) return true;
  }
  return false;
}

/// 递归移除 `--skip-hidden` / `--skip-name-prefix` 命中的子树。
///
/// 目标节点及其祖先必须保留，否则 `findFigmaNode` 会找不到目标；node 与 markdown
/// 共用这棵剪枝后的树，避免两者不一致。
Map<String, dynamic> _pruneNodes(
  Map node,
  String targetId, {
  required bool skipHidden,
  required List<String> prefixes,
}) {
  final copy = Map<String, dynamic>.from(node);
  final children = node['children'];
  if (children is List) {
    final kept = <Object?>[];
    for (final child in children) {
      if (child is! Map) {
        kept.add(child);
        continue;
      }
      final id = '${child['id'] ?? ''}';
      final keep = id == targetId ||
          _containsNode(child, targetId) ||
          _keepChild(child, skipHidden: skipHidden, prefixes: prefixes);
      if (keep) {
        kept.add(_pruneNodes(
          child,
          targetId,
          skipHidden: skipHidden,
          prefixes: prefixes,
        ));
      }
    }
    copy['children'] = kept;
  }
  return copy;
}

bool _keepChild(
  Map child, {
  required bool skipHidden,
  required List<String> prefixes,
}) {
  final name = '${child['name'] ?? ''}';
  if (prefixes.any(name.startsWith)) return false;
  if (!skipHidden) return true;
  if (child['visible'] == false) return false;
  final opacity = child['opacity'];
  return !(opacity is num && opacity <= 0);
}

/// `spec` 的纯逻辑：定位缓存 → 取节点 → 按需裁剪 / 渲染。
SpecReport buildSpecReport(
  CacheStore store, {
  required List<String> nodeIds,
  String? file,
  int? nodeDepth,
  bool includeMarkdown = true,
  bool skipHidden = false,
  bool preferFullDepth = true,
  FigmaSpecRenderer renderer = const FigmaSpecRenderer(),
}) {
  final sources = resolveNodeCaches(
    store,
    nodeIds,
    explicitFile: file,
    preferFullDepth: preferFullDepth,
  );
  final documents = <File, Map<String, Map<String, dynamic>>>{};
  final entries = <SpecEntryData>[];
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
    final prefixes = renderer.skipNamePrefixes;
    final renderDocument = (skipHidden || prefixes.isNotEmpty)
        ? _pruneNodes(document, nodeId, skipHidden: skipHidden, prefixes: prefixes)
        : document;
    final renderNode = findFigmaNode(renderDocument, nodeId) ?? rawNode;
    final node = nodeDepth == null ? renderNode : trimNode(renderNode, nodeDepth);
    final markdown =
        includeMarkdown ? renderer.renderMarkdownFromRoot(renderDocument, nodeId) : null;
    if (markdown != null) markdowns.add(markdown);
    entries.add((
      source: source.path,
      nodeId: nodeId,
      node: Map<String, dynamic>.from(node),
      markdown: markdown,
    ));
  }
  if (missing.isNotEmpty) {
    throw StateError(missingNodesMessage(missing));
  }
  return (entries: entries, markdowns: markdowns);
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
