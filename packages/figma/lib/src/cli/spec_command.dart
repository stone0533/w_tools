import 'dart:convert';
import 'dart:io';

import '../spec/figma_node.dart';
import '../spec/spec_renderer.dart';
import 'args.dart';
import '../cache/cache_store.dart';
import 'cache_data.dart';
import 'cli_io.dart';

Future<void> runSpec(List<String> args) async {
  final options = parseOptions(args);
  rejectUnsupported(options, {'root', 'file', 'json', 'node-only', 'node-depth'});
  final rawIds = options.positional.isEmpty ? null : options.positional.first;
  if (rawIds == null) {
    stderr.writeln('spec 需要 nodeId，例如：spec 1862:9222');
    exitCode = 2;
    return;
  }
  final nodeIds = rawIds.split(',').where((e) => e.isNotEmpty).toList();
  if (nodeIds.isEmpty) {
    stderr.writeln('spec 需要 nodeId，例如：spec 1862:9222');
    exitCode = 2;
    return;
  }

  final store = CacheStore(Directory(options.root));
  final sources = resolveNodeCaches(store, nodeIds, explicitFile: options.file);
  const renderer = FigmaSpecRenderer();
  final items = <Map<String, Object?>>[];
  final markdowns = <String>[];
  final documents = <File, Map<String, Map<String, dynamic>>>{};
  final missing = <String>[];

  for (final nodeId in nodeIds) {
    final file = sources[nodeId]!;
    final docs = documents.putIfAbsent(file, () => readDocuments(file));
    final document =
        docs[nodeId] ?? docs.values.where((d) => findFigmaNode(d, nodeId) != null).firstOrNull;
    if (document == null) {
      missing.add(nodeId);
      continue;
    }
    final rawNode = findFigmaNode(document, nodeId)!;
    final node = options.nodeDepth == null ? rawNode : _trimNode(rawNode, options.nodeDepth!);
    final markdown = renderer.renderMarkdownFromRoot(document, nodeId);
    markdowns.add(markdown);
    items.add(<String, Object?>{
      'source': file.path,
      'nodeId': nodeId,
      if (!options.nodeOnly) 'markdown': markdown,
      'node': node,
    });
  }
  if (missing.isNotEmpty) {
    throw StateError(
      '在缓存里找不到节点：${missing.join(', ')}；先运行 `figma frames` 查看缓存中的 FRAME',
    );
  }

  if (options.json) {
    if (items.length == 1) {
      printLine(jsonEncode(<String, Object?>{
        'schema': 'w_tools_figma.spec/1',
        ...items.single,
      }));
    } else {
      printLine(jsonEncode(<String, Object?>{
        'schema': 'w_tools_figma.specs/1',
        'items': items,
      }));
    }
    return;
  }

  final sourcePaths = items.map((item) => '${item['source']}').toSet().join(', ');
  stderr.writeln('> 数据源：$sourcePaths');
  for (var i = 0; i < markdowns.length; i++) {
    if (i > 0) printLine('');
    printOut(markdowns[i]);
  }
}

/// 限制 JSON 里的原始节点深度；0 表示只保留当前节点，不带 children。
Map<String, dynamic> _trimNode(Map node, int depth) {
  final copy = Map<String, dynamic>.from(node);
  if (depth <= 0) {
    copy.remove('children');
    return copy;
  }
  final children = node['children'];
  if (children is List) {
    copy['children'] = <Object?>[
      for (final child in children)
        if (child is Map) _trimNode(child, depth - 1) else child,
    ];
  }
  return copy;
}
