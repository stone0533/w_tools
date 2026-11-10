import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import '../commands/spec_command.dart';
import '../spec/spec_renderer.dart';
import 'args.dart';
import 'cli_io.dart';

Future<void> runSpec(
  List<String> args, {
  FigmaSpecRenderer renderer = const FigmaSpecRenderer(),
}) async {
  final options = parseOptions(args);
  rejectUnsupported(options, {'root', 'file', 'json', 'node-only', 'node-depth'});
  rejectExtraPositional(options, 1);

  if (options.seenText['node-only'] == '--no-markdown') {
    stderr.writeln('# --no-markdown 已弃用，改用 --node-only（remove-in: 0.13.0）');
  }

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

  // `--node-only` 只影响 `--json`：文本模式的输出本身就是 markdown，必须照常渲染。
  final includeMarkdown = !options.json || !options.nodeOnly;
  final result = SpecCommand(CacheStore(Directory(options.root)), renderer: renderer).run(
    nodeIds: nodeIds,
    file: options.file,
    nodeDepth: options.nodeDepth,
    includeMarkdown: includeMarkdown,
  );

  if (options.json) {
    final items = <Map<String, Object?>>[
      for (final entry in result.entries)
        <String, Object?>{
          'source': entry.source,
          'nodeId': entry.nodeId,
          if (entry.markdown != null && !options.nodeOnly) 'markdown': entry.markdown,
          'node': entry.node,
        },
    ];
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

  final sourcePaths = result.entries.map((entry) => entry.source).toSet().join(', ');
  stderr.writeln('> 数据源：$sourcePaths');
  for (var i = 0; i < result.markdowns.length; i++) {
    if (i > 0) printLine('');
    printOut(result.markdowns[i]);
  }
}
