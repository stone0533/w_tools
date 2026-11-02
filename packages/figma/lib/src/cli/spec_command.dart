import 'dart:convert';
import 'dart:io';

import '../spec/figma_node.dart';
import '../spec/spec_renderer.dart';
import 'args.dart';
import 'cache_data.dart';
import 'cli_io.dart';

Future<void> runSpec(List<String> args) async {
  final options = parseOptions(args);
  final nodeId = options.positional.isEmpty ? null : options.positional.first;
  if (nodeId == null) {
    stderr.writeln('spec 需要 nodeId，例如：spec 1862:9222');
    exitCode = 2;
    return;
  }

  final root = Directory(options.root);
  final file = options.file != null ? File(options.file!) : pickLargestCache(root);
  final document = readDocument(file, nodeId);
  if (document == null) {
    throw StateError(
      '在缓存里找不到节点：$nodeId；先运行 `figma frames` 查看缓存中的 FRAME',
    );
  }
  final rawNode = findFigmaNode(document, nodeId)!;
  final node = options.nodeDepth == null ? rawNode : _trimNode(rawNode, options.nodeDepth!);

  const renderer = FigmaSpecRenderer();
  if (options.json) {
    final markdown = renderer.renderMarkdownFromRoot(document, nodeId);
    printLine(
      jsonEncode({
        'schema': 'w_tools_figma.spec/1',
        'source': file.path,
        'nodeId': nodeId,
        if (!options.nodeOnly) 'markdown': markdown,
        // 原始 Figma 节点；需要结构化字段时直接读它，markdown 仅用于人读。
        'node': node,
      }),
    );
    return;
  }
  stderr.writeln('> 数据源：${file.path}');
  printOut(renderer.renderMarkdownFromRoot(document, nodeId));
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
