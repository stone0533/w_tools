import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import '../cache/nodes_index.dart';
import '../spec/cache_document.dart';
import 'args.dart';
import 'cli_io.dart';

/// 列出缓存中的 FRAME，默认只列顶层画板。
///
/// 不给 `--file` 时用 `_nodes-index.json` 的 FRAME 摘要；坏文件跳过并提示。
Future<void> runFrames(List<String> args) async {
  final options = parseCommand(args, 'frames');
  rejectExtra(options, 0);

  final root = Directory(options.root);
  final store = CacheStore(root);

  var rows = const <Map<String, Object?>>[];
  if (options.file != null) {
    // 显式给文件时直接解析这一份，方便对着任意 nodes 缓存排错。
    final file = File(options.file!);
    try {
      rows = framesFromFile(
        file,
        root: root,
        all: options.all || options.depth != null,
        maxDepth: options.depth,
      );
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
    final outcome = framesFromIndex(
      store,
      root: root,
      all: options.all || options.depth != null,
      maxDepth: options.depth,
    );
    rows = outcome.rows;
    if (outcome.corrupt.isNotEmpty) {
      final paths = outcome.corrupt.map((file) => file.path).join(', ');
      stderr.writeln('# 跳过 ${outcome.corrupt.length} 个解析失败的缓存：$paths');
    }
  }

  final list = filterFrames(
    rows,
    nameFilter: options.nameFilter,
    pageFilter: options.pageFilter,
  );
  final total = list.length;
  final limited = options.limit == null ? list : list.take(options.limit!).toList();
  final truncated = limited.length < total;
  // `nested` 只用于筛选，不进输出：frames --json 的契约里没有这个字段。
  final visible = <Map<String, Object?>>[
    for (final frame in limited) Map<String, Object?>.from(frame)..remove('nested'),
  ];

  if (options.json) {
    printLine(jsonEncode({
      'schema': 'w_tools_figma.frames/1',
      'total': total,
      'truncated': truncated,
      'frames': visible,
    }));
    return;
  }
  if (visible.isEmpty) {
    printLine('（没有 FRAME）');
    return;
  }

  if (truncated) {
    stderr.writeln('# 仅显示 ${visible.length}/$total 条（--limit=${options.limit}）');
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

/// 直接解析一个缓存文件；文件损坏时抛 [StateError] / [FormatException]。
List<Map<String, Object?>> framesFromFile(
  File file, {
  required Directory root,
  required bool all,
  int? maxDepth,
}) {
  final frames = <String, Map<String, Object?>>{};
  for (final document in readDocuments(file).values) {
    collectFrames(
      document,
      all: all,
      maxDepth: maxDepth,
      cacheFile: relativeToRoot(root, file),
      out: frames,
    );
  }
  return frames.values.toList();
}

/// 名称 / 页面过滤（大小写不敏感的子串）+ 按 name、id 排序。
List<Map<String, Object?>> filterFrames(
  List<Map<String, Object?>> rows, {
  String? nameFilter,
  String? pageFilter,
}) {
  final name = nameFilter?.toLowerCase();
  final page = pageFilter?.toLowerCase();
  return rows.where((row) {
    final rowName = '${row['name']}'.toLowerCase();
    final rowPage = '${row['page']}'.toLowerCase();
    return (name == null || rowName.contains(name)) && (page == null || rowPage.contains(page));
  }).toList()
    ..sort((a, b) {
      final byName = '${a['name']}'.compareTo('${b['name']}');
      // 同名画板按 id 排，脚本拿到的顺序才稳定。
      return byName != 0 ? byName : '${a['id']}'.compareTo('${b['id']}');
    });
}
