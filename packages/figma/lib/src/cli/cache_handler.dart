import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import 'args.dart';
import 'cli_io.dart';

/// `figma cache stats|clean`。
void runCache(List<String> args) {
  final options = parseCommand(args, 'cache');
  final sub = options.positional.isEmpty ? 'stats' : options.positional.first;
  if (sub == 'stats') {
    final bad = <String>[
      if (options.all) '--all',
      if (options.yes) '--yes',
      if (options.legacy) '--legacy',
      if (options.file != null) '--file',
    ];
    if (bad.isNotEmpty) {
      throw FormatException('不支持的选项：${bad.join(', ')}');
    }
  }
  if (sub == 'clean' && options.files) {
    throw const FormatException('clean 不支持 --files');
  }
  if (sub == 'clean' && options.file != null && (options.all || options.legacy)) {
    throw const FormatException('--file 不能与 --all / --legacy 一起使用');
  }

  rejectExtra(options, 1);
  final store = CacheStore(Directory(options.root));

  switch (sub) {
    case 'stats':
      final s = cacheStats(store);
      final megabytes = s.bytes / (1024 * 1024);
      final entries = options.files ? cacheFileEntries(store) : const <CacheFileEntry>[];
      if (options.json) {
        printLine(jsonEncode({
          'schema': 'w_tools_figma.cache/1',
          'dir': s.dir.path,
          'files': s.files,
          'bytes': s.bytes,
          'megabytes': double.parse(megabytes.toStringAsFixed(1)),
          if (options.files)
            'entries': [
              for (final entry in entries)
                {
                  'path': entry.path,
                  'bytes': entry.bytes,
                  'kind': entry.kind,
                  'indexed': entry.indexed,
                },
            ],
        }));
      } else {
        printLine('缓存目录：${s.dir.path}');
        printLine('文件数：${s.files}（${megabytes.toStringAsFixed(1)} MB）');
        for (final entry in entries) {
          printLine(
            '${(entry.bytes / (1024 * 1024)).toStringAsFixed(1)} MB  '
            '${entry.kind.padRight(6)} ${entry.indexed ? 'indexed' : 'not-indexed'} ${entry.path}',
          );
        }
      }
    case 'clean':
      // 清理后只能重新 fetch，会消耗额度 —— 当前项目 / --all 都必须显式确认
      if (!options.yes) {
        final int files;
        final int bytes;
        if (options.all) {
          final all = cacheStatsAll(store);
          files = all.files;
          bytes = all.bytes;
        } else {
          final s = cacheStats(store);
          files = s.files;
          bytes = s.bytes;
        }
        final megabytes = (bytes / (1024 * 1024)).toStringAsFixed(1);
        stderr.writeln(
          '清理${options.all ? '所有项目' : '当前项目'}缓存需要 --yes 确认'
          '（${options.all ? '所有项目' : '当前项目'} $files 个文件 / $megabytes MB；'
          '清理后重新 fetch 会消耗 Figma 额度）',
        );
        exitCode = 2;
        return;
      }
      if (options.file != null) {
        final (file, bytes) = cleanFile(store, options.file!);
        final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
        if (options.json) {
          printLine(jsonEncode({
            'schema': 'w_tools_figma.cache/1',
            'removedFiles': 1,
            'bytes': bytes,
            'path': file.path,
          }));
        } else {
          printLine('已清理缓存文件：${file.path}（$mb MB）');
        }
        return;
      }
      if (options.legacy) {
        final (files, bytes) = cleanLegacy(store, all: options.all);
        final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
        if (options.json) {
          printLine(jsonEncode({
            'schema': 'w_tools_figma.cache/1',
            'removedFiles': files,
            'bytes': bytes,
          }));
        } else if (files == 0) {
          printLine('没有可清理的遗留缓存');
        } else {
          printLine('已清理 $files 个遗留缓存文件（$mb MB）');
        }
        return;
      }
      final (dirs, bytes) = cleanCache(store, all: options.all);
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
      if (options.json) {
        printLine(jsonEncode({
          'schema': 'w_tools_figma.cache/1',
          'removedDirs': dirs,
          'bytes': bytes,
        }));
      } else if (dirs == 0) {
        printLine('没有可清理的缓存');
      } else {
        printLine('已清理 $dirs 个项目缓存（$mb MB）${options.all ? '' : '：${store.dir.path}'}');
      }
    default:
      stderr.writeln('未知子命令：$sub（可用：stats, clean）');
      exitCode = 2;
  }
}

/// `cache stats --files` 的一行。
typedef CacheFileEntry = ({
  String path,
  int bytes,
  String kind,
  bool indexed,
});

/// 当前项目缓存的逐文件明细；[kind] 区分 legacy / nodes / index / other。
List<CacheFileEntry> cacheFileEntries(CacheStore store) {
  final entries = <CacheFileEntry>[];
  if (!store.dir.existsSync()) return entries;
  final indexedPaths = _indexedPaths(store);
  for (final entity in store.dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    final kind = _cacheKind(entity.uri.pathSegments.last);
    entries.add((
      path: entity.path,
      bytes: entity.statSync().size,
      kind: kind,
      indexed: indexedPaths?.contains(entity.path) ?? false,
    ));
  }
  entries.sort((a, b) => b.bytes.compareTo(a.bytes));
  return entries;
}

Set<String>? _indexedPaths(CacheStore store) {
  final indexFile = File('${store.dir.path}/_nodes-index.json');
  if (!indexFile.existsSync()) return null;
  try {
    final raw = jsonDecode(indexFile.readAsStringSync());
    final files = raw is Map ? raw['files'] : null;
    if (files is Map) return files.keys.map((key) => '$key').toSet();
  } on FormatException {
    // 索引坏了就当没有；stats 不该因此失败。
  } on FileSystemException {
    // 只读目录也可能读失败。
  }
  return null;
}

String _cacheKind(String name) {
  if (name.startsWith('file-')) return 'legacy';
  if (name.startsWith('nodes-')) return 'nodes';
  if (name == '_nodes-index.json') return 'index';
  return 'other';
}

String filePath(File file) => file.absolute.uri.normalizePath().toFilePath();

/// 删一个显式点名的缓存文件；只允许当前项目缓存目录内，防止误删。
(File file, int bytes) cleanFile(CacheStore store, String raw) {
  final root = store.dir.absolute;
  final rootPath = Directory(root.path).absolute.path;
  final candidate = File(raw).isAbsolute ? File(raw) : File('${root.path}/$raw');
  final file = File(filePath(candidate));
  final resolvedRoot = _canonicalDir(rootPath);
  // 先比较目录（不存在时只做绝对化），解析软链后再比较文件本身：
  // macOS 上 `/tmp` 与 `/private/tmp` 是同一目录，但不能因此放行缓存目录外的文件。
  if (_canonicalDir(file.parent.path) != resolvedRoot) {
    throw FormatException('--file 只能删当前项目缓存目录下的文件：$raw');
  }
  if (!file.existsSync()) {
    throw StateError('缓存文件不存在：${file.path}');
  }
  final resolved = File(file.resolveSymbolicLinksSync());
  if (resolved.parent.path != resolvedRoot) {
    throw FormatException('--file 只能删当前项目缓存目录下的文件：$raw');
  }
  if (FileSystemEntity.typeSync(resolved.path) != FileSystemEntityType.file) {
    throw StateError('缓存文件不存在：${resolved.path}');
  }
  final bytes = resolved.statSync().size;
  resolved.deleteSync();
  return (resolved, bytes);
}

String _canonicalDir(String path) {
  final dir = Directory(path);
  try {
    return dir.resolveSymbolicLinksSync();
  } on FileSystemException {
    return dir.absolute.uri.normalizePath().toFilePath();
  }
}

/// 只删旧 `file-*` 缓存；`nodes-*` 是有效缓存，不能按“看起来没用”删。
(int files, int bytes) cleanLegacy(CacheStore store, {bool all = false}) {
  final targets = <Directory>[];
  if (all) {
    if (store.cacheRoot.existsSync()) {
      for (final entity in store.cacheRoot.listSync()) {
        if (entity is Directory) targets.add(entity);
      }
    }
  } else if (store.dir.existsSync()) {
    targets.add(store.dir);
  }
  var files = 0;
  var bytes = 0;
  for (final dir in targets) {
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      if (!entity.uri.pathSegments.last.startsWith('file-')) continue;
      bytes += entity.statSync().size;
      entity.deleteSync();
      files++;
    }
  }
  return (files, bytes);
}

/// 所有项目缓存目录的总统计（`cache clean --all` 的确认信息用）。
({int files, int bytes}) cacheStatsAll(CacheStore store) {
  var files = 0;
  var bytes = 0;
  if (store.cacheRoot.existsSync()) {
    for (final entity in store.cacheRoot.listSync()) {
      if (entity is! Directory) continue;
      for (final child in entity.listSync(recursive: true)) {
        if (child is! File) continue;
        files++;
        bytes += child.statSync().size;
      }
    }
  }
  return (files: files, bytes: bytes);
}

/// 一个缓存目录的统计。
({Directory dir, int files, int bytes}) cacheStats(CacheStore store) {
  var files = 0;
  var bytes = 0;
  if (store.dir.existsSync()) {
    for (final entity in store.dir.listSync(recursive: true)) {
      if (entity is! File) continue;
      files++;
      bytes += entity.statSync().size;
    }
  }
  return (dir: store.dir, files: files, bytes: bytes);
}

/// 删除当前项目缓存；[all] 时删除账号下所有项目缓存（保留用量/预算）。
/// 返回清理的目录数与字节数。
(int dirs, int bytes) cleanCache(CacheStore store, {bool all = false}) {
  final targets = <Directory>[];
  if (all) {
    if (store.cacheRoot.existsSync()) {
      for (final entity in store.cacheRoot.listSync()) {
        if (entity is Directory) targets.add(entity);
      }
    }
  } else if (store.dir.existsSync()) {
    targets.add(store.dir);
  }

  var bytes = 0;
  for (final dir in targets) {
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File) bytes += entity.statSync().size;
    }
    dir.deleteSync(recursive: true);
  }
  return (targets.length, bytes);
}
