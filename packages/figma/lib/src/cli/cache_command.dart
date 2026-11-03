import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import '../commands/cache_command.dart';
import 'args.dart';
import 'cli_io.dart';

/// `figma cache stats|clean`。
void runCache(List<String> args) {
  final options = parseOptions(args);
  rejectUnsupported(options, {'root', 'json', 'all'});
  final store = CacheStore(Directory(options.root));
  final command = CacheCommand(store);
  final sub = options.positional.isEmpty ? 'stats' : options.positional.first;

  switch (sub) {
    case 'stats':
      final s = command.stats();
      if (options.json) {
        printLine(jsonEncode({'schema': 'w_tools_figma.cache/1', ...s.toJson()}));
      } else {
        printLine('缓存目录：${s.dir.path}');
        printLine('文件数：${s.files}（${s.megabytes.toStringAsFixed(1)} MB）');
      }
    case 'clean':
      final (dirs, bytes) = command.clean(all: options.allFrames);
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
        printLine('已清理 $dirs 个项目缓存（$mb MB）${options.allFrames ? '' : '：${store.dir.path}'}');
      }
    default:
      stderr.writeln('未知子命令：$sub（可用：stats, clean）');
      exitCode = 2;
  }
}
