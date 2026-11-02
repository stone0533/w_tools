import 'dart:convert';
import 'dart:io';

import '../spec/figma_node.dart';
import '../tokens/token_collector.dart';
import '../tokens/tokens_renderer.dart';
import 'args.dart';
import 'cache_data.dart';
import 'cli_io.dart';

Future<void> runTokens(List<String> args) async {
  final options = parseOptions(args);
  final rawIds = options.positional.isEmpty ? null : options.positional.first;
  if (rawIds == null) {
    stderr.writeln('tokens 需要节点 id，例如：tokens 1862:9222,1862:9226');
    exitCode = 2;
    return;
  }
  final nodeIds = rawIds.split(',').where((e) => e.isNotEmpty).toList();

  final file =
      options.file != null ? File(options.file!) : pickLargestCache(Directory(options.root));
  final documents = readDocuments(file);

  final collector = TokenCollector(minCount: options.min);
  final missing = <String>[];
  for (final id in nodeIds) {
    final document =
        documents[id] ?? documents.values.where((d) => findFigmaNode(d, id) != null).firstOrNull;
    final node = document == null ? null : findFigmaNode(document, id);
    if (node == null) {
      missing.add(id);
      continue;
    }
    collector.collect(node);
  }
  if (missing.isNotEmpty) {
    throw StateError('在缓存里找不到节点：${missing.join(', ')}');
  }

  final markdown = const TokensRenderer().renderMarkdown(
    tokens: collector,
    source: file.path,
    nodeIds: nodeIds,
  );
  if (options.out != null) {
    File(options.out!).writeAsStringSync(markdown);
    stderr.writeln('已写入 ${options.out}');
    return;
  }
  if (options.json) {
    printLine(
      jsonEncode({
        'schema': 'w_tools_figma.tokens/1',
        'source': file.path,
        'nodeIds': nodeIds,
        'counts': {
          'colors': collector.colorsSorted().length,
          'texts': collector.textsSorted().length,
          'radii': collector.radiiSorted().length,
          'spacings': collector.spacingsSorted().length,
        },
        'markdown': markdown,
      }),
    );
    return;
  }
  printOut(markdown);
}
