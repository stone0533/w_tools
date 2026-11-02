import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import '../client/figma_client.dart';
import '../commands/diff_command.dart';
import 'args.dart';
import 'cache_data.dart';
import 'cli_io.dart';

Future<void> runDiff(List<String> args) async {
  final options = parseOptions(args);
  rejectUnsupported(options, {'root', 'json', 'if-stale', 'no-log'});
  final positional = options.positional;
  if (positional.length < 2) {
    stderr.writeln('diff 用法：diff <fileKey> <nodeId>（消耗 1 次 Tier 1）');
    exitCode = 2;
    return;
  }
  final fileKey = positional[0];
  final nodeId = positional[1];
  final store = CacheStore(Directory(options.root));
  final client = HttpFigmaClient(token: readToken(store));
  try {
    String? latest;
    if (options.ifStale) {
      latest = await _latestVersion(client, fileKey);
      final meta = store.read(store.metaFile(fileKey));
      final target = store.cacheFile(kind: 'nodes', fileKey: fileKey, ids: nodeId);
      if (latest != null && target.existsSync() && meta != null && '${meta['version']}' == latest) {
        if (options.json) {
          printLine(jsonEncode({
            'schema': 'w_tools_figma.diff/1',
            'fileKey': fileKey,
            'nodeId': nodeId,
            'tierCalls': 0,
            'skipped': true,
            'changes': <Object?>[],
            'nodes': <Object?>[],
          }));
        } else {
          printLine('没有变化（$nodeId，版本 $latest）');
        }
        return;
      }
    }
    final result = await DiffCommand(
      store: store,
      client: client,
      log: options.log,
    ).run(
      fileKey: fileKey,
      nodeId: nodeId,
    );
    if (latest != null) {
      store.write(store.metaFile(fileKey), <String, dynamic>{
        'version': latest,
        'checkedAt': DateTime.now().toIso8601String(),
      });
    }
    if (options.json) {
      printLine(jsonEncode({
        'schema': 'w_tools_figma.diff/1',
        'fileKey': fileKey,
        'nodeId': nodeId,
        'tierCalls': result.tierCalls,
        'changes': [
          for (final c in result.changes)
            {
              'nodeId': c.nodeId,
              'name': c.name,
              'field': c.field,
              'before': c.before,
              'after': c.after
            },
        ],
        'nodes': [
          for (final n in result.nodes) {'nodeId': n.nodeId, 'name': n.name, 'added': n.added},
        ],
      }));
      return;
    }
    if (result.isEmpty) {
      printLine('没有变化（$nodeId）');
      return;
    }
    for (final n in result.nodes) {
      printLine(n.toString());
    }
    for (final c in result.changes) {
      printLine(c.toString());
    }
  } finally {
    client.close();
  }
}

Future<String?> _latestVersion(FigmaClient client, String fileKey) async {
  final meta = await client.getJson(
    Uri.parse('https://api.figma.com/v1/files/$fileKey/meta'),
  );
  final file = meta['file'];
  if (file is! Map) return null;
  final version = '${file['version'] ?? ''}';
  return version.isEmpty ? null : version;
}
