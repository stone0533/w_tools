import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import '../cache/cache_store.dart';
import '../cache/nodes_index.dart';
import '../spec/cache_document.dart';
import '../spec/figma_node.dart';
import '../tokens/token_collector.dart';
import '../tokens/token_renderer.dart';
import 'args.dart';
import 'cli_io.dart';

Future<void> runTokens(List<String> args) async {
  final options = parseCommand(args, 'tokens');
  rejectExtra(options, 1);

  final rawIds = options.positional.isEmpty ? null : options.positional.first;
  if (rawIds == null) {
    stderr.writeln('tokens 需要节点 id，例如：tokens 1862:9222,1862:9226');
    exitCode = 2;
    return;
  }
  final nodeIds = rawIds.split(',').where((e) => e.isNotEmpty).toList();
  if (options.json && options.out != null) {
    throw const FormatException('--json 与 --out 不能同时使用');
  }
  if (options.skipMarkdown && !options.json) {
    throw const FormatException('--skip-markdown 只与 --json 一起使用');
  }
  if (options.skipMarkdown && options.out != null) {
    throw const FormatException('--skip-markdown 与 --out 不能同时使用');
  }

  final colorNames = _loadColorNames(options.mapFile);
  final report = buildTokensReport(
    CacheStore(Directory(options.root)),
    nodeIds: nodeIds,
    file: options.file,
    min: options.min,
    colorNames: colorNames,
    includeMarkdown: !options.skipMarkdown,
  );

  final depthLimited = depthLimitedCachePaths(report.sources);
  if (depthLimited.isNotEmpty) {
    printNote(
      '# 数据源来自 --depth 裁剪缓存（${depthLimited.join(', ')}），子节点可能缺失；'
      '用 --file= 指定完整缓存，或重新 fetch nodes',
    );
  }

  if (options.out != null) {
    final out = File(options.out!);
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(report.markdown!);
    stderr.writeln('已写入 ${options.out}');
    return;
  }
  if (options.json) {
    printLine(
      jsonEncode({
        'schema': 'w_tools_figma.tokens/1',
        'sources': report.sources,
        'nodeIds': report.nodeIds,
        'counts': {
          'colors': report.colors.length,
          'texts': report.texts.length,
          'radii': report.radii.length,
          'spacings': report.spacings.length,
        },
        // 结构化数组：脚本 / AI 不该靠解析 markdown 拿 token。
        'colors': _colorsJson(report.colors, colorNames: colorNames),
        'texts': _textsJson(report.texts),
        'radii': _numbersJson(report.radii),
        'spacings': _numbersJson(report.spacings),
        if (report.markdown != null) 'markdown': report.markdown,
      }),
    );
    return;
  }
  printOut(report.markdown ?? '');
}

typedef TokensReport = ({
  List<ColorUsage> colors,
  List<TextStyleUsage> texts,
  List<NumberUsage> radii,
  List<NumberUsage> spacings,
  List<String> sources,
  List<String> nodeIds,
  String? markdown,
});

/// `tokens` 的纯逻辑：定位缓存 → 汇总 → 按需渲染。
TokensReport buildTokensReport(
  CacheStore store, {
  required List<String> nodeIds,
  String? file,
  int min = 1,
  Map<String, String> colorNames = const <String, String>{},
  bool includeMarkdown = true,
  TokenRenderer renderer = const TokenRenderer(),
}) {
  final sources = resolveNodeCaches(store, nodeIds, explicitFile: file);
  final documents = <File, Map<String, dynamic>>{};
  final collector = TokenCollector(minCount: min);

  for (final id in nodeIds) {
    final cache = sources[id]!;
    final docs = documents.putIfAbsent(cache, () => readDocuments(cache));
    final document = docs[id] ?? docs.values.where((d) => findFigmaNode(d, id) != null).firstOrNull;
    final node = document == null ? null : findFigmaNode(document, id);
    if (node == null) {
      throw StateError(missingNodesMessage(<String>[id]));
    }
    collector.collect(node);
  }

  final sourceFiles = sources.values.map((cache) => cache.path).toSet().toList();
  final markdown = includeMarkdown
      ? renderer.renderMarkdown(
          tokens: collector,
          source: sourceFiles.join(', '),
          nodeIds: nodeIds,
          colorNames: colorNames,
        )
      : null;
  return (
    colors: collector.colorsSorted(),
    texts: collector.textsSorted(),
    radii: collector.radiiSorted(),
    spacings: collector.spacingsSorted(),
    sources: sourceFiles,
    nodeIds: nodeIds,
    markdown: markdown,
  );
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
    final key = colorKey('${entry.key}');
    if (key.isNotEmpty) out[key] = '${entry.value}';
  }
  return out;
}

List<Map<String, Object?>> _colorsJson(
  List<ColorUsage> items, {
  Map<String, String> colorNames = const <String, String>{},
}) =>
    [
      for (final item in items)
        {
          'value': item.value,
          if (colorNames.isNotEmpty) 'name': colorNames[colorKey(item.value)],
          'count': item.count,
          'samples': item.samples,
        },
    ];

List<Map<String, Object?>> _textsJson(List<TextStyleUsage> items) => [
      for (final item in items)
        {
          'family': item.family,
          'size': item.size,
          'weight': item.weight,
          'lineHeight': item.lineHeight,
          'letterSpacing': item.letterSpacing,
          'align': item.align,
          'color': item.color,
          'count': item.count,
          'samples': item.samples,
        },
    ];

List<Map<String, Object?>> _numbersJson(List<NumberUsage> items) => [
      for (final item in items) {'value': item.value, 'count': item.count},
    ];
