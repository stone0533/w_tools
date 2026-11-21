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

  final store = CacheStore(Directory(options.root));
  final root = store.root;
  final nameFilter = _filterValue(options, 'name');
  final pageFilter = _filterValue(options, 'page');

  final includeNested =
      options.all || options.depth != null || nameFilter != null || pageFilter != null;
  var rows = const <Map<String, Object?>>[];
  if (options.file != null) {
    // 显式给文件时直接解析这一份，方便对着任意 nodes 缓存排错。
    final file = File(options.file!);
    try {
      rows = framesFromFile(
        file,
        root: root,
        all: includeNested,
        maxDepth: options.depth,
      );
    } on FormatException catch (e) {
      // 显式 --file 解析失败不能伪装成「没有画板」：脚本会误判成功。
      stderr.writeln('缓存解析失败 ${file.path}: ${e.message}');
      exitCode = 1;
      return;
    } on StateError catch (e) {
      stderr.writeln('缓存解析失败 ${file.path}: ${e.message}');
      exitCode = 1;
      return;
    }
  } else {
    if (nodesCacheFiles(store).isEmpty) {
      throw StateError('${store.dir.path} 里没有 nodes-*.json，先跑 fetch nodes');
    }
    final outcome = framesFromIndex(
      store,
      root: root,
      all: includeNested,
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
    nameFilter: nameFilter,
    pageFilter: pageFilter,
  );
  if (pageFilter != null && pageFilter != '-' && rows.any((row) => '${row['page']}'.isEmpty)) {
    stderr.writeln(
      '# 部分单节点缓存的 FRAME 没有 page 信息，--page 可能漏掉它们；请用完整页面缓存或 --file=',
    );
  }
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
  final pageWidth = visible.map((e) => _width('${e['page']}')).reduce(_max);
  final pageIdWidth = visible.map((e) => _width('${e['pageId'] ?? '-'}')).reduce(_max);
  final idWidth = visible.map((e) => _width('${e['id']}')).reduce(_max);
  final typeWidth = visible.map((e) => _width('${e['type'] ?? '-'}')).reduce(_max);
  final nameWidth = visible.map((e) => _width('${e['name']}')).reduce(_max);
  final sizeWidth = visible.map((e) => _width('${e['width']}×${e['height']}')).reduce(_max);
  printLine(
    '${_pad('page', pageWidth)}  ${_pad('pageId', pageIdWidth)}  ${_pad('id', idWidth)}  '
    '${_pad('type', typeWidth)}  ${_pad('name', nameWidth)}  '
    '${_pad('size', sizeWidth)}  children',
  );
  for (final frame in visible) {
    final size = '${frame['width']}×${frame['height']}';
    final truncated = frame['cacheDepth'] != null;
    final pageId = '${frame['pageId'] ?? ''}';
    final line = '${_pad(('${frame['page']}'.isEmpty) ? '-' : '${frame['page']}', pageWidth)}  '
        '${_pad(pageId.isEmpty ? '-' : pageId, pageIdWidth)}  '
        '${_pad('${frame['id']}', idWidth)}  '
        '${_pad('${frame['type'] ?? '-'}', typeWidth)}  '
        '${_pad('${frame['name']}', nameWidth)}  '
        '${_pad(size, sizeWidth)}  '
        '${frame['children']}${truncated ? '*' : ''}';
    printLine(options.verbose ? '$line  ${frame['cacheFile']}  ${frame['fetchedAt'] ?? ''}' : line);
  }
  if (visible.any((frame) => frame['cacheDepth'] != null)) {
    printLine('');
    printLine('* 来自 --depth 裁剪缓存，children 可能不完整；可用完整缓存或 --file=');
  }
}

/// 过滤值不允许空串：`--name=` 以前会把 includeNested 强制打开，静默列出全部嵌套画板。
String? _filterValue(CommandArgs options, String name) {
  final raw = options.option(name);
  if (raw == null) return null;
  final value = raw.trim();
  if (value.isEmpty) throw FormatException('--$name 不能为空');
  return value;
}

int _width(String value) => value.runes.fold(0, (sum, rune) {
      final wide = (rune >= 0x1100 && rune <= 0x115F) ||
          (rune >= 0x2E80 && rune <= 0xA4CF) ||
          (rune >= 0xAC00 && rune <= 0xD7A3) ||
          (rune >= 0xF900 && rune <= 0xFAFF) ||
          (rune >= 0xFE30 && rune <= 0xFE6F) ||
          (rune >= 0xFF00 && rune <= 0xFF60) ||
          (rune >= 0xFFE0 && rune <= 0xFFE6) ||
          (rune >= 0x20000 && rune <= 0x3FFFD);
      return sum + (wide ? 2 : 1);
    });

String _pad(String value, int width) => value + ' ' * (width - _width(value)).clamp(0, width);

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
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(
        file.statSync().modified.millisecondsSinceEpoch,
      ).toIso8601String(),
      out: frames,
    );
  }
  final depth = nodesCacheDepth(file.path);
  return <Map<String, Object?>>[
    for (final row in frames.values) {...row, 'cacheDepth': depth},
  ];
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
    final pageMatches = page == null || (page == '-' ? rowPage.isEmpty : rowPage.contains(page));
    return (name == null || rowName.contains(name)) && pageMatches;
  }).toList()
    ..sort((a, b) {
      final byName = '${a['name']}'.compareTo('${b['name']}');
      // 同名画板按 id 排，脚本拿到的顺序才稳定。
      return byName != 0 ? byName : '${a['id']}'.compareTo('${b['id']}');
    });
}
