import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import '../cache/nodes_index.dart';
import '../commands/frames_command.dart';
import 'args.dart';
import 'cli_io.dart';

/// 列出缓存中的 FRAME，默认只列顶层画板。
///
/// 不给 `--file` 时只读 `_nodes-index.json` 里的 FRAME 摘要，不再重新解析缓存文件。
Future<void> runFrames(List<String> args) async {
  final options = parseOptions(args);
  rejectUnsupported(options, {'root', 'file', 'json', 'all', 'name', 'page', 'verbose'});
  rejectExtraPositional(options, 0);

  final root = Directory(options.root);
  final store = CacheStore(root);
  final command = FramesCommand(store);

  var rows = const <Map<String, Object?>>[];
  if (options.file != null) {
    // 显式给文件时不走索引：直接解析这一份，方便对着任意 nodes 缓存排错。
    final file = File(options.file!);
    try {
      rows = command.fromFile(file, root: root, all: options.all);
    } on FormatException catch (e) {
      stderr.writeln('跳过损坏缓存 ${file.path}: ${e.message}');
      rows = const <Map<String, Object?>>[];
    } on StateError catch (e) {
      stderr.writeln('跳过损坏缓存 ${file.path}: ${e.message}');
      rows = const <Map<String, Object?>>[];
    }
  } else {
    if (nodesCacheFiles(store).isEmpty) {
      throw StateError('缓存里没有 nodes-*.json，先跑 fetch nodes');
    }
    rows = command.fromIndex(root: root, all: options.all);
    final corrupt = corruptCacheFiles(store);
    if (corrupt.isNotEmpty) {
      final paths = corrupt.map((file) => file.path).join(', ');
      stderr.writeln('# 跳过 ${corrupt.length} 个解析失败的缓存：$paths');
    }
  }

  final list = command.filter(
    rows,
    nameFilter: options.nameFilter,
    pageFilter: options.pageFilter,
  );
  // `nested` 只用于筛选，不进输出：frames --json 的契约里没有这个字段。
  final visible = <Map<String, Object?>>[
    for (final frame in list) Map<String, Object?>.from(frame)..remove('nested'),
  ];

  if (options.json) {
    printLine(jsonEncode({
      'schema': 'w_tools_figma.frames/1',
      'frames': visible,
    }));
    return;
  }
  if (visible.isEmpty) {
    printLine('（没有 FRAME）');
    return;
  }

  final pageWidth = visible.map((e) => '${e['page']}'.length).reduce(_max);
  final idWidth = visible.map((e) => '${e['id']}'.length).reduce(_max);
  final nameWidth = visible.map((e) => '${e['name']}'.length).reduce(_max);
  final sizeWidth = visible.map((e) => '${e['width']}×${e['height']}'.length).reduce(_max);
  printLine(
    '${'page'.padRight(pageWidth)}  ${'id'.padRight(idWidth)}  '
    '${'name'.padRight(nameWidth)}  ${'size'.padRight(sizeWidth)}  children',
  );
  for (final frame in visible) {
    final size = '${frame['width']}×${frame['height']}';
    final line =
        '${(('${frame['page']}'.isEmpty) ? '-' : '${frame['page']}').padRight(pageWidth)}  '
        '${'${frame['id']}'.padRight(idWidth)}  '
        '${'${frame['name']}'.padRight(nameWidth)}  '
        '${size.padRight(sizeWidth)}  '
        '${frame['children']}';
    printLine(options.verbose ? '$line  ${frame['cacheFile']}' : line);
  }
}

int _max(int a, int b) => a > b ? a : b;
