import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import '../cache/cache_store.dart';
import '../cache/nodes_index.dart';
import '../commands/tokens_command.dart';
import '../tokens/token_collector.dart';
import 'args.dart';
import 'cli_io.dart';

Future<void> runTokens(List<String> args) async {
  final options = parseOptions(args);
  rejectUnsupported(options, {'root', 'file', 'json', 'min', 'out', 'map'});
  rejectExtraPositional(options, 1);

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

  final report = TokensCommand(CacheStore(Directory(options.root))).run(
    nodeIds: nodeIds,
    file: options.file,
    min: options.min,
    colorNames: _loadColorNames(options.mapFile),
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
    out.writeAsStringSync(report.markdown);
    stderr.writeln('已写入 ${options.out}');
    return;
  }
  if (options.json) {
    printLine(
      jsonEncode({
        'schema': 'w_tools_figma.tokens/1',
        'source': report.sources.first,
        'sources': report.sources,
        'nodeIds': report.nodeIds,
        'counts': {
          'colors': report.colors.length,
          'texts': report.texts.length,
          'radii': report.radii.length,
          'spacings': report.spacings.length,
        },
        // 结构化数组：脚本 / AI 不该靠解析 markdown 拿 token。
        'colors': _colorsJson(report.colors),
        'texts': _textsJson(report.texts),
        'radii': _numbersJson(report.radii),
        'spacings': _numbersJson(report.spacings),
        'markdown': report.markdown,
      }),
    );
    return;
  }
  printOut(report.markdown);
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

List<Map<String, Object?>> _colorsJson(List<ColorUsage> items) => [
      for (final item in items) {'value': item.value, 'count': item.count, 'samples': item.samples},
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
