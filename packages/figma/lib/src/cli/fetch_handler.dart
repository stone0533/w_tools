import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import '../cache/nodes_index.dart';
import '../client/figma_client.dart';
import '../commands/fetch_command.dart';
import 'args.dart';
import 'token_source.dart';
import 'cli_io.dart';

/// `fetch --json` 的稳定结构；脚本据此判断部分节点缺失。
Map<String, Object?> fetchJson(
  FetchResult result, {
  bool checkedMeta = false,
  bool versionUnknown = false,
}) =>
    {
      'schema': 'w_tools_figma.fetch/1',
      'cacheFile': result.file.path,
      'fromCache': result.fromCache,
      'tierCalls': result.tierCalls,
      'stale': result.stale,
      'cachedVersion': result.cachedVersion,
      'latestVersion': result.latestVersion,
      'missingNodeIds': result.missingNodeIds,
      'checkedMeta': checkedMeta,
      if (versionUnknown) 'versionUnknown': true,
    };

Future<void> runFetch(List<String> args) async {
  final options = parseCommand(args, 'fetch');

  rejectExtra(options, 3);
  final positional = options.positional;
  if (positional.length < 2) {
    stderr.writeln('fetch 用法：fetch <nodes|images> <fileKey> [ids]');
    exitCode = 2;
    return;
  }
  final kind = positional[0];
  final fileKey = positional[1];
  final idsRaw = positional.length > 2 ? positional[2] : null;
  final ids = idsRaw == null
      ? const <String>[]
      : idsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  if ((kind == 'nodes' || kind == 'images') && ids.isEmpty) {
    stderr.writeln('$kind 需要 ids，例如：fetch $kind <fileKey> 1862:9222');
    exitCode = 2;
    return;
  }

  if (kind == 'images') {
    if (options.depth != null) {
      throw const FormatException('images 不支持 --depth');
    }
    if (options.refresh) {
      throw const FormatException('images 不支持 --refresh：图片地址不缓存');
    }
    if (options.checkStale) {
      throw const FormatException('images 不支持 --check-stale：图片地址不缓存');
    }
  }
  if (kind == 'nodes' && options.wasProvided('scale')) {
    throw const FormatException('nodes 不支持 --scale');
  }

  final store = CacheStore(Directory(options.root));
  // 只有真正需要请求时才读 token；缓存命中不会触发 factory。
  final client = LazyFigmaClient(() => HttpFigmaClient(token: readToken(store)));
  final command = FetchCommand(
    store: store,
    client: client,
  );
  try {
    if (kind == 'images') {
      final urls = await command.imageUrls(
        fileKey: fileKey,
        ids: ids,
        scale: options.scale,
      );
      stderr.writeln('# fetched images (Tier 1: 1)');
      if (urls.values.any((url) => url == null)) {
        stderr.writeln('⚠️ 有节点没有导出图片（Figma 返回 null）');
      }
      if (options.json) {
        printLine(jsonEncode({
          'schema': 'w_tools_figma.images/1',
          'fileKey': fileKey,
          'tierCalls': 1,
          'urls': urls,
        }));
        return;
      }
      for (final entry in urls.entries) {
        printLine('${entry.key}\t${entry.value ?? ''}');
      }
      return;
    }
    if (kind != 'nodes') {
      throw FormatException('未知的 fetch 类型：$kind（nodes / images）');
    }
    final result = await command.nodes(
      fileKey: fileKey,
      ids: ids,
      depth: options.depth,
      refresh: options.refresh,
      checkStale: options.checkStale,
    );
    final depthSatisfiedByFull =
        options.depth != null && result.fromCache && nodesCacheDepth(result.file.path) == null;
    final versionUnknown = options.checkStale && result.fromCache && result.cachedVersion == null;
    if (depthSatisfiedByFull) {
      final checked = options.checkStale ? '; checked /meta' : '';
      stderr.writeln(
        '# cache hit (完整缓存已满足 --depth$checked): ${result.file.path}',
      );
    } else if (result.fromCache) {
      stderr.writeln(
        options.checkStale
            ? '# cache hit (checked /meta): ${result.file.path}'
            : '# cache hit: ${result.file.path}',
      );
    } else {
      stderr.writeln('# fetched: ${result.file.path}');
    }
    if (versionUnknown) {
      stderr.writeln(
        '# 缓存没有 version，无法判断是否过期；需要时用 --refresh 重新拉取',
      );
    }
    if (result.stale) {
      stderr.writeln(
        '⚠️ 缓存可能过期：版本 ${result.cachedVersion} → ${result.latestVersion}；'
        '确认要更新请加 --refresh（会消耗 1 次 Tier 1）',
      );
    }
    if (result.missingNodeIds.isNotEmpty) {
      final reason = result.fromCache && result.tierCalls == 0 ? '缓存里记录为缺失' : 'Figma 返回 null';
      stderr.writeln(
        '⚠️ 缺少节点：${result.missingNodeIds.join(', ')}（$reason，已跳过）',
      );
    }
    if (options.json) {
      printLine(jsonEncode(fetchJson(
        result,
        checkedMeta: options.checkStale,
        versionUnknown: versionUnknown,
      )));
    }
  } finally {
    client.close();
  }
}
