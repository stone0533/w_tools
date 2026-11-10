import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import '../cache/nodes_index.dart';
import '../client/figma_client.dart';
import '../commands/diff_command.dart';
import 'args.dart';
import 'token_source.dart';
import 'cli_io.dart';

/// diff 用的基线提示（打到 stderr；`--json` 的 stdout 不受影响）。
List<String> diffBaselineNotes({required File? baseline, required String targetPath}) {
  if (baseline == null) {
    return <String>['# 首次 diff：没有旧缓存可比，本次只写入基线（$targetPath）'];
  }
  final depth = nodesCacheDepth(baseline.path);
  if (depth != null) {
    return <String>['# 基线来自 --depth=$depth 缓存，新增/删除节点可能偏多'];
  }
  return const <String>[];
}

/// `--if-stale` 是否可以直接跳过：有基线、有 meta、版本没变。
bool staleVersionUnchanged({
  required File? baseline,
  required Map<String, dynamic>? meta,
  required String? latest,
}) {
  if (latest == null || baseline == null || meta == null) return false;
  final version = '${meta['version'] ?? ''}';
  return version.isNotEmpty && version == latest;
}

/// diff 的可测核心：解析基线 →（可选）版本没变就跳过 → 拉取并与基线比较。
///
/// 打印留给 [runDiff]；`result == null` 表示按版本跳过了（没有消耗 Tier 1）。
Future<({DiffResult? result, List<String> notes, String? latestVersion})> executeDiff({
  required CacheStore store,
  required FigmaClient client,
  required String fileKey,
  required String nodeId,
  bool ifStale = false,
  bool log = true,
  bool ignoreBudget = false,
}) async {
  // 基线按缓存索引找（fetch 可能写成 -d<depth> 或批量 ids 的文件名），不要写死键。
  final baseline = findNodesCache(store, nodeId);
  final target = store.cacheFile(kind: 'nodes', fileKey: fileKey, ids: nodeId);
  final notes = diffBaselineNotes(baseline: baseline, targetPath: target.path);

  String? latest;
  if (ifStale) {
    latest = await latestFileVersion(client, fileKey);
    final meta = store.read(store.metaFile(fileKey));
    if (staleVersionUnchanged(baseline: baseline, meta: meta, latest: latest)) {
      return (result: null, notes: const <String>[], latestVersion: latest);
    }
  }

  final result = await DiffCommand(
    store: store,
    client: client,
    log: log,
    ignoreBudget: ignoreBudget,
  ).run(
    fileKey: fileKey,
    nodeId: nodeId,
    oldFile: baseline,
  );
  if (latest != null) {
    store.write(store.metaFile(fileKey), <String, dynamic>{
      'version': latest,
      'checkedAt': DateTime.now().toIso8601String(),
    });
  }
  return (result: result, notes: notes, latestVersion: latest);
}

Future<void> runDiff(
  List<String> args, {
  FigmaClient Function(CacheStore store)? clientFactory,
}) async {
  final options = parseOptions(args);
  rejectUnsupported(options, {'root', 'json', 'if-stale', 'no-log', 'ignore-budget'});

  rejectExtraPositional(options, 2);
  final positional = options.positional;
  if (positional.length < 2) {
    stderr.writeln('diff 用法：diff <fileKey> <nodeId>（消耗 1 次 Tier 1）');
    exitCode = 2;
    return;
  }
  final fileKey = positional[0];
  final nodeId = positional[1];
  final store = CacheStore(Directory(options.root));
  final client = clientFactory?.call(store) ?? HttpFigmaClient(token: readToken(store));
  try {
    final outcome = await executeDiff(
      store: store,
      client: client,
      fileKey: fileKey,
      nodeId: nodeId,
      ifStale: options.ifStale,
      log: options.log,
      ignoreBudget: options.ignoreBudget,
    );
    final result = outcome.result;
    if (result == null) {
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
        printLine('没有变化（$nodeId，版本 ${outcome.latestVersion}）');
      }
      return;
    }
    for (final note in outcome.notes) {
      stderr.writeln(note);
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

/// 线上文件版本（Tier 3 的 `/meta`，不占 20 次/月）。
Future<String?> latestFileVersion(FigmaClient client, String fileKey) async {
  final meta = await client.getJson(
    Uri.parse('https://api.figma.com/v1/files/$fileKey/meta'),
  );
  final file = meta['file'];
  if (file is! Map) return null;
  final version = '${file['version'] ?? ''}';
  return version.isEmpty ? null : version;
}
