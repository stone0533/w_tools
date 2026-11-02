import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import 'args.dart';
import 'cache_data.dart';
import 'cli_io.dart';

/// 列出缓存中的 FRAME，方便找 nodeId。
Future<void> runFrames(List<String> args) async {
  final options = parseOptions(args);
  final store = CacheStore(Directory(options.root));
  final files = options.file != null ? <File>[File(options.file!)] : nodesCacheFiles(store);
  if (files.isEmpty) {
    throw StateError('缓存里没有 nodes-*.json，先跑 fetch nodes');
  }

  final frames = <String, Map<String, Object?>>{};
  for (final file in files) {
    final documents = readDocuments(file);
    for (final document in documents.values) {
      _collectFrames(document, file, frames);
    }
  }
  final list = frames.values.toList()..sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));

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
  for (final frame in list) {
    printLine(
      '${frame['id']}  ${frame['name']}  '
      '${frame['width']}×${frame['height']}  '
      'children=${frame['children']}  ${frame['cacheFile']}',
    );
  }
}

void _collectFrames(
  Map node,
  File cacheFile,
  Map<String, Map<String, Object?>> out,
) {
  if ('${node['type']}' == 'FRAME') {
    final id = '${node['id'] ?? ''}';
    if (id.isNotEmpty && !out.containsKey(id)) {
      final bb = node['absoluteBoundingBox'];
      final children = node['children'];
      out[id] = <String, Object?>{
        'id': id,
        'name': '${node['name'] ?? ''}',
        'width': bb is Map ? bb['width'] : null,
        'height': bb is Map ? bb['height'] : null,
        'children': children is List ? children.length : 0,
        'cacheFile': cacheFile.path,
      };
    }
  }
  for (final child in (node['children'] as List?) ?? const []) {
    if (child is Map) _collectFrames(child, cacheFile, out);
  }
}
