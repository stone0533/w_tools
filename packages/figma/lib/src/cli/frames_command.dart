import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import 'args.dart';
import 'cache_data.dart';
import 'cli_io.dart';

/// 列出缓存中的 FRAME，默认只列顶层画板。
Future<void> runFrames(List<String> args) async {
  final options = parseOptions(args);
  final root = Directory(options.root);
  final store = CacheStore(root);
  final files = options.file != null ? <File>[File(options.file!)] : nodesCacheFiles(store);
  if (files.isEmpty) {
    throw StateError('缓存里没有 nodes-*.json，先跑 fetch nodes');
  }

  final frames = <String, Map<String, Object?>>{};
  for (final file in files) {
    try {
      final documents = readDocuments(file);
      for (final document in documents.values) {
        _collectDocument(
          document,
          file,
          root,
          frames,
          all: options.allFrames,
        );
      }
    } on FormatException catch (e) {
      stderr.writeln('跳过损坏缓存 ${file.path}: ${e.message}');
    } on StateError catch (e) {
      stderr.writeln('跳过损坏缓存 ${file.path}: ${e.message}');
    }
  }

  final nameFilter = options.nameFilter?.toLowerCase();
  final pageFilter = options.pageFilter?.toLowerCase();
  final list = frames.values.where((frame) {
    final name = '${frame['name']}'.toLowerCase();
    final page = '${frame['page']}'.toLowerCase();
    return (nameFilter == null || name.contains(nameFilter)) &&
        (pageFilter == null || page.contains(pageFilter));
  }).toList()
    ..sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));

  if (options.json) {
    printLine(jsonEncode({
      'schema': 'w_tools_figma.frames/1',
      'frames': list,
    }));
    return;
  }
  if (list.isEmpty) {
    printLine('（没有 FRAME）');
    return;
  }

  final pageWidth = list.map((e) => '${e['page']}'.length).reduce(_max);
  final idWidth = list.map((e) => '${e['id']}'.length).reduce(_max);
  final nameWidth = list.map((e) => '${e['name']}'.length).reduce(_max);
  final sizeWidth = list.map((e) => '${e['width']}×${e['height']}'.length).reduce(_max);
  printLine(
    '${'page'.padRight(pageWidth)}  ${'id'.padRight(idWidth)}  '
    '${'name'.padRight(nameWidth)}  ${'size'.padRight(sizeWidth)}  children',
  );
  for (final frame in list) {
    final size = '${frame['width']}×${frame['height']}';
    final line = '${'${frame['page']}'.padRight(pageWidth)}  '
        '${'${frame['id']}'.padRight(idWidth)}  '
        '${'${frame['name']}'.padRight(nameWidth)}  '
        '${size.padRight(sizeWidth)}  '
        '${frame['children']}';
    printLine(options.verbose ? '$line  ${frame['cacheFile']}' : line);
  }
}

int _max(int a, int b) => a > b ? a : b;

void _collectDocument(
  Map document,
  File file,
  Directory root,
  Map<String, Map<String, Object?>> out, {
  required bool all,
}) {
  final page = '${document['name'] ?? ''}';
  final type = '${document['type']}';
  if (type == 'FRAME') {
    _addFrame(document, file, root, out, page);
    if (all) _walkChildren(document, file, root, out, page);
    return;
  }
  final children = document['children'];
  if (children is! List) return;
  for (final child in children) {
    if (child is! Map) continue;
    if ('${child['type']}' == 'FRAME') {
      _addFrame(child, file, root, out, page);
      if (all) _walkChildren(child, file, root, out, page);
    } else if (all) {
      _walkChildren(child, file, root, out, page);
    }
  }
}

void _walkChildren(
  Map node,
  File file,
  Directory root,
  Map<String, Map<String, Object?>> out,
  String page,
) {
  for (final child in (node['children'] as List?) ?? const []) {
    if (child is! Map) continue;
    if ('${child['type']}' == 'FRAME') {
      _addFrame(child, file, root, out, page);
    }
    _walkChildren(child, file, root, out, page);
  }
}

void _addFrame(
  Map node,
  File file,
  Directory root,
  Map<String, Map<String, Object?>> out,
  String page,
) {
  final id = '${node['id'] ?? ''}';
  if (id.isEmpty) return;
  final bb = node['absoluteBoundingBox'];
  final children = node['children'];
  final cacheFile = _relative(root, file);
  final next = <String, Object?>{
    'id': id,
    'name': '${node['name'] ?? ''}',
    'page': page,
    'width': bb is Map ? bb['width'] : null,
    'height': bb is Map ? bb['height'] : null,
    'children': children is List ? children.length : 0,
    'cacheFile': cacheFile,
  };
  final existing = out[id];
  if (existing == null || (next['children'] as int) > (existing['children'] as int)) {
    out[id] = next;
  }
}

String _relative(Directory root, File file) {
  final prefix = '${root.path}/';
  return file.path.startsWith(prefix) ? file.path.substring(prefix.length) : file.path;
}
