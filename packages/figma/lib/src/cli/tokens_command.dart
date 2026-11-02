import 'dart:convert';

import 'package:yaml/yaml.dart';
import 'dart:io';

import '../spec/figma_node.dart';
import '../tokens/token_collector.dart';
import '../tokens/token_renderer.dart';
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

  final sources = resolveNodeCaches(
    Directory(options.root),
    nodeIds,
    explicitFile: options.file,
  );
  final documents = <File, Map<String, dynamic>>{};
  final collector = TokenCollector(minCount: options.min);
  for (final id in nodeIds) {
    final file = sources[id]!;
    final docs = documents.putIfAbsent(file, () => readDocuments(file));
    final document = docs[id] ?? docs.values.where((d) => findFigmaNode(d, id) != null).firstOrNull;
    final node = document == null ? null : findFigmaNode(document, id);
    if (node == null) {
      throw StateError('在缓存里找不到节点：$id；先运行 `figma frames --verbose` 查看');
    }
    collector.collect(node);
  }
  final source = sources.values.map((f) => f.path).toSet().join(', ');

  final colorNames = _loadColorNames(options.mapFile);
  final markdown = const TokenRenderer().renderMarkdown(
    tokens: collector,
    source: source,
    nodeIds: nodeIds,
    colorNames: colorNames,
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
        'source': source,
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

Map<String, String> _loadColorNames(String? path) {
  if (path == null) return const <String, String>{};
  YamlNode raw;
  try {
    raw = loadYamlNode(File(path).readAsStringSync());
  } on YamlException catch (e) {
    throw FormatException('$path 解析失败：${e.message}');
  }
  if (raw is! YamlMap) {
    throw FormatException('$path 顶层必须是 map');
  }
  final colors = raw['colors'];
  if (colors is! Map || colors.isEmpty) {
    throw FormatException('$path 缺少 colors: 段');
  }
  final out = <String, String>{};
  for (final entry in colors.entries) {
    final key = '${entry.key}'.replaceAll('#', '').toUpperCase();
    if (key.isNotEmpty) out[key] = '${entry.value}';
  }
  return out;
}
