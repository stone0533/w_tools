import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import '../client/figma_client.dart';
import '../commands/fetch_command.dart';
import 'args.dart';
import 'cache_data.dart';
import 'cli_io.dart';

Future<void> runFetch(List<String> args) async {
  final options = parseOptions(args);
  final positional = options.positional;
  if (positional.length < 2) {
    stderr.writeln('fetch 用法：fetch <file|nodes|images> <fileKey> [ids]');
    exitCode = 2;
    return;
  }
  final kind = positional[0];
  final fileKey = positional[1];
  final idsRaw = positional.length > 2 ? positional[2] : null;
  final ids =
      idsRaw == null ? const <String>[] : idsRaw.split(',').where((e) => e.isNotEmpty).toList();
  if ((kind == 'nodes' || kind == 'images') && ids.isEmpty) {
    stderr.writeln('$kind 需要 ids，例如：fetch $kind <fileKey> 1862:9222');
    exitCode = 2;
    return;
  }

  final store = CacheStore(Directory(options.root));
  // 只有真正需要请求时才读 token；缓存命中不会触发 factory。
  final client = LazyFigmaClient(() => HttpFigmaClient(token: readToken(store)));
  final command = FetchCommand(store: store, client: client, log: options.log);
  try {
    final result = switch (kind) {
      'file' => await command.file(
          fileKey: fileKey,
          depth: options.depth,
          refresh: options.refresh,
          checkStale: options.checkStale,
        ),
      'nodes' => await command.nodes(
          fileKey: fileKey,
          ids: ids,
          refresh: options.refresh,
          checkStale: options.checkStale,
        ),
      'images' => await command.images(
          fileKey: fileKey,
          ids: ids,
          scale: options.scale,
          refresh: options.refresh,
          checkStale: options.checkStale,
        ),
      _ => throw FormatException('未知的 fetch 类型：$kind（file / nodes / images）'),
    };
    if (result.fromCache) {
      stderr.writeln('# cache hit: ${result.file.path}');
    } else {
      stderr.writeln('# fetched: ${result.file.path}');
    }
    if (result.stale) {
      stderr.writeln(
        '⚠️ 缓存可能过期：版本 ${result.cachedVersion} → ${result.latestVersion}；'
        '确认要更新请加 --refresh（会消耗 1 次 Tier 1）',
      );
    }
    if (options.json) {
      printLine(jsonEncode({
        'schema': 'w_tools_figma.fetch/1',
        'cacheFile': result.file.path,
        'fromCache': result.fromCache,
        'tierCalls': result.tierCalls,
        'stale': result.stale,
        'cachedVersion': result.cachedVersion,
        'latestVersion': result.latestVersion,
      }));
    }
  } finally {
    client.close();
  }
}
