import 'dart:convert';
import 'dart:io';

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
    throw StateError('在缓存里找不到节点：$nodeId');
  }

  const renderer = FigmaSpecRenderer();
  if (options.json) {
    final markdown = renderer.renderMarkdownFromRoot(document, nodeId);
    printLine(
      jsonEncode({
        'schema': 'w_tools_figma.spec/1',
        'source': file.path,
        'nodeId': nodeId,
        'markdown': markdown,
      }),
    );
    return;
  }
  stderr.writeln('> 数据源：${file.path}');
  printOut(renderer.renderMarkdownFromRoot(document, nodeId));
}
