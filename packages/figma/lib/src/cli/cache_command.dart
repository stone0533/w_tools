import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import '../commands/cache_command.dart';
import 'args.dart';
import 'cli_io.dart';

/// `figma cache stats|clean`。
void runCache(List<String> args) {
  final options = parseOptions(args);
  final sub = options.positional.isEmpty ? 'stats' : options.positional.first;
  rejectUnsupported(
    options,
    sub == 'clean' ? {'root', 'json', 'all', 'yes'} : {'root', 'json'},
  );
  if (sub == 'clean' && options.yes && !options.all) {
    throw const FormatException('--yes 只与 --all 一起使用');
  }
  final store = CacheStore(Directory(options.root));
  final command = CacheCommand(store);

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
      // 清理后只能重新 fetch，会消耗额度 —— --all 必须显式确认
      if (options.all && !options.yes) {
        stderr.writeln('清理所有项目缓存需要 --yes 确认（清理后重新 fetch 会消耗 Figma 额度）');
        exitCode = 2;
        return;
      }
      final (dirs, bytes) = command.clean(all: options.all);
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
